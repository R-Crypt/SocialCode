-- Run this to force Supabase's API to recognize the new artist_name column
NOTIFY pgrst, 'reload schema';
