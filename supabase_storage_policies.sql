-- Storage Policies for Social Code Buckets

-- ==========================================
-- 1. Avatars Bucket
-- ==========================================
CREATE POLICY "Avatar images are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatars" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Users can update their own avatars" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'avatars');

CREATE POLICY "Users can delete their own avatars" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'avatars');


-- ==========================================
-- 2. Submissions Bucket
-- ==========================================
CREATE POLICY "Submission images are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'submissions');

CREATE POLICY "Users can upload submission images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'submissions');

CREATE POLICY "Users can update their submission images" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'submissions');

CREATE POLICY "Users can delete their submission images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'submissions');


-- ==========================================
-- 3. Civic-reports Bucket
-- ==========================================
CREATE POLICY "Civic report images are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'civic-reports');

CREATE POLICY "Users can upload civic report images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'civic-reports');

CREATE POLICY "Users can update their civic report images" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'civic-reports');

CREATE POLICY "Users can delete their civic report images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'civic-reports');


-- ==========================================
-- 4. Challenge-images Bucket
-- ==========================================
CREATE POLICY "Challenge images are publicly accessible" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'challenge-images');

CREATE POLICY "Creators and admins can upload challenge images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'challenge-images');

CREATE POLICY "Creators and admins can update challenge images" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'challenge-images');

CREATE POLICY "Creators and admins can delete challenge images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'challenge-images');
