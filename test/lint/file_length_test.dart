// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#1680 / #2351): no *new* handwritten Dart file in
/// `lib/` may exceed [_lineLimit] lines, and no *grandfathered* file may
/// **grow** beyond its snapshot line count.
///
/// ### Cap for new files
/// The ~400-line norm keeps files reviewable and decomposable. Any file
/// not in [_grandfatheredSnapshot] that exceeds the cap fails CI.
///
/// ### One-way ratchet for grandfathered files (#2351)
/// Each grandfathered file was measured when it entered the set; that
/// count is recorded in [_grandfatheredSnapshot]. The test enforces two
/// invariants:
///
/// 1. **Shrink signal** — if a grandfathered file has been decomposed
///    below the cap, the entry must be removed (stale-baseline check).
/// 2. **Growth block** — if a grandfathered file's current line count
///    *exceeds* its snapshot, CI fails immediately. This prevents
///    balloon growth across PRs with no incremental signal.
///
/// When a file legitimately needs more lines during a refactoring, the
/// snapshot entry must be updated in the same PR, with a comment
/// explaining why.
///
/// Generated files are not scanned: `.g.dart` / `.freezed.dart` and the
/// `lib/l10n/app_localizations*.dart` outputs of `flutter gen-l10n`
/// (each thousands of lines, none handwritten).
void main() {
  const lineLimit = 400;

  // Snapshot map: grandfathered path → line count at time of
  // grandfathering (SPDX header excluded, same as the runtime count).
  // The growth ratchet fails CI if current > snapshot. Update the value
  // here when a legitimate re-grandfathering is needed (same PR, with
  // a comment). NEVER add new entries — use decomposition instead.
  const grandfatheredSnapshot = <String, int>{
    // #2465 — re-grandfathered 934 → 950: a post-first-frame warm-up block
    // that reads `obd2CommDiagnosticsGateProvider` to arm the gated OBD2
    // comm-health collector from `Feature.debugMode` (mirrors the adjacent
    // #1925 `obd2DebugSessionLoggingProvider` kick-off).
    'lib/app/app_initializer.dart': 950,
    // #2415 — background_service.dart graduated: the scan body moved into
    // BackgroundAlertScanCoordinator + BackgroundScanRunners +
    // BackgroundPriceHistoryWriter, so the file dropped from 782 to ~246
    // lines (below the cap). Removed from the snapshot per the shrink
    // ratchet; the extracted files are all new and under 400.
    'lib/core/country/country_config.dart': 723,
    // #2373 — re-grandfathered 868 → 887: one required `sourceUrl` field
    // added to every per-country FuelServicePolicy row (19 data lines) so
    // the country-service header can link the upstream data source.
    'lib/core/services/country_service_registry.dart': 887,
    'lib/features/consumption/data/obd2/adapter_registry.dart': 500,
    'lib/features/consumption/data/obd2/auto_trip_coordinator.dart': 726,
    // #2456 — re-grandfathered 457 → 481: two new pure parsers,
    // `parseBaroPressureKpa` (PID 0x33) and `parseCommandedEquivalenceRatio`
    // (PID 0x44, commanded λ), each with their dartdoc, so the
    // fuel-rate estimator can use the ECU's real mixture + ambient
    // air-density instead of the assumed-stoich AFR / sea-level pressure.
    // #2458/#2459 — re-grandfathered 481 → 538: nine new pure parsers,
    // each with dartdoc — bank-2 trims (0x08/0x09), absolute load (0x43),
    // accelerator-pedal D/E/F (0x49/0x4A/0x4B), engine-oil (0x5C) +
    // ambient-air (0x46) temps. All trivial decoders reusing the existing
    // `_parseFuelTrim` / `_parse1BytePercent` / `_parseModeOneBody`
    // plumbing. Decomposition tracked separately by #2187/#2188.
    'lib/features/consumption/data/obd2/elm327_parsers.dart': 538,
    // #2456 — re-grandfathered 471 → 524: the live integrator gained λ
    // (PID 0x44, 2 Hz) + baro (PID 0x33, 0.5 Hz) supportsPid-gated
    // subscriptions and threads both into the MAF + speed-density fuel
    // derivation (effective AFR + air-density correction). Decomposition
    // is tracked separately by #2187/#2188.
    // #2457 — re-grandfathered 524 → 533: subscribeAllTiers re-expressed
    // as four cadence tiers (PidTier) + the centralised `_sub` helper that
    // carries the discover-all ∩ target-set gate (optionalPid) so each PID
    // is a one-line tier assignment, with #2458 tier slots commented in.
    // Net +9 is the helper + its dartdoc, not new branching. Decomposition
    // is tracked separately by #2187/#2188.
    // #2458/#2459 — re-grandfathered 533 → 652: filled the #2457 tier
    // slots with nine supportsPid-gated subscriptions (pedal D/E/F →
    // dynamics, abs-load → mixture, bank-2 trims → slow, oil + ambient →
    // thermal) + their latches and latest-value getters that `_emit`
    // persists onto each TripSample (#2459), + the bank-2 fold into
    // `_applyTrim`. Each is a one-line `_sub` call carrying its own gate.
    // Decomposition is tracked separately by #2187/#2188.
    'lib/features/consumption/data/obd2/live_sample_snapshot.dart': 652,
    // #2379 — re-grandfathered 1457 → 1468: threaded the
    // `logFailureAsError` flag through `connect()` (param + doc + the
    // guarded `if` around the now-conditional connect-failed trace) so a
    // recoverable connect attempt stops flooding the error log. Net +11;
    // decomposition is tracked separately by #2187/#2188.
    // #2456 — re-grandfathered 1468 → 1505: two new read helpers
    // (`readBaroPressureKpa` PID 0x33, `readCommandedEquivalenceRatio`
    // PID 0x44) + their supportsPid-gated use in the MAF + speed-density
    // steps of `readFuelRateLPerHour` + the new optional params on the
    // `estimateFuelRateLPerHourFromMap` forwarder. Decomposition tracked
    // by #2187/#2188.
    // #2465 — re-grandfathered 1505 → 1552: the connect/init path now tees
    // the gated comm-health diagnostics — a `linkKind` field, a
    // `beginSession` + `recordAdapterIdentity` stamp, and the two
    // `recordHandshakeLine` tees alongside the existing
    // `Obd2DebugSessionRecorder.recordHandshakeCommand` calls (all
    // `if(!enabled)`-gated, no-op in prod). Decomposition tracked by
    // #2187/#2188.
    // #2458 — re-grandfathered 1552 → 1599: bank-2 trim folded into
    // `_applyFuelTrimCorrection` (supportsPid-gated PIDs 0x08/0x09) + the
    // updated `applyFuelTrimCorrection` static forwarder + three new read
    // helpers (bank-2 STFT/LTFT, absolute load 0x43). Decomposition tracked
    // by #2187/#2188.
    'lib/features/consumption/data/obd2/obd2_service.dart': 1599,
    // #2428 — re-grandfathered 1235 → 1241: the recoverable VIN-read catch
    // dropped its `errorLogger.log([storage], …)` (and the now-unused
    // error_logger import, −1 line) in favour of a `debugPrint` breadcrumb
    // + an 8-line comment documenting WHY the transient is reclassified
    // (matching the #2379/#2424 precedent in this same map). Net +6: the
    // explanatory rationale, not behaviour. Decomposition of this god-class
    // is tracked under #2187/#2188/#2190.
    // #2459 — re-grandfathered 1241 → 1288: the per-trip 'diagnostic
    // capture' flag (field + dartdoc + slow-cadence interval/guard) and
    // the `_emit` stamping of the six consumed-but-unstored signals
    // (λ/baro/absLoad/pedal/oil/ambient) + the slow-cadence raw mixture
    // inputs (MAF/MAP/STFT/LTFT). Decomposition tracked by #2187/#2188/#2190.
    // #2506 — re-grandfathered 1288 → 1360: the live GPS-physics estimate +
    // coaching + GPS speed/distance fallback for no-fuel-PID cars. The
    // SUBSTANTIVE new logic (the per-fix fold, the coaching window, and the
    // reading-overlay) was extracted to the new pure-Dart
    // `gps_live_estimate_folder.dart` (shared with the GPS-only pipeline so
    // they can't diverge); only the controller-local WIRING remains here —
    // the injected folder field + GPS-speed latch + coaching getter, the
    // `updateGpsFix(speedKmh:)` latch, the `_emit` effective-speed/distance
    // fallback, and the no-fuel-PID overlay call. Decomposition of this
    // god-class is tracked by #2187/#2188/#2190.
    // #2509 — re-grandfathered 1360 → 1402: the GPS start-time fallback that
    // stops a real GPS-tracked drive with a dead OBD2 link from being
    // silently discarded — the `_gpsStartedAt`/`_gpsEndedAt` latch (set in
    // `updateGpsFix`), the `_finaliseSummary` start/end back-fill, and the
    // `gpsFixCount` getter the persist guard reads. Pure wiring + rationale;
    // decomposition of this god-class is tracked by #2187/#2188/#2190.
    'lib/features/consumption/data/obd2/trip_recording_controller.dart': 1402,
    // #2442 — re-grandfathered 496 → 513: the save flow now raises the
    // guided reconciliation workflow after a plein save (a 7-line
    // await-then-route call into the extracted
    // `runReconciliationWorkflowIfPending` launcher + its rationale
    // comment). The workflow + apply logic itself lives in the extracted
    // launcher/widget; only the trigger call stays on the screen.
    // Decomposition of this god-class is tracked under #2187/#2188/#2190.
    'lib/features/consumption/presentation/screens/add_fill_up_screen.dart':
        513,
    // #2380 — +5: closest-station radar card at the top of the
    // recording column + a SingleChildScrollView wrap so the longer
    // column (radar + 5 metric cards + coaching card) scrolls instead
    // of overflowing on short viewports.
    // #2391 — re-grandfathered 1069 → 1074: GPS-only Avg card now shows
    // the measured-vs-estimate (`~`) decision via the extracted
    // `TripAvgConsumptionCard` widget (the substantial logic moved off
    // the screen), and the Fuel-used card gained a GPS-estimate fallback
    // branch. Decomposition tracked under the existing god-class
    // follow-ups (#2187/#2188/#2190).
    // #2509 — re-grandfathered 1074 → 1088: the `_onStop` handler now
    // surfaces a localized "no movement detected" SnackBar when the stop
    // returned a stationary discard (`StoppedTripResult.discardedNoMovement`),
    // so a Stop tap that saves nothing is never silent data loss. Pure UI
    // wiring; decomposition tracked under #2187/#2188/#2190.
    'lib/features/consumption/presentation/screens/trip_recording_screen.dart':
        1088,
    'lib/features/consumption/presentation/widgets/broken_map_widgets.dart':
        439,
    'lib/features/consumption/presentation/widgets/obd2_adapter_picker.dart':
        439,
    'lib/features/consumption/presentation/widgets/trip_path_map_card.dart':
        463,
    // #2441 — re-grandfathered 879 → 911: split the trip-vs-pump
    // reconciliation into a detect-vs-apply seam. The detector still
    // lives in reconciler.dart; the apply step (`applyReconciliation`)
    // and the surface-or-clear branch must stay on `FillUpList` because
    // they mutate its state. The PendingReconciliation value object and
    // the PendingReconciliations notifier were already extracted to
    // their own files; only the seam wiring remains here.
    // #2442/#2444 — re-grandfathered 911 → 964: the silent save is gone
    // (the seam now only publishes the gap), and the two CONSENTED apply
    // paths landed here — `applyReconciliation` (Path A, consented
    // correction) and `applyVirtualTrajet` (Path B, virtual trajet).
    // Both must stay on `FillUpList` / its trip-history sibling because
    // they mutate provider state; the workflow UI + launcher are
    // extracted. Decomposition tracked under #2187/#2188/#2190.
    // #2445 — re-grandfathered 964 → 975: the surface-or-clear branch
    // gained a keep-prior-gap guard so a clean later plein never silently
    // drops a still-unresolved deferred gap (the decision is never lost).
    // Lives on `FillUpList` because it reads + mutates the pending-gap
    // provider in the same save path. Decomposition tracked #2187/#2188.
    'lib/features/consumption/providers/consumption_providers.dart': 975,
    // #2509 — re-grandfathered 1180 → 1217: the persist guard in
    // `_saveToHistory` was tightened from the buggy disjunction
    // (`startedAt == null || distance < 0.01`, which silently discarded a
    // real GPS-tracked drive with a dead OBD2 link) to the conjunction
    // #1923 intended, `_saveToHistory` now returns a `TripPersistOutcome`,
    // and a genuine stationary discard logs a structured `errorLogger`
    // entry (no more silent discard). The `_RecordingPipelineHostAdapter`
    // forwards the new `gpsFixCount` param + return type. Pure wiring +
    // rationale; decomposition of this god-class is tracked #2187/#2188/#2190.
    // #2392 — re-grandfathered 1125 → 1162: wired the OBD2-ground-truth
    // physicsScale calibration into `_saveToHistory` (one fire-and-forget
    // call + the `_calibratePhysicsScale` resolve/persist helper; the EWMA
    // math itself lives in the standalone `PhysicsScaleCalibrator`).
    // Decomposition of this god-class is tracked under #2187/#2188/#2190.
    // #2459 — re-grandfathered 1162 → 1180: the `_readDiagnosticCaptureFlag`
    // closure (mirrors `_readOemPidsFlag`: reads Feature.debugMode, swallows
    // provider-wiring errors → safe off) + its injection into the pipeline.
    // Decomposition tracked by #2187/#2188/#2190.
    'lib/features/consumption/providers/trip_recording_provider.dart': 1217,
    'lib/features/feature_management/data/legacy_toggle_migrator.dart': 647,
    'lib/features/map/presentation/widgets/station_map_layers.dart': 544,
    // #2382 — +5 for Feature.approachOverlay's three per-feature switch
    // cases (label / description / blocked-enable). Intrinsic per-feature
    // growth in this switch-based section; full decomposition is its own
    // task, so the snapshot tracks the new size.
    'lib/features/profile/presentation/widgets/feature_management_section.dart':
        711,
    'lib/features/vehicle/domain/entities/vehicle_profile.dart': 453,
    'lib/features/vehicle/presentation/screens/edit_vehicle_screen.dart': 806,
    'lib/features/vehicle/presentation/widgets/auto_record_section.dart': 830,
    'lib/features/vehicle/presentation/widgets/calibration_section.dart': 465,
    'lib/features/widget/data/home_widget_service.dart': 696,
  };

  bool isScanned(String path) {
    if (!path.endsWith('.dart')) return false;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return false;
    }
    // `flutter gen-l10n` output — generated, not handwritten.
    if (path.startsWith('lib/l10n/')) return false;
    return true;
  }

  int effectiveLines(File file) {
    final rawLines = file.readAsLinesSync();
    // The standard MIT SPDX header (#2053) adds 3 lines at the top of
    // every file (copyright, SPDX-License-Identifier, blank). Discount
    // it so the 400-line norm measures actual content, not boilerplate.
    final headerOffset =
        rawLines.length >= 2 &&
                rawLines[0].contains('Copyright (c) 2026 Florian DITTGEN') &&
                rawLines[1].contains('SPDX-License-Identifier')
            ? 3
            : 0;
    return rawLines.length - headerOffset;
  }

  test('no new Dart file in lib/ exceeds $lineLimit lines (#1680)', () {
    final offenders = <String>[];
    final stillOver = <String>{};
    // Growth ratchet violations: grandfathered file grew beyond snapshot.
    final grownFiles = <String>[];
    // Decomposition candidates: grandfathered files now in 400-800 band.
    final decompositionCandidates = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!isScanned(path)) continue;
      final lines = effectiveLines(entity);

      if (grandfatheredSnapshot.containsKey(path)) {
        if (lines > lineLimit) {
          stillOver.add(path);
          // Growth ratchet (#2351): fail if current > snapshot.
          final snapshot = grandfatheredSnapshot[path]!;
          if (lines > snapshot) {
            grownFiles.add(
              '$path  ($lines lines, snapshot $snapshot, '
              'grew by ${lines - snapshot})',
            );
          }
          // Soft signal: grandfathered files in the 400-800 band are
          // prime decomposition candidates (#2187/#2188/#2190).
          if (lines <= 800) {
            decompositionCandidates.add('$path  ($lines lines)');
          }
        }
        // lines <= lineLimit → file graduated; stale-baseline check below.
      } else if (lines > lineLimit) {
        offenders.add('$path  ($lines lines)');
      }
    }

    // Soft print: list near-cap grandfathered files as decomposition hints.
    if (decompositionCandidates.isNotEmpty) {
      // ignore: avoid_print
      print(
        '\n[file_length_test] Decomposition candidates '
        '(grandfathered, 400-800 lines):\n'
        '${decompositionCandidates.join('\n')}\n',
      );
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'New / un-grandfathered Dart file(s) over $lineLimit lines. '
          'Decompose the file below the limit — splitting widgets, '
          'helpers, or providers into their own files. Offenders:\n'
          '${offenders.join("\n")}',
    );

    // Growth ratchet (#2351): a grandfathered file must not grow beyond
    // its snapshot line count.
    expect(
      grownFiles,
      isEmpty,
      reason:
          'Grandfathered file(s) have GROWN beyond their snapshot. '
          'Decompose the file or update the snapshot in this test with '
          'a comment explaining why more lines are justified.\n'
          '${grownFiles.join("\n")}',
    );

    // Shrink ratchet (#1680): a grandfathered file decomposed below the
    // limit must be removed from the snapshot map so the debt baseline
    // stays honest.
    final staleBaseline =
        grandfatheredSnapshot.keys.toSet().difference(stillOver);
    expect(
      staleBaseline,
      isEmpty,
      reason:
          'These files are no longer over $lineLimit lines — remove '
          'them from the `grandfatheredSnapshot` map in this test so '
          'the debt baseline stays honest:\n${staleBaseline.join("\n")}',
    );
  });
}
