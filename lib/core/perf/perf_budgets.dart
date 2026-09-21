// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Performance budgets for the surfaces that have one (#4163, epic #4155).
///
/// #4110 found and fixed the dominant startup cost by MEASURING it — the
/// guess ("Hive should be lazy") and the measured cause (national
/// datasets in the first-frame box, deserialised on the main isolate)
/// were different things. That was one pass over one surface. This file
/// is the standing version: a small number of ceilings on things a user
/// feels, each carrying the measurement that justified it.
///
/// ## Two kinds of budget, and why they are separated
///
/// **Structural budgets are asserted in CI.** How many widgets a row
/// builds, how many markers reach the map — these are device-independent
/// and they are what actually regresses when a card gains a feature.
/// A test can hold them honestly.
///
/// **Timing budgets are field signals.** A CI runner has no mid-range
/// Android GPU, so a frame-time assertion there measures the runner and
/// calls it the app. Those ceilings are recorded here and reported in
/// the field export next to the startup phases, where a real device
/// produced them.
///
/// **A budget nobody can defend is worse than none**, so every constant
/// below names the device and the scenario it came from, or says plainly
/// that it is not measured and why.
library;

import 'package:meta/meta.dart';

/// One surface's budget, with its provenance.
@immutable
class PerfBudget {
  const PerfBudget({
    required this.surface,
    required this.limit,
    required this.unit,
    required this.measuredOn,
    this.assertedInCi = false,
  });

  /// Not measured, and the reason — an explicit gap rather than a
  /// silence. [limit] is null and nothing asserts it.
  const PerfBudget.unmeasured({
    required this.surface,
    required this.unit,
    required String why,
  })  : limit = null,
        measuredOn = why,
        assertedInCi = false;

  final String surface;

  /// The ceiling, or null when the surface is deliberately unmeasured.
  final num? limit;

  final String unit;

  /// The device and scenario the number came from, or — for an
  /// unmeasured surface — why there is no number.
  final String measuredOn;

  /// Whether a test holds this ceiling. Timing budgets are false by
  /// design; see the library doc.
  final bool assertedInCi;

  bool get isMeasured => limit != null;
}

/// How many widgets one station row may build.
///
/// The list is the app's main surface and its rows got materially more
/// complex (#4091 badges, #3949 value-only pills, #4133 the presentation
/// split). A row is built once per visible station and again on every
/// filter change, so its widget count is the multiplier on everything
/// else. Structural, so CI can hold it.
const kStationRowWidgetBudget = PerfBudget(
  surface: 'station list row',
  limit: 260,
  unit: 'widgets in the StationCard subtree',
  measuredOn: 'MEASURED 2026-09-14 at 230 widgets — a fully-loaded row '
      '(brand, full address, three prices, freshness stamp, open state, '
      'three amenities) in station_row_budget_test. The ceiling is that '
      'measurement plus ~13% headroom, so one added element is not a '
      'false alarm and a doubling is. The first guess here was 120, '
      'which was wrong by a factor of two — hence the rule that a budget '
      'is measured before it is written',
  assertedInCi: true,
);

/// How many markers may reach the map before clustering.
///
/// This was a GUARD on an unbounded quantity until #4181; it is the
/// actual bound now. `StationMarkerModelBuilder` reads this constant and
/// enforces it: cull to the camera plus a screen of margin, then keep at
/// most this many by relevance (selection first, then cheapest for a
/// price sort / closest otherwise). Stations dropped by the second step
/// are reported as `omittedCount` and the map says "showing N of M",
/// because `clusterAlways: true` means a dropped station also makes a
/// cluster badge count fewer members than exist.
///
/// The history is worth keeping: the first version of this comment
/// claimed "the search radius cap and the per-country result cap
/// together bound a realistic result set below this". There is no
/// per-country result cap. Checking that plausible sentence is what
/// found the gap.
const kMapMarkerBudget = PerfBudget(
  surface: 'map markers',
  limit: 400,
  unit: 'markers built per frame',
  measuredOn: '400 is the point past which a mid-range device visibly '
      'stutters while panning. Since #4181 the builder ENFORCES it, so '
      'this is a derived ceiling rather than a hope about what a search '
      'returns; a dense-city 25 km result is ~250 and never reaches it',
  assertedInCi: true,
);

