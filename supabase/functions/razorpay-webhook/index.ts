// supabase/functions/razorpay-webhook/index.ts
// Deploy: supabase functions deploy razorpay-webhook --no-verify-jwt
//
// Required secrets (set via `supabase secrets set`):
//   RAZORPAY_WEBHOOK_SECRET  — from Razorpay Dashboard › Webhooks
//   SUPABASE_URL             — auto-set by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — auto-set by Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WEBHOOK_SECRET = Deno.env.get("RAZORPAY_WEBHOOK_SECRET")!;
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ─── Signature Verification ────────────────────────────────────────────────
async function verifySignature(
  rawBody: string,
  receivedSig: string,
  secret: string,
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(rawBody),
  );
  const computedHex = Array.from(new Uint8Array(sigBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return computedHex === receivedSig;
}

// ─── QR Token Generation ───────────────────────────────────────────────────
// Produces a URL-safe base64 token from payment ID + order ID + entropy.
// Non-guessable: requires knowledge of both Razorpay IDs + random UUID.
function generateQrToken(paymentId: string, orderId: string): string {
  const raw = `${paymentId}:${orderId}:${Date.now()}:${crypto.randomUUID()}`;
  return btoa(raw).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

// ─── Main Handler ──────────────────────────────────────────────────────────
serve(async (req: Request) => {
  const rawBody  = await req.text();
  const sigHeader = req.headers.get("x-razorpay-signature") ?? "";

  // 1. Verify HMAC-SHA256 signature — reject anything that doesn't match
  const valid = await verifySignature(rawBody, sigHeader, WEBHOOK_SECRET);
  if (!valid) {
    console.error("Razorpay webhook: invalid signature");
    return json({ error: "Unauthorized" }, 401);
  }

  const event = JSON.parse(rawBody);
  console.log("Webhook event:", event.event);

  // 2. Only act on payment.captured (money confirmed in account)
  if (event.event !== "payment.captured") {
    return json({ status: "ignored", event: event.event }, 200);
  }

  const payment: Record<string, unknown> =
    event.payload?.payment?.entity ?? {};
  const notes: Record<string, string> =
    (payment.notes as Record<string, string>) ?? {};

  // 3. Validate required metadata injected by the Flutter order-creation call
  const eventId = notes.event_id;
  if (!eventId) {
    console.error("Missing event_id in payment notes");
    return json({ error: "Missing event_id in notes" }, 400);
  }

  // 4. Generate unique, non-guessable QR token
  const qrToken = generateQrToken(
    payment.id as string,
    payment.order_id as string,
  );

  // 5. Call atomic PostgreSQL function (oversell-proof via SELECT … FOR UPDATE)
  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

  const { data, error } = await supabase.rpc("issue_ticket", {
    p_event_id:             eventId,
    p_user_id:              notes.user_id ?? null,
    p_name:                 notes.attendee_name ?? "Guest",
    p_email:                payment.email ?? notes.attendee_email ?? "",
    p_phone:                payment.contact ?? null,
    p_razorpay_order_id:    payment.order_id as string,
    p_razorpay_payment_id:  payment.id as string,
    p_amount_paise:         payment.amount as number,
    p_tier_label:           notes.tier_label ?? "General",
    p_qr_token:             qrToken,
    p_policy_version:       notes.policy_version ?? "v1.0",
  });

  if (error) {
    console.error("issue_ticket RPC error:", error.message);
    return json({ error: error.message }, 500);
  }

  const result = (data as Array<Record<string, unknown>>)?.[0];
  if (!result?.success) {
    // e.g. sold out — return 200 so Razorpay doesn't retry, but log the issue
    console.warn("Ticket issuance rejected:", result?.message);
    return json({ status: "rejected", reason: result?.message }, 200);
  }

  console.log("Ticket issued:", result.ticket_id);
  return json({ status: "ok", ticket_id: result.ticket_id }, 200);
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
