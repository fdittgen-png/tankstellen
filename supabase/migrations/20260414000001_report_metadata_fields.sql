-- #484 — extend price_reports to cover metadata corrections
-- (wrong station name, wrong address) in addition to price and
-- open/closed status reports.
--
-- Two shape changes to the existing table:
--
-- 1. Make `reported_price` nullable. Metadata reports don't carry a
--    price, and we don't want to invent a sentinel value that would
--    leak into analytics queries on the column.
--
-- 2. Add a `correction_text` TEXT nullable column. Used by metadata
--    reports to carry the user-supplied correction (the new name,
--    the new address). For price reports it stays null.
--
-- Backwards compatibility: existing rows are unaffected — they all
-- have non-null `reported_price` and `correction_text` defaults to
-- null. The insert policy (`reports_insert`) is unchanged: inserts
-- still require `reporter_id = auth.uid()`.
--
-- Row semantics after the migration:
--
--   Price report (e.g. wrongE10):
--     fuel_type = 'e10'
--     reported_price = 1.799
--     correction_text = NULL
--
--   Metadata report (e.g. wrong station name):
--     fuel_type = 'name'               -- sentinel field identifier
--     reported_price = NULL
--     correction_text = 'Total Access Pézenas Sud'
--
-- The `fuel_type` column keeps its NOT NULL constraint because we
-- always know which field is being corrected (either a fuel price
-- code or a metadata field name).

ALTER TABLE public.price_reports
  ALTER COLUMN reported_price DROP NOT NULL;

ALTER TABLE public.price_reports
  ADD COLUMN IF NOT EXISTS correction_text TEXT NULL;

-- At least one of reported_price / correction_text must be set —
-- a report with neither is meaningless.
ALTER TABLE public.price_reports
  ADD CONSTRAINT price_reports_has_payload
  CHECK (reported_price IS NOT NULL OR correction_text IS NOT NULL);

-- Optional index on correction_text for future analytics; small table
-- so this is cheap.
CREATE INDEX IF NOT EXISTS price_reports_correction_text_idx
  ON public.price_reports (correction_text)
  WHERE correction_text IS NOT NULL;
