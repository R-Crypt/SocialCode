-- Add image hash to submissions to prevent duplicate image cheating
ALTER TABLE public.submissions 
ADD COLUMN IF NOT EXISTS image_hash TEXT;

-- Create an index to quickly look up duplicate hashes
CREATE INDEX IF NOT EXISTS idx_submissions_image_hash 
ON public.submissions(image_hash);