/// Cold start to a usable map.
///
/// The one #4110 and #4140 already measure. Reported, not asserted in
/// CI: a runner's cold start is not a phone's.
///
/// #4140 pinned down what "usable map" means — `StartupKpi` records
/// launch → the first painted frame carrying a readable price, and this
/// is the ceiling it is judged against. The structural half of that
/// issue (`startup_regression_gate_test.dart`) is what CI *can* hold:
/// the work this number was measured over cannot grow silently, even
/// though the number itself is a field signal.
const kColdStartBudget = PerfBudget(
  surface: 'cold start to usable map',
  limit: 2500,
  unit: 'ms',
  measuredOn: 'Samsung mid-range, cold cache, after #4110 moved the '
      'national datasets out of the first-frame box',
);

/// Hive open, all first-frame boxes.
///
/// #4140 fixed the SET this was measured over: the gate runs
/// `HiveFirstFrameBoxes.openAll` and fails if the boxes it opened are
/// not exactly the pinned ten, in either direction.
const kHiveOpenBudget = PerfBudget(
  surface: 'Hive open (first-frame boxes)',
  limit: 400,
  unit: 'ms',
  measuredOn: 'HiveOpenTiming names the slowest box in the field export; '
      'the ceiling is what #4110 left it at',
);

/// One background alert scan.
const kBackgroundScanBudget = PerfBudget(
  surface: 'background scan',
  limit: 20000,
  unit: 'ms',
  measuredOn: 'the scan already records its duration; the ceiling is the '
      'point past which WorkManager is at risk of being killed mid-run',
);

/// Route calculation, which grows with the number of corridor countries.
const kRouteCalculationBudget = PerfBudget.unmeasured(
  surface: 'route calculation',
  unit: 'ms',
  why: 'dominated by OSRM and the per-country fan-out, both network-bound '
      'and rate-limited — a local number would measure the fixture, not '
      'the feature. Needs a field span first (#4163)',
);

/// Warm start.
const kWarmStartBudget = PerfBudget.unmeasured(
  surface: 'warm start',
  unit: 'ms',
  why: 'no instrumentation yet; StartupTimer only arms on a cold launch',
);

/// Battery during a recording.
const kRecordingBatteryBudget = PerfBudget.unmeasured(
  surface: 'battery during recording',
  unit: '%/hour',
  why: 'the one a user notices without measuring, and the hardest to '
      'assert. A documented manual protocol is worth more than a fake '
      'automated number; it belongs with the on-device validation matrix '
      '(#3439)',
);

/// OBD2 telemetry frequency.
const kObd2SampleRateBudget = PerfBudget.unmeasured(
  surface: 'OBD2 telemetry frequency',
  unit: 'samples/min',
  why: 'sample counts are recorded per session, but the healthy rate is '
      'adapter-dependent (a K-line ATSP3 link is legitimately slower than '
      'CAN) — one ceiling across adapters would be wrong for most of them',
);

/// Every budget, for the field export and the coverage test.
const List<PerfBudget> kPerfBudgets = [
  kStationRowWidgetBudget,
  kMapMarkerBudget,
  kColdStartBudget,
  kHiveOpenBudget,
  kBackgroundScanBudget,
  kRouteCalculationBudget,
  kWarmStartBudget,
  kRecordingBatteryBudget,
  kObd2SampleRateBudget,
];

/// The budgets as export rows, reported beside the startup phases.
List<Map<String, Object?>> perfBudgetExportRows() => [
      for (final b in kPerfBudgets)
        {
          'surface': b.surface,
          'limit': b.limit,
          'unit': b.unit,
          'measured': b.isMeasured,
          'basis': b.measuredOn,
          'assertedInCi': b.assertedInCi,
        },
    ];
