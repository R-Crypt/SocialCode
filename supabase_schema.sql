-- ============================================================
-- SOCIAL CODE - COMPLETE SUPABASE SCHEMA
-- Run this in the Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. PROFILES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  email TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT 'Citizen',
  role TEXT DEFAULT 'citizen' CHECK (role IN ('citizen', 'creator', 'admin')),
  points INTEGER DEFAULT 0,
  region TEXT DEFAULT 'Bengaluru',
  profile_image_url TEXT,
  bio TEXT,
  instagram_url TEXT,
  website_url TEXT,
  creator_details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone."
  ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update their own profile." ON public.profiles;
CREATE POLICY "Users can update their own profile."
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- CLEANUP OLD RECURSIVE POLICY FROM PREVIOUS RUN
DROP POLICY IF EXISTS "Admins have full access to profiles." ON public.profiles;

DROP POLICY IF EXISTS "Admins can update profiles." ON public.profiles;
CREATE POLICY "Admins can update profiles."
  ON public.profiles FOR UPDATE USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

DROP POLICY IF EXISTS "Admins can delete profiles." ON public.profiles;
CREATE POLICY "Admins can delete profiles."
  ON public.profiles FOR DELETE USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  );

DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
CREATE POLICY "Users can insert their own profile."
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile." ON public.profiles;
CREATE POLICY "Users can update their own profile."
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- ============================================================
-- 2. CHALLENGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  mission_briefing TEXT,
  creator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  creator_name TEXT NOT NULL DEFAULT 'Admin',
  start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  end_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() + INTERVAL '30 days'),
  points_reward INTEGER NOT NULL DEFAULT 50,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'upcoming', 'completed', 'draft', 'pending')),
  image_url TEXT,
  category TEXT DEFAULT 'environment' CHECK (category IN ('environment', 'community', 'education', 'health', 'civic')),
  city TEXT DEFAULT 'Bengaluru',
  target_count INTEGER DEFAULT 100,
  current_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Challenges are viewable by everyone." ON public.challenges;
CREATE POLICY "Challenges are viewable by everyone."
  ON public.challenges FOR SELECT USING (true);

DROP POLICY IF EXISTS "Creators and admins can insert challenges." ON public.challenges;
CREATE POLICY "Creators and admins can insert challenges."
  ON public.challenges FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM public.profiles WHERE role IN ('creator', 'admin')
    )
  );

