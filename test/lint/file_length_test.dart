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
    // #2597 — re-grandfathered 950 → 957: the post-first-frame migration
    // block now also runs `ProfileRepository.dedupeCountryProfiles()` to
    // enforce one profile per country for existing duplicate users (a few
    // lines next to the adjacent country/language backfill migration).
    'lib/app/app_initializer.dart': 957,
    // #2415 — background_service.dart graduated: the scan body moved into
    // BackgroundAlertScanCoordinator + BackgroundScanRunners +
    // BackgroundPriceHistoryWriter, so the file dropped from 782 to ~246
    // lines (below the cap). Removed from the snapshot per the shrink
    // ratchet; the extracted files are all new and under 400.
    'lib/core/country/country_config.dart': 723,
    // #2373 — re-grandfathered 868 → 887: one required `sourceUrl` field
    // added to every per-country FuelServicePolicy row (19 data lines) so
    // the country-service header can link the upstream data source.
    // #2621 — re-grandfathered 887 → 909: the order-independent
    // `entriesByLatLng` (a `sync*` yielding EVERY box that contains a point,
    // not just the first declared) + its dartdoc, plus `entryByLatLng`
    // refactored to delegate to it. Fixes the FR-shadows-Catalonia bbox bug
    // that left cross-border routes with zero Spanish stations. Decomposition
    // of this registry is tracked separately by #2187/#2188.
    'lib/core/services/country_service_registry.dart': 909,
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
    // #2648 — re-grandfathered 652 → 673: GPS horizontal accuracy +
    // bearing latches (2 fields + 2 getters + 2 updateGpsFix params, all
    // null-guarded like altitude) so the OBD2 emit path stops dropping
    // them (they reached only 0.3 % of samples). Net +21; decomposition
    // is still tracked by #2187/#2188.
    'lib/features/consumption/data/obd2/live_sample_snapshot.dart': 673,
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
    // #2509 + #2513 — re-grandfathered 1360 → 1412 (merge of both): the GPS
    // start-time fallback (the `_gpsStartedAt`/`_gpsEndedAt` latch in
    // `updateGpsFix`, the `_finaliseSummary` start/end back-fill, and the
    // `gpsFixCount` getter the persist guard reads, #2509) PLUS the
    // wider-range absolute load (PID 0x43) + latest GPS altitude wired to
    // the baseline recorder so the fuzzy path can fill the climbing/loaded
    // bucket from a real road grade and/or load ramp (#2513). Pure wiring;
    // decomposition of this god-class is tracked by #2187/#2188/#2190.
    // #2524 — re-grandfathered → 1471: the in-trip reconnect now swaps the
    // controller's live service (`_service` made mutable + the new
    // `replaceService` method that points the recording loop at the
    // reconnected transport AND tears down the dead one) plus the
    // `_DroppedSessionHostAdapter.disconnectDroppedService` hook that fails
    // the dead transport's stranded `_pending` on a drop. Before this the
    // loop polled the DEAD old transport forever → silent data loss + a
    // timeout/StateError flood. Pure recovery wiring; decomposition of this
    // god-class is tracked by #2187/#2188/#2190.
    // #2515 — re-grandfathered 1471 → 1484: the live reading now carries
    // the eight precision signals the calibration path consumes
    // (oil/ambient temp + λ/baro/MAP/STFT/LTFT/pedal), each stamped from
    // an existing snapshot latest-getter in `_emit` (+a shared dartdoc
    // comment). Pure field-plumbing onto the existing TripLiveReading
    // build; decomposition of this god-class is tracked by
    // #2187/#2188/#2190.
    // #2565 — re-grandfathered 1484 → 1595: the GPS-DEGRADE fallback adds
    // the `degradedGpsOnly` ACTIVE state, the `_degradedGpsOnly` latch +
    // `gpsAlive` host wiring, a `_gpsAliveWindow` const, the `_emit`
    // degrade guard, the shared `_overlayGpsEstimate` (extracted from the
    // healthy `_emit` so both paths can't diverge), and the thin
    // delegation + constructor wiring for the new emit collaborator. The
    // bulk WAS extracted out of this file: `GpsOnlySampleBuilder`,
    // `DegradedGpsEmitter` and the `DroppedSessionManager` repo resolver
    // are all new files under the cap. The residual growth is the field
    // plumbing + the host/state-machine seam that must live on the
    // controller. Decomposition of this god-class stays tracked by
    // #2187/#2188/#2190.
    // #2648 — re-grandfathered 1595 → 1621: GPS horizontal accuracy +
    // bearing now thread through the controller's `updateGpsFix` (2
    // params + doc) → `_liveSampleSnapshot.updateGpsFix`, are stamped in
    // `_emit` + the degraded-emit call site, and exposed via two
    // `@visibleForTesting` debug getters. Net +26; the field plumbing
    // must live on the controller seam. Decomposition stays tracked by
    // #2187/#2188/#2190.
    // #2653 — re-grandfathered 1621 → 1623: the `_recorder.onSample`
    // call now threads the live `distanceSource` (+ a 2-line rationale
    // comment) so the harsh-event detector suppresses scoring on the
    // `virtual` dead-reckoning source. Net +2; the wiring must live at the
    // controller's emit site. Decomposition stays tracked by #2187/#2188.
    // #2663 — re-grandfathered 1623 → 1626: the ctor gained an optional
    // `onHarshEvent` callback (forwarded into the default TripRecorder) +
    // a rationale comment, so harsh events stream live to the driving-coach
    // voice listener (the dead-link fix). Net +3 (HarshEvent resolves via
    // the existing trip_recorder re-export, no new import); the wiring must
    // live where the controller builds its recorder. Decomposition stays
    // tracked by #2187/#2188.
    // #2671 — re-grandfathered 1626 → 1636: the OBD2 drop-pause fix wires the
    // scheduler's new pause()/resume() through the DroppedSessionHost adapter
    // (two thin wrappers mirroring the existing stopScheduler) + a resume()
    // call on the drop→reconnect transition with a rationale comment, so a
    // flapping link no longer dispatches PIDs into a dead channel. Net +10;
    // the wiring must live at the controller's host adapter + resume site.
    // Decomposition stays tracked by #2187/#2188.
    'lib/features/consumption/data/obd2/trip_recording_controller.dart': 1636,
    // #2442 — re-grandfathered 496 → 513: the save flow now raises the
    // guided reconciliation workflow after a plein save (a 7-line
    // await-then-route call into the extracted
    // `runReconciliationWorkflowIfPending` launcher + its rationale
    // comment). The workflow + apply logic itself lives in the extracted
    // launcher/widget; only the trigger call stays on the screen.
    // Decomposition of this god-class is tracked under #2187/#2188/#2190.
    // #2689 — re-grandfathered 513 → 526: the e-receipt Phase 1 plumbing
    // adds the `_scannedPricePerLiter` state field (+ dartdoc), its
    // `setScannedPricePerLiter` wiring in `_buildScanHostState`, and the
    // `scannedPricePerLiter:` arg on the saved `FillUp` (+ rationale) so the
    // exact receipt-scanned unit price is persisted instead of discarded.
    // Pure field plumbing; decomposition stays tracked under #2187/#2188/#2190.
    'lib/features/consumption/presentation/screens/add_fill_up_screen.dart':
        526,
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
    // #2548 — re-grandfathered 1088 → 1105: `_buildRecording` now renders the
    // inline `TripSaveProgress` card during the transient `saving` phase (the
    // stop-side bookend to the connecting view) plus a saving AppBar-title
    // variant — staged save feedback. Pure UI wiring; decomposition still
    // tracked under #2187/#2188/#2190.
    // #2569 — re-grandfathered 1105 → 1113: a one-line `ref.watch` of the
    // voice-announcement listener in `build` (keeps the keepAlive listener
    // mounted while the screen is up) plus its import + an explaining
    // comment. Pure wiring; decomposition still tracked under #2187/#2188.
    // #2663 — re-grandfathered 1113 → 1123: a one-line `ref.watch` of the
    // NEW driving-coach voice listener in `build` (the missing
    // event→coach→speak wire — keeps the keepAlive listener mounted while
    // the screen is up) plus its import + an explaining comment. Pure
    // wiring; decomposition still tracked under #2187/#2188.
    'lib/features/consumption/presentation/screens/trip_recording_screen.dart':
        1123,
    'lib/features/consumption/presentation/widgets/broken_map_widgets.dart':
        439,
    'lib/features/consumption/presentation/widgets/obd2_adapter_picker.dart':
        439,
    // #2624 — shrank 463 → 450: dropped the post-frame `fitCamera` block
    // (+ its dart:async / error_logger imports) in favour of
    // `MapOptions.initialCameraFit`, fixing the grey-tile cold-start race.
    'lib/features/consumption/presentation/widgets/trip_path_map_card.dart':
        450,
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
    // #2548 — re-grandfathered 1217 → 1235: the `setSaveStage` notifier method
    // + its `_RecordingPipelineHostAdapter` override + the TripSaveStage
    // re-export — the staged save-progress wiring mirroring `setConnectStage`.
    // Decomposition still tracked by #2187/#2188/#2190.
    // #2565 — re-grandfathered 1235 → 1240: the WAL-snapshot phase-string
    // switch gained the `degradedGpsOnly` case (mapped to 'recording' — a
    // degraded trip is still actively recording) + its rationale comment.
    // Pure mapping; decomposition still tracked by #2187/#2188/#2190.
    'lib/features/consumption/providers/trip_recording_provider.dart': 1240,
    'lib/features/feature_management/data/legacy_toggle_migrator.dart': 647,
    // #2510 — re-grandfathered 544 → 562: the nearby-search map no longer
    // hides results behind count-clusters. Adds the `rankForEmphasis`
    // helper + two `@visibleForTesting` constants (emphasisCount,
    // clusterThreshold) and the de-clustering branch (a bounded set renders
    // a plain MarkerLayer with the top-ranked stations emphasized; only a
    // huge/zoomed-far set falls back to clustering). Net +18 is the helper,
    // the constants and their dartdoc. Decomposition tracked by #2187/#2188.
    // #2532 — re-grandfathered 562 → 574: the optional `onStationTap` field
    // (so a wide-screen marker tap selects into the side panel instead of
    // pushing the route) + its dartdoc, its constructor param, its pass-down
    // in `_recomputeMarkers`, and the `didUpdateWidget` identity guard that
    // rebuilds markers on a changed callback. Decomposition tracked by
    // #2187/#2188.
    // #2547 — tightened 574 → 562: the #2547 revert removed that
    // `onStationTap` field (the map now takes the full horizontal width on
    // wide/landscape — no side panel), so the marker tap is back to its
    // pre-#2532 `/station/:id` push and the field + its plumbing are gone.
    // #2631 — re-grandfathered 562 → 604: the optional cross-border
    // `fuelResolver` field + its dartdoc, its constructor param + the
    // `didUpdateWidget` identity guard, the resolver thread-through in
    // `orderedByPriceForPainting` + `_recomputeMarkers`, and the small
    // `_resolvedRange` helper that colours cross-border markers by each
    // station's own country fuel. Lets a Spanish station show its E10 price
    // instead of '--' on an E85 route. Decomposition tracked by #2187/#2188.
    'lib/features/map/presentation/widgets/station_map_layers.dart': 604,
    // #2681 — feature_management_section.dart graduated: the #2681 ordered-
    // category reorg decomposed the 718-line god-class into the
    // widgets/feature_management/ folder (conso_feature_card.dart,
    // feature_group_card.dart, feature_localization.dart,
    // feature_grouping.dart, feature_section_header.dart) so the section
    // dropped to ~168 content lines (below the cap). Removed from the
    // snapshot per the shrink ratchet; every extracted file is new and
    // under 400.
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
