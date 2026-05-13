CREATE OR REPLACE FUNCTION public.increment_report_upvote(report_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.civic_reports
  SET upvotes = upvotes + 1
  WHERE id = report_id;
END;
$$;
