// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Key-prefix allow-list of French-reachable surfaces that MUST be fully
/// translated into `app_fr.arb` — no English fallback permitted.
///
/// Background: French is the project's primary user locale (#495). While the
/// 23-locale autofill pipeline (#2335) now machine-fills every locale to 100%
/// of `app_en.arb`, that fallback is an English-shaped placeholder. For the
/// handful of *core user-facing surfaces* below we hold a harder bar: every
/// matching key must carry a real French string in `app_fr.arb`, asserted by
/// `test/l10n/localization_completeness_test.dart`.
///
/// Each entry is matched with `String.startsWith`, so a single value covers a
/// whole `featureLabel_*` family as well as an exact key like
/// `addServiceReminder` (which is a `startsWith` of itself).
///
/// ## Adding a new French-reachable surface
///
/// When a new screen/section that a French user can reach ships its strings,
/// add the key prefix(es) here in ONE line — no test logic changes needed.
/// Keep the trailing `// #NNNN` issue/incident reference so the rationale for
/// each gate stays discoverable.
///
/// Every prefix below traces to a real shipped incident where a French user
/// saw an English island in an otherwise-French screen.
library;

/// Prefixes (or exact keys) of `app_en.arb` keys that French MUST translate.
const List<String> kFrenchRequiredPrefixes = <String>[
  // #495 — onboarding wizard is the French user's first impression of the app
  // and must not fall back to English.
  'onboarding',

  // #1218 — the Edit vehicle screen (calibration / service-reminder / VIN /
  // vehicle-edit) was shipping mixed-locale on French.
  'vehicle',
  'calibrationMode',
  'veReset',
  'serviceReminder',
  'addServiceReminder', // exact key — startsWith of itself
  'vin',

  // Fuel club cards (loyalty) settings sub-screen shipped en+de-only, so the
  // whole screen — including the menu tile that opens it — was English for
  // French users.
  'loyalty',

  // #1373 phase 2 — the Feature management section in Settings: every
  // per-feature label, description and blocked-transition tooltip.
  'featureManagementSection',
  'featureLabel_',
  'featureDescription_',
  'featureBlockedEnable_',
  'featureBlockedDisable_',

  // #1374 phase 2 — the GPS trip-path overlay card on the trip detail screen.
  'tripPath',

  // #3587 — the driving-lessons combustion-health family + the
  // upshift-cruise insight + the fuel-breakdown label were caught
  // rendering ENGLISH on a French device (field captures 2026-07-21):
  // the MT autofill had copied the source text verbatim. These lesson
  // surfaces are core French-reachable — hand-French required.
  'lessonCombustionHealth',
  'insightUpshiftCruise',
  'fuelBreakdownHighRpmCruise',

  // #1401 phase 6 — the adapter-capability card on the Edit vehicle screen.
  'obd2Capability',

  // #1401 phase 7b — the verified-by-adapter badge on every fill-up card and
  // the variance dialog inside the Add fill-up flow.
  'fillUpReconciliation',

  // #1439 — the auto-record consent scope-clarification badge, help dialog
  // and revoke hint on the Edit vehicle screen.
  'autoRecordConsent',
];
