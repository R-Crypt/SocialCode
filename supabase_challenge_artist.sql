-- Add artist_name column to challenges table to support creator details
ALTER TABLE public.challenges 
ADD COLUMN IF NOT EXISTS artist_name TEXT;
