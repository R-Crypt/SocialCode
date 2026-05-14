-- Ensure user_consents table exists and has correct policies
CREATE TABLE IF NOT EXISTS public.user_consents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  analytics_consent BOOLEAN DEFAULT false,
  marketing_consent BOOLEAN DEFAULT false,
  ip_hash TEXT,
  consented_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  UNIQUE(user_id) -- Only one consent record per user
);

ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own consent" ON public.user_consents;
CREATE POLICY "Users can view own consent" ON public.user_consents
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own consent" ON public.user_consents;
CREATE POLICY "Users can insert own consent" ON public.user_consents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own consent" ON public.user_consents;
CREATE POLICY "Users can update own consent" ON public.user_consents
  FOR UPDATE USING (auth.uid() = user_id);
