-- ============================================================
-- SOCIAL CODE - SECURITY & COMPLIANCE (GDPR & DPDPA) SCHEMA
-- Run this in the Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. RIGHT TO ERASURE (DELETE ACCOUNT SECURELY)
-- ============================================================
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get the ID of the user making the request
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Nullify or delete submissions (Nullify to preserve aggregate metrics but remove PII)
  -- Or explicitly delete if you prefer complete removal:
  DELETE FROM public.submissions WHERE user_id = v_user_id;

  -- 2. Delete challenges created by the user (if applicable)
  -- If you want to keep them, you can set creator_id to NULL.
  -- Here we cascade delete for strict GDPR compliance.
  DELETE FROM public.challenges WHERE creator_id = v_user_id;

  -- 3. Delete Profile (The CASCADE from auth.users might do this, but explicit is safer)
  DELETE FROM public.profiles WHERE id = v_user_id;

  -- 4. Delete the Auth User (Requires elevated privileges or a SECURITY DEFINER function)
  -- NOTE: This requires the function to be SECURITY DEFINER to bypass RLS
  DELETE FROM auth.users WHERE id = v_user_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. DATA PORTABILITY (EXPORT DATA)
-- ============================================================
CREATE OR REPLACE FUNCTION export_user_data()
RETURNS json AS $$
DECLARE
  v_user_id uuid;
  v_profile json;
  v_submissions json;
  v_challenges json;
  v_result json;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Get Profile
  SELECT row_to_json(p) INTO v_profile FROM public.profiles p WHERE id = v_user_id;
  
  -- Get Submissions
  SELECT json_agg(row_to_json(s)) INTO v_submissions FROM public.submissions s WHERE user_id = v_user_id;
  
  -- Get Created Challenges
  SELECT json_agg(row_to_json(c)) INTO v_challenges FROM public.challenges c WHERE creator_id = v_user_id;

  -- Build final JSON
  SELECT json_build_object(
    'profile', v_profile,
    'submissions', COALESCE(v_submissions, '[]'::json),
    'challenges_created', COALESCE(v_challenges, '[]'::json),
    'exported_at', now()
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 3. CONSENT MANAGEMENT LOGGING
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_consents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  analytics_consent BOOLEAN DEFAULT false,
  marketing_consent BOOLEAN DEFAULT false,
  ip_hash TEXT, -- Hashed IP for audit trailing without storing raw PII
  consented_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own consent" ON public.user_consents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own consent" ON public.user_consents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own consent" ON public.user_consents
  FOR UPDATE USING (auth.uid() = user_id);


-- ============================================================
-- 4. INPUT SANITIZATION (TRIGGER BASED)
-- ============================================================
-- Example: Strip basic HTML tags from profile bio
CREATE OR REPLACE FUNCTION sanitize_profile_inputs()
RETURNS TRIGGER AS $$
BEGIN
  -- Simple regex replace to strip <tag> formats
  IF NEW.bio IS NOT NULL THEN
    NEW.bio := regexp_replace(NEW.bio, '<[^>]*>', '', 'g');
  END IF;
  
  IF NEW.creator_details IS NOT NULL THEN
    NEW.creator_details := regexp_replace(NEW.creator_details, '<[^>]*>', '', 'g');
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sanitize_profile_trigger ON public.profiles;

CREATE TRIGGER sanitize_profile_trigger
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION sanitize_profile_inputs();
