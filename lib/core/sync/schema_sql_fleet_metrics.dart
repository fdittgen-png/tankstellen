// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The manager dashboard's read path (#4216, ADR 0025, schema v15) —
/// the wizard twin of
/// `supabase/migrations/20260919000001_fleet_period_metrics.sql`.
///
/// Two functions, no new table. That is the whole design decision:
///
///  * a **materialised** `fleet_metrics` table would be a second copy
///    of the employees' expenses living under the organisation's
///    tenancy, with its own refresh story, its own retention clock and
///    its own erasure hole. ADR 0025's data-class matrix has no row for
///    it, and inventing one to make a dashboard faster is the wrong
///    trade at v1 volumes;
///  * an **RPC** computes the aggregate at read time from rows that
///    already exist, so an expense corrected this morning is right this
///    afternoon, erasure needs no second pass, and the suppression
///    threshold is applied where it cannot be bypassed.
///
/// [fleetPeriodMetricsSql] is SECURITY DEFINER because it must do three
/// things RLS cannot: read the org's expenses without the manager
/// SELECT policy's row-at-a-time cost, write the audit row (no client
/// has an INSERT policy on `fleet_audit_events`), and suppress
/// per-vehicle rows below the org's own threshold. Definer bypasses RLS
/// entirely, so the body re-checks `auth.uid()` and the caller's role on
/// `p_org` before it reads anything (#4049's third surface).
///
/// Emission order (`schema_sql.dart`): after `fleetExpenseRpcSql`, so
/// `fleet_audit_events` and `fleet_role` both already exist.
library;

