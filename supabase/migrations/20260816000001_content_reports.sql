-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #3726 — Play UGC-policy prerequisite: in-app REPORT for community
-- user-generated content (shared trips, community price reports, shared
-- ratings). One row per report a user files against a piece of content;
-- the self-host operator reviews the table and moderates out-of-band.
--
-- RLS: a user may INSERT only reports naming THEMSELVES as reporter, and
-- may SELECT / DELETE only their own reports (the delete path serves the
-- GDPR wipe in UserDataSync.deleteAll). Nobody can read another user's
-- reports; moderation happens with the service role / SQL editor.

CREATE TABLE IF NOT EXISTS public.content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  target_kind TEXT NOT NULL,
  target_id TEXT NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS content_reports_reporter_idx
  ON public.content_reports(reporter_user_id);

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS content_reports_insert_own ON public.content_reports;
CREATE POLICY content_reports_insert_own ON public.content_reports
  FOR INSERT WITH CHECK (reporter_user_id = auth.uid());
DROP POLICY IF EXISTS content_reports_select_own ON public.content_reports;
CREATE POLICY content_reports_select_own ON public.content_reports
  FOR SELECT USING (reporter_user_id = auth.uid());
DROP POLICY IF EXISTS content_reports_delete_own ON public.content_reports;
CREATE POLICY content_reports_delete_own ON public.content_reports
  FOR DELETE USING (reporter_user_id = auth.uid());