DROP POLICY IF EXISTS "Creators can update their own challenges." ON public.challenges;
CREATE POLICY "Creators can update their own challenges."
  ON public.challenges FOR UPDATE
  USING (auth.uid() = creator_id OR auth.uid() IN (
    SELECT id FROM public.profiles WHERE role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins can delete challenges." ON public.challenges;
CREATE POLICY "Admins can delete challenges."
  ON public.challenges FOR DELETE
  USING (auth.uid() IN (
    SELECT id FROM public.profiles WHERE role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins have full access to challenges." ON public.challenges;
CREATE POLICY "Admins have full access to challenges."
  ON public.challenges USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- ============================================================
-- 3. CHALLENGE PARTICIPANTS (Join table)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.challenge_participants (
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (challenge_id, user_id)
);

ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view participants." ON public.challenge_participants;
CREATE POLICY "Anyone can view participants."
  ON public.challenge_participants FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can join challenges." ON public.challenge_participants;
CREATE POLICY "Users can join challenges."
  ON public.challenge_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can leave challenges." ON public.challenge_participants;
CREATE POLICY "Users can leave challenges."
  ON public.challenge_participants FOR DELETE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins have full access to challenge_participants." ON public.challenge_participants;
CREATE POLICY "Admins have full access to challenge_participants."
  ON public.challenge_participants USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- ============================================================
-- 4. SUBMISSIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  user_name TEXT NOT NULL,
  image_url TEXT NOT NULL,
  caption TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_name TEXT,
  points_awarded INTEGER DEFAULT 0,
  reviewer_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Submissions are viewable by everyone." ON public.submissions;
CREATE POLICY "Submissions are viewable by everyone."
  ON public.submissions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can submit." ON public.submissions;
CREATE POLICY "Authenticated users can submit."
  ON public.submissions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own pending submissions." ON public.submissions;
CREATE POLICY "Users can update their own pending submissions."
  ON public.submissions FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending');

DROP POLICY IF EXISTS "Admins and creators can approve/reject submissions." ON public.submissions;
CREATE POLICY "Admins and creators can approve/reject submissions."
  ON public.submissions FOR UPDATE
  USING (auth.uid() IN (
    SELECT id FROM public.profiles WHERE role IN ('admin', 'creator')
  ));

DROP POLICY IF EXISTS "Admins have full access to submissions." ON public.submissions;
CREATE POLICY "Admins have full access to submissions."
  ON public.submissions USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- ============================================================
-- 5. CIVIC REPORTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.civic_reports (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  user_name TEXT NOT NULL DEFAULT 'Anonymous',
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'pothole' CHECK (category IN ('pothole', 'waste', 'streetlight', 'water', 'tree', 'other')),
  status TEXT DEFAULT 'reported' CHECK (status IN ('reported', 'in_progress', 'resolved', 'rejected')),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  location_name TEXT,
  image_url TEXT,
  upvotes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.civic_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Reports are viewable by everyone." ON public.civic_reports;
CREATE POLICY "Reports are viewable by everyone."
  ON public.civic_reports FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create reports." ON public.civic_reports;
CREATE POLICY "Authenticated users can create reports."
  ON public.civic_reports FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update their own reports." ON public.civic_reports;
CREATE POLICY "Users can update their own reports."
  ON public.civic_reports FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins have full access to civic reports." ON public.civic_reports;
CREATE POLICY "Admins have full access to civic reports."
  ON public.civic_reports USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- ============================================================
-- 6. REPORT UPVOTES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.report_upvotes (
  report_id UUID REFERENCES public.civic_reports(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (report_id, user_id)
);

ALTER TABLE public.report_upvotes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view upvotes." ON public.report_upvotes;
CREATE POLICY "Anyone can view upvotes." ON public.report_upvotes FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can upvote." ON public.report_upvotes;
CREATE POLICY "Users can upvote." ON public.report_upvotes FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can remove their upvote." ON public.report_upvotes;
CREATE POLICY "Users can remove their upvote." ON public.report_upvotes FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- 7. LEADERBOARD VIEW
-- ============================================================
CREATE OR REPLACE VIEW public.leaderboard AS
  SELECT
    p.id,
    p.display_name,
    p.profile_image_url,
    p.region,
    p.points,
    COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'approved') AS approved_submissions,
    RANK() OVER (ORDER BY p.points DESC) AS rank
  FROM public.profiles p
  LEFT JOIN public.submissions s ON s.user_id = p.id
  WHERE p.role = 'citizen'
  GROUP BY p.id, p.display_name, p.profile_image_url, p.region, p.points
  ORDER BY p.points DESC;

-- ============================================================
-- 8. FUNCTIONS AND TRIGGERS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE OR REPLACE TRIGGER on_challenges_updated
  BEFORE UPDATE ON public.challenges
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE OR REPLACE TRIGGER on_submissions_updated
  BEFORE UPDATE ON public.submissions
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE OR REPLACE TRIGGER on_civic_reports_updated
  BEFORE UPDATE ON public.civic_reports
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'citizen')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Award points when submission is approved
CREATE OR REPLACE FUNCTION public.award_points_on_approval()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Get challenge points reward
    WITH reward AS (
      SELECT points_reward FROM public.challenges WHERE id = NEW.challenge_id
    )
    UPDATE public.profiles
    SET points = points + (SELECT points_reward FROM reward)
    WHERE id = NEW.user_id;
    
    NEW.points_awarded = (SELECT points_reward FROM public.challenges WHERE id = NEW.challenge_id);
    
    -- Increment challenge current_count
    UPDATE public.challenges
    SET current_count = current_count + 1
    WHERE id = NEW.challenge_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_submission_approved
  BEFORE UPDATE ON public.submissions
  FOR EACH ROW EXECUTE PROCEDURE public.award_points_on_approval();

-- ============================================================
-- 9. SEED DATA (sample challenges)
-- ============================================================
INSERT INTO public.challenges (title, description, mission_briefing, creator_name, points_reward, category, city, status, image_url, target_count)
VALUES
(
  'STREET GREEN CHALLENGE',
  'Plant a native sapling in your neighborhood and document it.',
  'BANGALORE IS LOSING ITS GREEN COVER. WE NEED CITIZENS TO ACT. FIND A SPOT IN YOUR NEIGHBORHOOD, PLANT A NATIVE SAPLING, AND CARE FOR IT. THIS ISN''T JUST A PHOTO OP—IT''S A COMMITMENT.',
  'Social Code HQ',
  80,
  'environment',
  'Bengaluru',
  'active',
  'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=1000',
  500
),
(
  'FEED THE CITY',
  'Organize a food drive for urban homeless communities.',
  'URBAN HUNGER IS REAL. CONNECT WITH LOCAL NGOs OR ORGANIZE YOUR OWN DRIVE. COLLECT NON-PERISHABLE ITEMS AND DISTRIBUTE TO THOSE IN NEED. DOCUMENT YOUR IMPACT AND INSPIRE OTHERS.',
  'Social Code HQ',
  100,
  'community',
  'Bengaluru',
  'active',
  'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=1000',
  300
),
(
  'CLOTHES FOR A CAUSE',
  'Donate clothes to shelters and document your contribution.',
  'YOUR CLOSET HAS POWER. COLLECT GENTLY USED CLOTHING FROM YOUR COMMUNITY, COORDINATE A DROP ZONE, AND ENSURE CLOTHES REACH THOSE WHO NEED THEM MOST BEFORE WINTER.',
  'Social Code HQ',
  60,
  'community',
  'Bengaluru',
  'active',
  'https://images.unsplash.com/photo-1593113598332-cd288d649433?q=80&w=1000',
  1000
),
(
  'POTHOLE WARRIORS',
  'Report and document road hazards in your area.',
  'EVERY POTHOLE UNREPORTED IS AN ACCIDENT WAITING TO HAPPEN. USE THE MAP FEATURE TO PIN HAZARDS, PHOTOGRAPH THEM, AND SUBMIT TO THE CIVIC REPORT SYSTEM. TRACK UNTIL FIXED.',
  'Social Code HQ',
  40,
  'civic',
  'Bengaluru',
  'active',
  'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=1000',
  200
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 10. STORAGE BUCKETS
-- ============================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('submissions', 'submissions', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('civic-reports', 'civic-reports', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('challenge-images', 'challenge-images', true) ON CONFLICT DO NOTHING;
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