/// `fleet_period_metrics(p_org, p_from, p_to)` — the aggregate-first
/// manager read (#4216), and `fleet_log_export(p_org, p_kind)`, the
/// audit hook an export goes through.
///
/// ## What it does NOT read
///
/// `trip_summaries`, `trip_details` and `obd2_baselines` are not named
/// anywhere in this file, and no fleet policy was added to them
/// (ADR 0025 D5.1). Distance comes from odometer readings printed on
/// forecourt receipts — a number the employee already handed to their
/// employer on paper — never from a journey. There is no location
/// column in the result and none in any table it reads (D5.2).
///
/// ## The suppression rule (D5.3)
///
/// A vehicle whose period holds fewer than the org's
/// `aggregationMinSamples` expenses (default 5, `fleet_policies.data`,
/// deployment configuration and not a legal conclusion — D9) comes back
/// as `suppressed = true` with **every** metric NULL, including
/// `sample_count`. Returning the count would hand the manager "this car
/// was refuelled once in March", which is the inference the threshold
/// exists to stop; the client names the threshold instead, which it
/// reads from `fleet_policies` like any other member.
///
/// ## The three refusals
///
///  * **more than one currency** in a vehicle's period → `spend`,
///    `currency` and `cost_per_km` are NULL. There is no exchange rate
///    here and inventing one would be a fabricated total (`Money.plus`
///    and `SavingsLedger` refuse the same sum on the device);
///  * **fewer than two odometer readings**, or a non-positive span →
///    `km`, `cost_per_km` and `l_per_100km` are NULL. A distance cannot
///    be derived from a single reading;
///  * **any litre whose grade has no published factor** → `co2e_kg` and
///    `co2_factor_version` are NULL for the whole vehicle. #4219: a
///    report without a factor says "not calculated" and never
///    substitutes an undocumented one, and a partial sum presented as
///    the period's emissions would be exactly that substitution.
///
/// CNG is deliberately absent from the factor table even though the
/// registry publishes it: ADEME quotes GNC **per kilogram** and the
/// expense carries a volume in litres, so the multiplication would be a
/// unit error wearing a citation. `fleet_metrics_contract_test` pins
/// the seven per-litre factors against
/// `EmissionFactorRegistry.ademeBaseCarbone` in both directions and
/// asserts CNG's absence, so neither the numbers nor this exclusion can
/// drift away from the Dart registry (#4392 supplied the sourced
/// values).
const String fleetMetricsRpcSql = '''
-- ── Fleet period metrics (#4216, v15, ADR 0025 D5.3/D5.4) ──────────
-- Aggregate-first manager read. SECURITY DEFINER, role re-checked in
-- the body, every call audited, per-vehicle rows suppressed below the
-- org's own threshold. Reads fleet_expenses only: no journey table is
-- named here and none has a manager policy (D5.1).
CREATE OR REPLACE FUNCTION public.fleet_period_metrics(
  p_org UUID,
  p_from TIMESTAMPTZ,
  p_to TIMESTAMPTZ
)
RETURNS TABLE (
  fleet_vehicle_id UUID,
  spend NUMERIC,
  litres NUMERIC,
  km NUMERIC,
  cost_per_km NUMERIC,
  l_per_100km NUMERIC,
  co2e_kg NUMERIC,
  co2_factor_version TEXT,
  sample_count INTEGER,
  measured_share NUMERIC,
  currency TEXT,
  suppressed BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  min_samples INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  -- Definer bypasses RLS, so the role is checked here or nowhere.
  IF coalesce(public.fleet_role(p_org), '') NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF p_from IS NULL OR p_to IS NULL OR p_to < p_from THEN
    RAISE EXCEPTION 'bad_period' USING ERRCODE = '22023';
  END IF;

  -- Deployment configuration, not a legal conclusion (ADR 0025 D9).
  -- Floored at 1: a threshold of 0 would switch suppression off, and
  -- that is not a value an operator gets to configure.
  SELECT coalesce((data ->> 'aggregationMinSamples')::int, 5)
    INTO min_samples
    FROM public.fleet_policies
   WHERE org_id = p_org;
  min_samples := greatest(coalesce(min_samples, 5), 1);

  -- Audited BEFORE the rows are computed (D5.4): an attempted read is
  -- a read, and a query that errors half way through must still leave
  -- the trail that it was made with these arguments.
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (p_org, auth.uid(), 'metrics_read',
            to_char(p_from AT TIME ZONE 'UTC', 'YYYY-MM-DD') || '..' ||
            to_char(p_to AT TIME ZONE 'UTC', 'YYYY-MM-DD'));

  RETURN QUERY
  WITH factor(fuel_key, kg_per_litre) AS (
    -- ADEME Base Carbone v23.6 (2026), well-to-wheel, per LITRE. Kept
    -- byte-comparable with EmissionFactorRegistry.ademeBaseCarbone by
    -- fleet_metrics_contract_test. GNC/CNG is published per kilogram
    -- and is therefore absent on purpose: the expense carries litres.
    VALUES ('e5', 2.69), ('e10', 2.69), ('e98', 2.69),
           ('diesel', 3.10), ('diesel_premium', 3.10),
           ('e85', 1.11), ('lpg', 1.86)
  ),
  src AS (
    SELECT
      e.fleet_vehicle_id AS vid,
      (e.data -> 'confirmed' ->> 'litres')::numeric AS litres,
      (e.data -> 'confirmed' -> 'total' ->> 'amount')::numeric AS amount,
      upper(e.data -> 'confirmed' -> 'total' ->> 'currency') AS ccy,
      (e.data -> 'confirmed' ->> 'odometerKm')::numeric AS odo,
      lower(e.data -> 'confirmed' ->> 'fuelApiValue') AS fuel_key
      FROM public.fleet_expenses e
     WHERE e.org_id = p_org
       AND e.fleet_vehicle_id IS NOT NULL
       -- A draft never leaves the employee (the manager policy says the
       -- same; this says it again where the aggregate is built). A
       -- rejected expense is one the company refused: it is not spend.
       AND e.status NOT IN ('draft', 'rejected')
       AND (e.data -> 'confirmed' ->> 'occurredAt')::timestamptz
             BETWEEN p_from AND p_to
  ),
  agg AS (
    SELECT
      s.vid,
      count(*)::int AS n,
      count(DISTINCT s.ccy) AS ccy_n,
      min(s.ccy) AS ccy,
      sum(s.amount) AS spend,
      sum(s.litres) AS litres,
      count(s.odo) AS odo_n,
      max(s.odo) - min(s.odo) AS odo_span,
      sum(s.litres) FILTER (WHERE s.odo IS NOT NULL) AS measured_litres,
      count(*) FILTER (WHERE f.kg_per_litre IS NULL) AS unpriced_n,
      sum(s.litres * f.kg_per_litre) AS co2e
      FROM src s
      LEFT JOIN factor f ON f.fuel_key = s.fuel_key
     GROUP BY s.vid
  ),
  shaped AS (
    SELECT
      a.vid,
      a.n,
      a.n < min_samples AS sup,
      CASE WHEN a.ccy_n = 1 THEN a.spend END AS spend,
      CASE WHEN a.ccy_n = 1 THEN a.ccy END AS ccy,
      a.litres,
      CASE WHEN a.odo_n >= 2 AND a.odo_span > 0 THEN a.odo_span END AS km,
      CASE WHEN a.unpriced_n = 0 THEN round(a.co2e, 3) END AS co2e,
      CASE WHEN a.litres > 0
           THEN round(coalesce(a.measured_litres, 0) / a.litres, 4)
      END AS measured_share
      FROM agg a
  )
  SELECT
    t.vid,
    CASE WHEN t.sup THEN NULL ELSE t.spend END,
    CASE WHEN t.sup THEN NULL ELSE t.litres END,
    CASE WHEN t.sup THEN NULL ELSE t.km END,
    CASE WHEN t.sup OR t.km IS NULL OR t.spend IS NULL
         THEN NULL ELSE round(t.spend / t.km, 4) END,
    CASE WHEN t.sup OR t.km IS NULL OR t.litres IS NULL
         THEN NULL ELSE round(t.litres * 100 / t.km, 3) END,
    CASE WHEN t.sup THEN NULL ELSE t.co2e END,
    CASE WHEN t.sup OR t.co2e IS NULL
         THEN NULL ELSE 'ADEME Base Carbone v23.6 (2026) WtW' END,
    -- NULL, not the count: "one refuelling in March" is the inference
    -- the threshold exists to prevent (D5.3).
    CASE WHEN t.sup THEN NULL ELSE t.n END,
    CASE WHEN t.sup THEN NULL ELSE t.measured_share END,
    CASE WHEN t.sup THEN NULL ELSE t.ccy END,
    t.sup
    FROM shaped t
   ORDER BY t.vid;
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_period_metrics(UUID, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_period_metrics(UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_period_metrics(UUID, TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;

-- One audit row per manager export (D5.4). Returns a boolean and
-- carries no data: it grants nothing, it only records that a manager
-- took the aggregate off the device.
CREATE OR REPLACE FUNCTION public.fleet_log_export(p_org UUID, p_kind TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  IF coalesce(public.fleet_role(p_org), '') NOT IN ('manager', 'admin') THEN
    RETURN FALSE;
  END IF;
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (p_org, auth.uid(), 'metrics_export',
            coalesce(nullif(trim(p_kind), ''), 'unspecified'));
  RETURN TRUE;
END;
\$\$;
REVOKE ALL ON FUNCTION public.fleet_log_export(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_log_export(UUID, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_log_export(UUID, TEXT) FROM anon;
''';
