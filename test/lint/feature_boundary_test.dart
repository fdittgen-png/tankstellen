// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_graph.dart';

/// Feature-boundary gate (#3132, epic #3129) — the import-direction lint.
///
/// The feature-first layout describes folders, not the dependency graph:
/// the 2026-06-10 audit found 787 cross-feature imports across 110
/// directed pairs with 24 bidirectional cycles, plus 101 core→feature
/// inversions (the #3130 domain kernel removed ~310 of them; the
/// baselines below are the post-kernel measurement). This test freezes
/// the remaining graph and lets it move in ONE direction only.
///
/// ## What counts as a violation
///
///   * **feature → feature** — a file under `lib/features/<a>/` importing
///     (or exporting) a file under `lib/features/<b>/` (`a != b`) that is
///     NOT `lib/features/<b>/api.dart`. Every feature's public contract is
///     its `api.dart` barrel; reaching into `providers/`, `data/`,
///     `domain/` or `presentation/` of another feature is the violation.
///   * **core → feature** — a file under `lib/core/` importing anything
///     under `lib/features/` (the barrel does NOT excuse this direction:
///     core must never depend on features at all — epic #3129's goal).
///   * **feature → app shell** (#3133) — a file under `lib/features/`
///     importing anything under `lib/` OUTSIDE `core/`, `features/` and
///     `l10n/` (i.e. `lib/app/` + `lib/main.dart`). The shell is the
///     composition root: it may depend on features, never the other way
///     round. Shared shell widgets belong in `lib/core/widgets` /
///     `lib/core/navigation` (#3133 moved responsive_layout,
///     settings_app_bar_action, current_shell_branch_provider and
///     search_fab_action_provider there). The shell→feature direction
///     (`lib/app/routes/` building feature screens) is the composition
///     root's job and stays out of scope.
///
/// ## Relative-import resolution (the audit's key finding)
///
/// The codebase uses *relative* imports exclusively — a
/// `package:tankstellen/` grep finds **zero** cross-feature imports while
/// the real count is in the hundreds. Every `import`/`export` URI is
/// therefore resolved against the importing file's directory (and
/// `package:tankstellen/` URIs against `lib/`) before classification.
///
/// ## The only-decreasing ratchet
///
/// The baselines are **exact-match** snapshots (same mechanism as the
/// `file_length_test` shrink signal):
///
///   1. a count above its baseline entry — or a brand-new pair — fails CI;
///   2. a count below its baseline entry ALSO fails ("stale baseline") so
///      every single decrement is locked in by updating the map in the
///      same PR and can never silently creep back.
///
/// NEVER raise an entry or add a new pair. The targets are: zero
/// core→feature imports, zero bidirectional cycles, and every surviving
/// feature→feature edge routed through `api.dart`.
void main() {
  // importing feature -> imported feature -> count (api.dart exempt).
  final featurePairs = <String, int>{};
  // imported feature -> count of lib/core/ files importing it.
  final coreImports = <String, int>{};
  // importing feature -> count of its imports into the app shell (#3133).
  final shellImports = <String, int>{};
  final violationLines = <String>[];

  // The barrel-aware graph (#4346): every feature -> feature edge,
  // api.dart included.
  final barrelAwareEdges = <String, int>{};
  var featureSccs = <List<String>>[];

  // ---------------------------------------------------------------------
  // Scan: resolve every import/export directive in lib/ to a lib/ path.
  // #4346 — one scanner, tool/architecture_graph.dart, feeds both graphs:
  // the reach-in rules below are unchanged (the exact baselines prove it),
  // and the same pass yields the barrel-aware graph.
  // ---------------------------------------------------------------------
  setUpAll(() {
    expect(
      Directory('lib').existsSync(),
      isTrue,
      reason: 'lib/ must exist at project root',
    );
    final inventory = ArchitectureInventory.scan();
    featurePairs.addAll(inventory.reachInPairs);
    coreImports.addAll(inventory.coreImportsByFeature);
    shellImports.addAll(inventory.shellImportsByFeature);
    violationLines.addAll(inventory.reachInLines);
    barrelAwareEdges.addAll(inventory.featureEdges);
    featureSccs = inventory.featureSccs;
  });

  /// Renders [actual] as the Dart map literal to paste over a baseline.
  String literalOf(Map<String, int> actual) {
    final keys = actual.keys.toList()..sort();
    return keys.map((k) => "    '$k': ${actual[k]},").join('\n');
  }

  /// All keys whose actual count differs from its baseline entry, with
  /// the direction of the drift spelled out.
  List<String> driftOf(Map<String, int> actual, Map<String, int> baseline) {
    final drift = <String>[];
    for (final key in {...actual.keys, ...baseline.keys}) {
      final a = actual[key] ?? 0;
      final b = baseline[key] ?? 0;
      if (a > b) drift.add('$key: $a (baseline $b) — REGRESSION, revert it');
      if (a < b) drift.add('$key: $a (baseline $b) — stale, lower the entry');
    }
    return drift..sort();
  }

  test('every feature exposes an api.dart public barrel', () {
    final missing = <String>[];
    for (final dir in Directory('lib/features').listSync()) {
      if (dir is! Directory) continue;
      final path = dir.path.replaceAll(r'\', '/');
      if (!File('$path/api.dart').existsSync()) missing.add(path);
    }
    expect(
      missing..sort(),
      isEmpty,
      reason:
          'Every feature directory must expose a public api.dart barrel '
          '(#3132) — the only file other features may import.\n'
          'Missing:\n${missing.join('\n')}',
    );
  });

  test('feature → feature imports never exceed the per-pair baseline', () {
    final drift = driftOf(featurePairs, _featurePairBaseline);
    expect(
      drift,
      isEmpty,
      reason:
          'Cross-feature import graph drifted from the only-decreasing '
          'baseline (#3132).\n'
          'A new/raised pair means a feature reached into another feature\'s '
          'internals — import its api.dart barrel (or move the shared type '
          'to lib/core/domain) instead. A lowered pair must be locked in by '
          'updating _featurePairBaseline in the same PR.\n\n'
          'Drift:\n${drift.join('\n')}\n\n'
          'Up-to-date baseline literal:\n${literalOf(featurePairs)}\n\n'
          'All current cross-feature imports:\n'
          '${(violationLines..sort()).join('\n')}',
    );
  });

  test('core → feature imports never exceed the (target-zero) baseline', () {
    final drift = driftOf(coreImports, _coreImportBaseline);
    expect(
      drift,
      isEmpty,
      reason:
          'core → feature is the WORST inversion direction: lib/core/ '
          'must never depend on lib/features/ at all (epic #3129; the '
          'api.dart barrel does not excuse it). Invert the dependency '
          '(callback / interface in core, implementation in the feature) or '
          'move the shared type to lib/core/. A lowered count must be locked '
          'in by updating _coreImportBaseline in the same PR.\n\n'
          'Drift:\n${drift.join('\n')}\n\n'
          'Up-to-date baseline literal:\n${literalOf(coreImports)}',
    );
  });

  test('feature → app-shell imports never exceed the (target-zero) baseline',
      () {
    final drift = driftOf(shellImports, _shellImportBaseline);
    expect(
      drift,
      isEmpty,
      reason:
          'feature → app-shell inverts the composition root: lib/app/ '
          'composes features, so a feature importing lib/app/ (or '
          'lib/main.dart) makes the shell unchangeable without touching '
          'features (#3133). Move the shared widget/provider to '
          'lib/core/widgets / lib/core/navigation, or navigate via '
          'go_router\'s context API / RoutePaths instead of app/router.dart. '
          'A lowered count must be locked in by updating '
          '_shellImportBaseline in the same PR.\n\n'
          'Drift:\n${drift.join('\n')}\n\n'
          'Up-to-date baseline literal:\n${literalOf(shellImports)}',
    );
  });

  test('bidirectional feature cycles never exceed the baseline', () {
    final cycles = <String>{};
    for (final key in featurePairs.keys) {
      final parts = key.split(' -> ');
      final reverse = '${parts[1]} -> ${parts[0]}';
      if (featurePairs.containsKey(reverse)) {
        final pair = [parts[0], parts[1]]..sort();
        cycles.add('${pair[0]} <-> ${pair[1]}');
      }
    }
    final sorted = cycles.toList()..sort();
    expect(
      sorted.length,
      _cycleBaseline,
      reason:
          'Bidirectional feature cycles changed (baseline '
          '$_cycleBaseline, target 0). A new cycle is a hard architectural '
          'regression — break it before merging. A broken cycle must be '
          'locked in by lowering _cycleBaseline in the same PR.\n\n'
          'Current cycles:\n${sorted.join('\n')}',
    );
  });

  // -----------------------------------------------------------------------
  // #4346 — the barrel-aware graph. The ratchets above exempt api.dart, so
  // a cycle built only from public barrels was invisible to them. These two
  // pin the ACTUAL graph's cycles. They do not ban a new public dependency:
  // only a new mutual pair or a change in cycle membership fails.
  // -----------------------------------------------------------------------

  test('barrel-aware mutual feature pairs match the baseline (#4346)', () {
    final actual = mutualPairsOf(barrelAwareEdges.keys);
    final drift = [
      for (final p in actual)
        if (!_barrelAwareMutualPairBaseline.contains(p)) '$p — NEW, break it',
      for (final p in _barrelAwareMutualPairBaseline)
        if (!actual.contains(p)) '$p — gone, remove it from the baseline',
    ];
    expect(
      drift,
      isEmpty,
      reason:
          'Mutual feature dependencies INCLUDING api.dart imports drifted '
          '(#4346). An import through a barrel is still a dependency, so two '
          'features that reach each other through their barrels still form '
          'a cycle. Break a new one before merging; lock a broken one in by '
          'removing it from _barrelAwareMutualPairBaseline in the same PR. '
          'Run `dart run tool/architecture_graph.dart` for the full graph.\n\n'
          'Current pairs:\n${actual.join('\n')}',
    );
  });

  test('barrel-aware feature SCC membership matches the baseline (#4346)',
      () {
    final actual = [for (final scc in featureSccs) scc.join(', ')];
    expect(
      featureSccs,
      _featureSccBaseline,
      reason:
          'The strongly connected components of the feature graph '
          '(api.dart imports included) changed (#4346). A cycle through '
          'three or more features — even through public barrels only — is '
          'a component here while it is zero mutual pairs. A feature that '
          'joined a component, or a new component, is a regression; a '
          'feature that left one must be locked in by updating '
          '_featureSccBaseline in the same PR. Run '
          '`dart run tool/architecture_graph.dart` for the full graph.\n\n'
          'Current components:\n${actual.join('\n')}',
    );
  });
}

/// Post-#3130 measurement (2026-06-11): cross-feature imports that do NOT
/// go through the target feature's `api.dart` barrel, grouped
/// `importing-feature -> imported-feature`. ONLY EVER DECREASES — never
/// raise an entry, never add a pair; remove an entry when it hits 0.
///
/// #3137 (OBD2 extraction) re-attributed the moved stack's edges: former
/// intra-`consumption` and `consumption -> X` imports now appear as
/// `obd2 -> X`, and every `X -> obd2` consumer goes through the new
/// `obd2/api.dart` barrel (exempt). Same graph, new attribution — the
/// `obd2 -> *` entries are the decomposition's measured starting point.
const _featurePairBaseline = <String, int>{
  'alerts -> map': 1,
  'approach -> favorites': 1,
  'approach -> profile': 8,
  'calculator -> profile': 1,
  'calculator -> search': 3,
  'calculator -> vehicle': 1,
  'car -> widget': 1,
  // #3743 (epic item 1, charging extraction, step 4/5) — re-attributed
  // from 'consumption -> vehicle' (23 -> 21). The 8 'consumption -> ev'
  // edges hit ZERO: the moved charging surfaces now import the ev
  // barrel for ChargingLog + the cost calculator.
  'charging -> vehicle': 2,
  'carbon -> vehicle': 1,
  // #3743 (epic item 1, receipts_ocr extraction) — the share-receipt
  // handler moved out and now imports the feature_management barrel: 21→19.
  'consumption -> feature_management': 2,
  // #3884 — 2 → 1: the backup export moved into fill_ups' shared
  // BackupExportFlow, so consumption_app_bar_actions dropped its direct
  // vehicle_providers import.
  'consumption -> vehicle': 1,
  'driving -> approach': 1,
  'driving -> feature_management': 6,
  'driving -> glide_coach': 2,
  'driving -> map': 3,
  // #3884 — 5 → 4: the voice-announcements tile (and its
  // voiceAnnouncementsEnabledProvider gate) left driving_settings_section
  // for Settings → Prices & alerts.
  'driving -> profile': 3,
  'driving -> search': 1,
  // #3743 (epic item 1, driving_score extraction, step 3/5) — the 35
  // edges are former INTRA-consumption imports of the trip stack
  // (trip_recorder/summary, accel gate, engine power factor, trip-detail
  // charts) — #3137-precedent decomposition edges that collapse onto the
  // trips barrel in step 5. All inbound edges are barrel-routed.
  'ev -> search': 1,
  'ev -> vehicle': 1,
  'favorites -> alerts': 1,
  'favorites -> price_history': 1,
  'favorites -> profile': 1,
  'favorites -> search': 1,
  'favorites -> widget': 1,
  'feature_management -> profile': 2,
  // #3743 (epic item 1, fill_ups extraction, step 2/5) — re-attributed
  // edges of the moved fill-up/tank/reconciliation/backup stack. The 36
  // 'fill_ups -> consumption' edges are former INTRA-consumption imports
  // of the trip stack (trip_history_repository/trip_recorder/summary,
  // eco/gps helpers) — the #3137 precedent: they collapse onto the trips
  // barrel when trips is extracted. All inbound edges route through
  // fill_ups/api.dart (exempt), so consumption<->achievements and
  // consumption<->carbon cycles broke (17 -> 15).
  'fill_ups -> carbon': 2,
  'fill_ups -> ev': 4,
  'fill_ups -> profile': 2,
  'fill_ups -> vehicle': 13,
  'glide_coach -> feature_management': 2,
  'itinerary -> profile': 1,
  'itinerary -> route_search': 3,
  'itinerary -> search': 1,
  'map -> ev': 5,
  'map -> itinerary': 1,
  'map -> profile': 1,
  'map -> route_search': 6,
  'map -> search': 10,
  // #3743 — the TripRecordingController inversion (epic item 2): the
  // controller's coaching-hint import moved to the core domain kernel and
  // the GPS-estimate folder now sits behind the obd2-owned
  // TripGpsEstimateOverlay seam (consumption implements it via the
  // barrel). 42 → 40.
  'obd2 -> driving': 1,
  'obd2 -> feature_management': 4,
  // #4315 — 10 → 9: fuel_rate_estimator imported reference_vehicle only
  // for the deleted #1625 η_v curve point.
  'obd2 -> vehicle': 9,
  'price_history -> feature_management': 6,
  'profile -> alerts': 2,
  'profile -> approach': 1,
  // #3743 (epic item 1) — 'profile -> consumption' hit ZERO: all 10 edges
  // were the developer-tools pump-OCR tester reaching into the OCR stack,
  // which now lives in features/receipts_ocr behind its api.dart barrel.
  // This also breaks the profile <-> consumption cycle (18 → 17).
  // #3884 — 52 → 47: the Settings root + topic screens import the
  // feature_management barrel; the old root's 4 direct imports and the
  // three manifest-fallback reads in feature_localization are gone.
  // 'profile -> driving' (1 → 0) and 'profile -> widget' (1 → 0) hit
  // zero the same way (driving/api.dart + widget/api.dart), which also
  // broke the driving <-> profile and widget <-> profile cycles.
  'profile -> feature_management': 45,
  'profile -> search': 2,
  // #3908 (Epic #3907) — 2 → 1: the dashboard's synced_data_card reach-in
  // to sync/providers is gone (the overview card imports the barrel).
  'profile -> sync': 1,
  'profile -> vehicle': 3,
  'route_search -> profile': 11,
  'route_search -> search': 1,
  'search -> approach': 1,
  'search -> ev': 4,
  'search -> favorites': 4,
  'search -> feature_management': 8,
  'search -> loyalty': 1,
  'search -> map': 1,
  'search -> profile': 15,
  'search -> route_search': 14,
  'search -> station_detail': 3,
  'search -> widget': 2,
  // #4217 — 4 → 2: `profile_choice_step.dart` needed the manifest and
  // the build channel for the fleet card, so its two reach-ins were
  // replaced by the `feature_management/api.dart` barrel. Locked in
  // here, per the house rule that a win is recorded in the same PR.
  'setup -> feature_management': 2,
  'setup -> profile': 3,
  'setup -> vehicle': 7,
  'station_detail -> alerts': 2,
  'station_detail -> favorites': 1,
  'station_detail -> feature_management': 2,
  'station_detail -> payment': 3,
  'station_detail -> price_history': 2,
  'station_detail -> profile': 1,
  'station_detail -> route_search': 1,
  'station_detail -> search': 8,
  'station_detail -> sync': 1,
  'station_services -> station_detail': 1,
  // #3447 — data_transparency's "sync now" replays the app-layer pull
  // registry instead of importing the feature notifiers directly.
  // #3743 (epic item 5) — the entity sync configs moved into their owning
  // features and the sync feature's consumers switched to the alerts /
  // consumption barrels, zeroing 'sync -> alerts' (was 2) and
  // 'sync -> consumption' (was 2) — which also breaks the
  // consumption <-> sync cycle.
  'sync -> favorites': 1,
  'sync -> feature_management': 2,
  'sync -> vehicle': 1,
  // #3743 (epic item 1, trips extraction, step 5/5) — the mega-feature's
  // hub edges re-attributed to the trips feature; every inbound edge
  // (obd2 39, driving_score 35, fill_ups 34, vehicle 11, carbon 6,
  // achievements 4, driving 4, search 4, approach 2, calculator 1, core,
  // shell) now routes through trips/api.dart — which broke the
  // consumption<->{approach,driving,search,vehicle} cycles (15 -> 11)
  // and zeroed EVERY '* -> consumption' pair. consumption itself is the
  // thin conso-mode tab shell (2 fm + 2 vehicle edges). The trips -> *
  // entries below are the decomposition's measured starting point for
  // epic items 2 (TripSink inversion) and 3 (barrel pruning).
  'trips -> approach': 8,
  'trips -> driving': 5,
  'trips -> glide_coach': 4,
  'trips -> map': 2,
  'trips -> profile': 6,
  'trips -> search': 2,
  'trips -> sync': 1,
  'trips -> vehicle': 19,
  'vehicle -> profile': 1,
  'widget -> price_history': 2,
  'widget -> profile': 3,
};

/// Post-#3130 measurement (2026-06-11): `lib/core/` files importing
/// `lib/features/` files, grouped by imported feature. Target **0** —
/// this direction is never legitimate. ONLY EVER DECREASES.
// #3131 — the alert-scan engine moved into features/alerts: alerts 17→3
// (the journal/trigger/telemetry seams remain), price_history and widget
// hit ZERO. #3137 — the obd2 extraction added no core→obd2 edge (the
// event-channel guard lives in core/utils since #3134).
// #3190 — station_services 19→18: the GB composition moved feature-side
// (uk_service_builder.dart), collapsing the builder's two UK imports into
// one seam.
// #3614 — search 2→1: BrandRegistry moved to lib/core/domain/, so the
// OSM brand enricher's import is core→core now (the search feature
// re-exports the registry to keep its public surface stable). The
// survivor is country_provider → search_provider.
// #3746 — station_services 18→17: the raw builder's switch is gone; each
// CountryServiceEntry carries a feature-side buildService factory and
// country_service_data.dart imports ONE file per country (FR's two
// service imports collapsed into france_service_builder.dart).
// #3743 (epic item 5) — the per-entity sync configs moved into their
// owning features: consumption 6→2 (baselines/fill_ups/trips/trips_json/
// trip_shares configs left core; the one add-back is user_data_sync's
// TripsSync.forgetAllForUser seam). alerts + itinerary stay flat: each
// lost its config's model import but supabase_sync_repository now
// imports the moved config (the legacy repo facade — its inversion is a
// follow-up).
// #3743 (epic item 1, step 2/5) — consumption 2 -> 1 + fill_ups 1: the
// co2_calculator's FillUp entity import followed the entity into
// features/fill_ups (kept as a direct entity import — pulling the barrel
// into core would drag presentation into core's closure).
const _coreImportBaseline = <String, int>{
  'alerts': 3,
  'feature_management': 3,
  'fill_ups': 1,
  'itinerary': 3,
  'map': 1,
  'profile': 4,
  'search': 1,
  'station_services': 17,
  // #3743 (step 5/5) — user_data_sync's TripsSync.forgetAllForUser seam
  // followed the sync config into features/trips (was 'consumption').
  'trips': 1,
};

/// Post-#3133 measurement (2026-06-11): `lib/features/` files importing
/// the app shell (`lib/` outside `core/`, `features/`, `l10n/`), grouped
/// by importing feature. Target **0**. ONLY EVER DECREASES.
// #3133 cut 16 → 3 by moving the shared shell widgets/providers to
// lib/core/. The 3 survivors all import app/router.dart for
// `routerProvider` — imperative no-context navigation (the share-receipt
// handler, the trip-recording banner and the home-widget click listener
// all run above/without the router's InheritedGoRouter, #1987), which
// needs a core-owned router seam to break.
// #3743 (epic item 1) — the share-receipt handler (one of consumption's
// two router.dart importers) moved to features/receipts_ocr: same edge,
// new attribution (consumption 2 → 1, receipts_ocr 0 → 1; total flat).
const _shellImportBaseline = <String, int>{
  'receipts_ocr': 1,
  // #3743 (step 5/5) — the trip-recording banner's router.dart import
  // followed it into features/trips (was 'consumption'). #3959 removed
  // the banner's tappable strip, and with it that import: trips reaches
  // ZERO. Keep it there — the recording form and the Trajets FAB own the
  // navigation now.
  'widget': 1,
};

/// Post-#3130 measurement (2026-06-11): bidirectional feature↔feature
/// cycles implied by [_featurePairBaseline]. Target **0**. ONLY EVER
/// DECREASES.
// #3743 (epic item 5) — 19 → 18: 'sync -> consumption' hit zero (entity
// sync configs moved home + barrel routing), breaking consumption <-> sync.
// #3743 (epic item 1) — 18 → 17: 'profile -> consumption' hit zero (the
// pump-OCR tester's targets moved to receipts_ocr, imported via barrel),
// breaking profile <-> consumption.
// #3743 (epic item 1, step 2/5) — 17 → 15: 'consumption -> achievements'
// and 'consumption -> carbon' hit zero (fuel_tab / monthly_fuel_charts
// moved to fill_ups), breaking both cycles.
// #3743 (epic item 1, step 5/5) — 15 → 11: every remaining
// consumption cycle (approach, driving, search, vehicle) broke when the
// trip stack moved behind trips/api.dart.
// #3884 — 11 → 9: 'profile -> driving' and 'profile -> widget' hit zero
// (barrel imports from the new Settings topic screens), breaking the
// driving <-> profile and widget <-> profile cycles.
const _cycleBaseline = 9;

/// #4346 — bidirectional feature pairs of the BARREL-AWARE graph: `a <-> b`
/// when some file under lib/features/a/ has an import or export directive
/// resolving into lib/features/b/ AND some file under lib/features/b/ has
/// one resolving into lib/features/a/, api.dart barrels included (unlike
/// [_cycleBaseline], which counts reach-ins only). Directives are resolved
/// by tool/architecture_graph.dart: relative and package:tankstellen URIs,
/// every branch of a conditional directive, hand-written Dart only.
/// Measured with that scanner by pinning this list empty and copying back
/// what the test reported. Target: empty. ONLY EVER SHRINKS.
const _barrelAwareMutualPairBaseline = <String>[
  'alerts <-> favorites',
  'approach <-> profile',
  'approach <-> trips',
  'carbon <-> fill_ups',
  'charging <-> fill_ups',
  'driving <-> obd2',
  'driving <-> profile',
  'driving <-> trips',
  'driving_score <-> obd2',
  'driving_score <-> trips',
  'ev <-> search',
  'favorites <-> search',
  'feature_management <-> profile',
  'fill_ups <-> obd2',
  'fill_ups <-> profile',
  'fill_ups <-> search',
  'fill_ups <-> trips',
  'fill_ups <-> vehicle',
  'map <-> search',
  'obd2 <-> trips',
  'obd2 <-> vehicle',
  'profile <-> search',
  'profile <-> trips',
  'profile <-> vehicle',
  'profile <-> widget',
  'route_search <-> search',
  'search <-> station_detail',
  'search <-> trips',
  'sync <-> trips',
  'trips <-> vehicle',
];

/// #4346 — the strongly connected components (two or more features) of
/// the same barrel-aware feature graph, each listed as its sorted members,
/// largest component first. A component is the set of
/// features that can each reach every other one along directive edges, so
/// it captures cycles through three or more features that no mutual pair
/// shows. Measured the same way as [_barrelAwareMutualPairBaseline].
/// Target: empty. Membership only ever shrinks.
const _featureSccBaseline = <List<String>>[
  [
    'alerts',
    'approach',
    'carbon',
    'charging',
    'driving',
    'driving_score',
    'ev',
    'favorites',
    'feature_management',
    'fill_ups',
    'glide_coach',
    'itinerary',
    'map',
    'obd2',
    'price_history',
    'profile',
    'receipts_ocr',
    'route_search',
    'search',
    'station_detail',
    'sync',
    'trips',
    'vehicle',
    'widget',
  ],
];
