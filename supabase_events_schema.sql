-- ============================================================
-- SOCIAL CODE — EVENTS & TICKETING SCHEMA
-- DPDPA 2023 Compliant | Oversell-Protected | RLS-Enforced
-- Run AFTER supabase_schema.sql
-- ============================================================

-- ============================================================
-- 1. EVENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.events (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title           TEXT NOT NULL,
  description     TEXT,
  location        TEXT NOT NULL,
  event_date      TIMESTAMP WITH TIME ZONE NOT NULL,
  total_slots     INTEGER NOT NULL DEFAULT 100 CHECK (total_slots > 0),
  slots_sold      INTEGER NOT NULL DEFAULT 0   CHECK (slots_sold >= 0),
  -- price_tiers: JSONB array e.g. [{"label":"General","price_paise":50000},{"label":"VIP","price_paise":150000}]
  price_tiers     JSONB NOT NULL DEFAULT '[{"label":"General","price_paise":0}]',
  banner_url      TEXT,
  status          TEXT DEFAULT 'published'
                    CHECK (status IN ('draft','published','cancelled','completed')),
  created_by      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Public SELECT: published & completed visible to all; drafts only to admins
DROP POLICY IF EXISTS "Published events viewable by all." ON public.events;
CREATE POLICY "Published events viewable by all."
  ON public.events FOR SELECT
  USING (
    status IN ('published','completed')
    OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- INSERT: admins only
DROP POLICY IF EXISTS "Only admins can create events." ON public.events;
CREATE POLICY "Only admins can create events."
  ON public.events FOR INSERT
  WITH CHECK (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- UPDATE: admins only
DROP POLICY IF EXISTS "Only admins can update events." ON public.events;
CREATE POLICY "Only admins can update events."
  ON public.events FOR UPDATE
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- DELETE: admins only
DROP POLICY IF EXISTS "Only admins can delete events." ON public.events;
CREATE POLICY "Only admins can delete events."
  ON public.events FOR DELETE
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- Trigger: auto-update updated_at
CREATE OR REPLACE TRIGGER on_events_updated
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ============================================================
-- 2. TICKETS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.tickets (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id              UUID REFERENCES public.events(id) ON DELETE CASCADE NOT NULL,
  user_id               UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- PII — maskable for DPDPA Right to Erasure
  attendee_name         TEXT NOT NULL,
  attendee_email        TEXT NOT NULL,
  attendee_phone        TEXT,

  -- Payment
  razorpay_order_id     TEXT,
  razorpay_payment_id   TEXT UNIQUE,
  amount_paid_paise     INTEGER NOT NULL DEFAULT 0,
  price_tier_label      TEXT NOT NULL DEFAULT 'General',

  -- QR token: HMAC-SHA256 derived, non-guessable, globally unique
  qr_token              TEXT UNIQUE NOT NULL,

  -- Lifecycle: valid → used (gate scan), cancelled, expired
  status                TEXT DEFAULT 'valid'
                          CHECK (status IN ('valid','used','cancelled','expired')),

  -- Gate verification audit
  scanned_at            TIMESTAMP WITH TIME ZONE,
  scanned_by            UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- DPDPA erasure flag
  is_pii_erased         BOOLEAN DEFAULT false,

  created_at            TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at            TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Users see only their own tickets; admins see all
DROP POLICY IF EXISTS "Users view own tickets." ON public.tickets;
CREATE POLICY "Users view own tickets."
  ON public.tickets FOR SELECT
  USING (
    auth.uid() = user_id
    OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- Direct INSERT is blocked for regular users — inserts go through the
-- issue_ticket() SECURITY DEFINER function (called by the webhook edge function)
-- Admins may UPDATE (cancel, gate-check override)
DROP POLICY IF EXISTS "Admins can manage tickets." ON public.tickets;
CREATE POLICY "Admins can manage tickets."
  ON public.tickets FOR UPDATE
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- Trigger
CREATE OR REPLACE TRIGGER on_tickets_updated
  BEFORE UPDATE ON public.tickets
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ============================================================
-- 3. TICKET CONSENT LOGS (DPDPA Audit Trail)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ticket_consent_logs (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id       UUID REFERENCES public.tickets(id) ON DELETE CASCADE NOT NULL,
  user_id         UUID REFERENCES auth.users ON DELETE CASCADE,
  policy_version  TEXT NOT NULL DEFAULT 'v1.0',
  consent_text    TEXT NOT NULL DEFAULT
    'I consent to my personal data being processed for ticket issuance and '
    'event entry verification under the Digital Personal Data Protection Act 2023.',
  consented_at    TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  ip_hash         TEXT   -- SHA-256 hash of IP (no raw PII stored)
);

ALTER TABLE public.ticket_consent_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own consent logs." ON public.ticket_consent_logs;
CREATE POLICY "Users view own consent logs."
  ON public.ticket_consent_logs FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins view all consent logs." ON public.ticket_consent_logs;
CREATE POLICY "Admins view all consent logs."
  ON public.ticket_consent_logs FOR SELECT
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

-- ============================================================
-- 4. ATOMIC TICKET ISSUANCE (Oversell Prevention)
--    Called exclusively by the Razorpay webhook Edge Function
--    using the service_role key — bypasses RLS intentionally.
-- ============================================================
CREATE OR REPLACE FUNCTION public.issue_ticket(
  p_event_id              UUID,
  p_user_id               UUID,
  p_name                  TEXT,
  p_email                 TEXT,
  p_phone                 TEXT,
  p_razorpay_order_id     TEXT,
  p_razorpay_payment_id   TEXT,
  p_amount_paise          INTEGER,
  p_tier_label            TEXT,
  p_qr_token              TEXT,
  p_policy_version        TEXT DEFAULT 'v1.0'
)
RETURNS TABLE(ticket_id UUID, success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ticket_id        UUID;
  v_slots_available  INTEGER;
BEGIN
  -- Lock the event row to serialize concurrent purchases
  SELECT (total_slots - slots_sold)
  INTO   v_slots_available
  FROM   public.events
  WHERE  id = p_event_id
  FOR UPDATE;

  IF v_slots_available IS NULL THEN
    RETURN QUERY SELECT NULL::UUID, FALSE, 'Event not found';
    RETURN;
  END IF;

  IF v_slots_available <= 0 THEN
    RETURN QUERY SELECT NULL::UUID, FALSE, 'Event is sold out';
    RETURN;
  END IF;

  -- Insert ticket record
  INSERT INTO public.tickets (
    event_id, user_id, attendee_name, attendee_email, attendee_phone,
    razorpay_order_id, razorpay_payment_id, amount_paid_paise,
    price_tier_label, qr_token, status
  ) VALUES (
    p_event_id, p_user_id, p_name, p_email, p_phone,
    p_razorpay_order_id, p_razorpay_payment_id, p_amount_paise,
    p_tier_label, p_qr_token, 'valid'
  )
  RETURNING id INTO v_ticket_id;

  -- Atomically increment slots_sold
  UPDATE public.events
  SET    slots_sold = slots_sold + 1
  WHERE  id = p_event_id;

  -- Log consent
  INSERT INTO public.ticket_consent_logs (ticket_id, user_id, policy_version)
  VALUES (v_ticket_id, p_user_id, p_policy_version);

  RETURN QUERY SELECT v_ticket_id, TRUE, 'Ticket issued successfully';
END;
$$;

-- ============================================================
-- 5. GATE CHECK FUNCTION (QR Scan → Mark Used, Replay-Proof)
-- ============================================================
CREATE OR REPLACE FUNCTION public.verify_and_use_ticket(
  p_qr_token    TEXT,
  p_scanned_by  UUID
)
RETURNS TABLE(
  ticket_id        UUID,
  event_title      TEXT,
  attendee_name    TEXT,
  price_tier_label TEXT,
  success          BOOLEAN,
  message          TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ticket RECORD;
BEGIN
  -- Lock the ticket row to prevent concurrent scans
  SELECT t.id, t.status, t.attendee_name, t.price_tier_label, e.title
  INTO   v_ticket
  FROM   public.tickets t
  JOIN   public.events  e ON e.id = t.event_id
  WHERE  t.qr_token = p_qr_token
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::TEXT, NULL::TEXT,
                        FALSE, 'Invalid QR token';
    RETURN;
  END IF;

  -- Replay attack guard
  IF v_ticket.status = 'used' THEN
    RETURN QUERY SELECT v_ticket.id, v_ticket.title, v_ticket.attendee_name,
                        v_ticket.price_tier_label, FALSE,
                        '⛔ REPLAY ATTACK: Ticket already scanned';
    RETURN;
  END IF;

  IF v_ticket.status IN ('cancelled','expired') THEN
    RETURN QUERY SELECT v_ticket.id, v_ticket.title, v_ticket.attendee_name,
                        v_ticket.price_tier_label, FALSE,
                        'Ticket is ' || v_ticket.status;
    RETURN;
  END IF;

  -- Mark as used
  UPDATE public.tickets
  SET status     = 'used',
      scanned_at = now(),
      scanned_by = p_scanned_by
  WHERE id = v_ticket.id;

  RETURN QUERY SELECT v_ticket.id, v_ticket.title, v_ticket.attendee_name,
                      v_ticket.price_tier_label, TRUE, '✅ ACCESS GRANTED';
END;
$$;

-- ============================================================
-- 6. DPDPA RIGHT TO ERASURE — Mask PII on Account Deletion
-- ============================================================
CREATE OR REPLACE FUNCTION public.erase_ticket_pii(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tickets
  SET attendee_name  = '[ERASED]',
      attendee_email = '[ERASED]',
      attendee_phone = NULL,
      user_id        = NULL,
      is_pii_erased  = true
  WHERE user_id = p_user_id;
END;
$$;

-- Extend the existing delete_user_account() to include ticket PII erasure
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- DPDPA: mask ticket PII (keep audit trail, remove personal data)
  PERFORM public.erase_ticket_pii(v_user_id);

  -- Existing cleanup
  DELETE FROM public.submissions WHERE user_id = v_user_id;
  DELETE FROM public.challenges  WHERE creator_id = v_user_id;
  DELETE FROM public.profiles    WHERE id = v_user_id;
  DELETE FROM auth.users         WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. STORAGE BUCKET — Event Banners
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-banners', 'event-banners', true)
ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "Admins upload event banners." ON storage.objects;
CREATE POLICY "Admins upload event banners."
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'event-banners'
    AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

DROP POLICY IF EXISTS "Anyone views event banners." ON storage.objects;
CREATE POLICY "Anyone views event banners."
  ON storage.objects FOR SELECT
  USING (bucket_id = 'event-banners');
