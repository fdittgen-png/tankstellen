// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_graph.dart';

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
/// explaining why — and the entry's `bumps` counter incremented.
///
/// ### Anti-re-grandfathering ratchet (#3141)
/// Repeated "justified +N" re-grandfatherings are how god files grow
/// forever (app_initializer took 9 bumps in one iteration; ~40 upward
/// bumps are recorded in this file's own comments). Each snapshot entry
/// therefore carries a `bumps` counter — the number of UPWARD snapshot
/// changes since the entry was created (shrinks don't count). Once a
/// file accumulates **3 or more bumps**, its entry MUST reference an
/// **open** GitHub decomposition issue via `decompositionIssue`, or the
/// test fails. The issue must stay open until the file graduates below
/// the cap; closing it without decomposing means the next bump fails
/// review honesty, not just CI. Existing entries were seeded at their
/// historical bump counts (parsed from the re-grandfather comments) and
/// linked to the open decomposition issues of epic #3136.
///
/// Generated files are not scanned: `.g.dart` / `.freezed.dart` and the
/// `lib/l10n/app_localizations*.dart` outputs of `flutter gen-l10n`
/// (each thousands of lines, none handwritten).
///
/// ### Second axis: the library, not the file (#4033 / epic #4032)
/// A `part` file satisfies the per-file cap without making the *unit*
/// smaller — it shares the declaring library's private scope, so the
/// code moved but the coupling did not. Measured per library (declaring
/// file + its hand-written parts), 36 libraries exceed the same 400-line
/// norm while every one of their files passes the per-file gate; the
/// worst spans 2 594 lines across 11 files. (#4037 has since taken three
/// of the 36 out — two of them entirely.)
///
/// [_libraryBaseline] therefore pins each of those libraries at its
/// measured total, and — following `opt_out_ratchet_test.dart` — the
/// ratchet is **exact in both directions**:
///
///   1. a total above its baseline fails (the library grew);
///   2. a total *below* its baseline ALSO fails, so a win is locked into
///      the baseline in the same PR instead of being silently re-spent.
///
/// A library that graduates below the cap leaves the map entirely, and a
/// library over the cap with no entry fails like any new offender. The
/// per-file 400-line gate above is unchanged — this adds an axis, it
/// does not relax the existing one.

/// One grandfathered file's ratchet state (#1680 / #2351 / #3141):
/// the snapshot [lines] count, the upward re-grandfathering [bumps]
/// counter, and the open [decompositionIssue] number (mandatory once
/// `bumps >= 3`).
typedef _GrandfatherEntry = ({int lines, int bumps, int? decompositionIssue});

void main() {
  const lineLimit = 400;

  // A file may be re-grandfathered upward at most this many times before
  // an OPEN decomposition issue must be referenced in its entry (#3141).
  const reGrandfatherBumpLimit = 3;

  // Snapshot map: grandfathered path → ratchet state.
  //  - lines: line count at (re-)grandfathering time (SPDX header
  //    excluded, same as the runtime count). The growth ratchet fails
  //    CI if current > lines.
  //  - bumps: UPWARD snapshot changes since the entry was created.
  //    When you raise `lines` you MUST increment `bumps` by 1 in the
  //    same edit (a shrink or a removal never increments).
  //  - decompositionIssue: the OPEN GitHub issue tracking this file's
  //    decomposition — MANDATORY once bumps >= 3 (#3141).
  // Update an entry only for a legitimate re-grandfathering (same PR,
  // with a comment). NEVER add new entries — use decomposition instead.
  const grandfatheredSnapshot = <String, _GrandfatherEntry>{
    // #3078 — grandfathered at 414 (was 400, right at the cap on master). The
    // deletion-tombstone fix threads a tombstoned-id set through `merge` and
    // `mergeRows` (fetch + dual-side filter so a delete on another device
    // doesn't resurrect) plus the `deleteSummary` tombstone write — a real
    // fix, not boilerplate. Decomposition of this near-cap file is its own
    // future task.
    // #3613 — re-grandfathered 414 → 433: `merge` gained the optional
    // `loadFull` hydration seam (doc + per-entry re-hydrate of the
    // local-only details-heal upload) so the launch pull can feed it
    // summary-only decoded entries without losing the trip_details heal.
    // #4056 — trips_sync.dart entry REMOVED: the pure row/reconcile half
    // moved to trips_sync_rows.dart and the file is under the cap now.
    // #3996 — +2: the diagnostics card opens on a plain-language line
    // explaining what the reading means, instead of on the posterior.
    'lib/features/trips/presentation/widgets/broken_map_widgets.dart': (
      lines: 441,
      bumps: 1,
      decompositionIssue: null,
    ),
    // #2624 — shrank 463 → 450: dropped the post-frame `fitCamera` block
    // (+ its dart:async / error_logger imports) in favour of
    // `MapOptions.initialCameraFit`, fixing the grey-tile cold-start race.
    // #3316 — shrank 450 → 412: the finite-point filter + zero-span bounds
    // padding moved to the pure trip_path_geometry.dart helper.
    'lib/features/trips/presentation/widgets/trip_path_map_card.dart': (
      lines: 412,
      bumps: 0,
      decompositionIssue: null,
    ),
    'lib/features/feature_management/data/legacy_toggle_migrator.dart': (
      lines: 647,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #3233 — station_map_layers.dart graduated (700 → 354, below the cap):
    // the pure geometry/marker-ranking statics → station_map_geometry.dart
    // (#3289), the marker-model pipeline → station_marker_model_builder.dart +
    // the zoom controls → map_zoom_controls.dart (#3295), and the FlutterMap
    // layer tree → station_map_body.dart (the presentational StationMapBody,
    // this PR). The widget now holds only the memoised marker model + the
    // camera-fit lifecycle. Removed from the snapshot per the shrink ratchet;
    // every extracted file is new and under 400.
    // #2510 — re-grandfathered 544 → 562: the nearby-search map no longer
    // #2681 — feature_management_section.dart graduated: the #2681 ordered-
    // category reorg decomposed the 718-line god-class into the
    // widgets/feature_management/ folder (conso_feature_card.dart,
    // feature_group_card.dart, feature_localization.dart,
    // feature_grouping.dart, feature_section_header.dart) so the section
    // dropped to ~168 content lines (below the cap). Removed from the
    // snapshot per the shrink ratchet; every extracted file is new and
    // under 400.
    // #3234 — vehicle_profile.dart decomposed (491 → 377): the powertrain /
    // calibration-mode / connector enums and their enum-only JSON converters
    // moved into vehicle_enums.dart (132, re-exported for backward compat), so
    // the freezed entity file holds only the model + ChargingPreferences and
    // drops below the cap. Removed from the snapshot per the shrink ratchet;
    // vehicle_enums.dart is new and under 400. The sibling edit_vehicle_screen
    // decomposition stays tracked by the (still-open) #3234.
    // #3234 — edit_vehicle_screen.dart graduated (879 → 308, below the cap):
    // the imperative form actions + the mutable form state moved into the
    // `_VehicleEditActions` part mixin (edit_vehicle_screen_actions.dart, 358),
    // and the form body (the PageScaffold + section-card stack) into the
    // presentational VehicleEditForm (vehicle_edit_form.dart, 281). The screen
    // now holds only the load/dispose lifecycle, the prepop `ref.listen`, the
    // discard `PopScope`, and `build`. Removed from the snapshot per the shrink
    // ratchet; both new files are under 400. Closes the #3234 decomposition.
    'lib/features/vehicle/presentation/widgets/auto_record_section.dart': (
      lines: 830,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #2837 — re-grandfathered 465 → 523: on a direct-fuel-rate (PID 5E)
    // car the η_v field + its "0 samples" learner readout + Reset learner
    // are replaced by an explanatory _DirectFuelRateNote, since η_v never
    // touches the direct branch. The note widget + the conditional
    // rendering account for the growth. Decomposition tracked under
    // #2187/#2188.
    'lib/features/vehicle/presentation/widgets/calibration_section.dart': (
      lines: 523,
      bumps: 1,
      decompositionIssue: null,
    ),
    'lib/features/widget/data/home_widget_service.dart': (
      lines: 696,
      bumps: 0,
      decompositionIssue: null,
    ),
  };

  // #4346 — the scope filter and the SPDX-discounted line count live in
  // tool/architecture_graph.dart, shared with the architecture inventory
  // so both measure the same libraries the same way.
  bool isScanned(String path) => isHandwrittenDart(path);

  int effectiveLinesOf(File file) => effectiveLines(file.readAsLinesSync());

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
      final lines = effectiveLinesOf(entity);

      if (grandfatheredSnapshot.containsKey(path)) {
        if (lines > lineLimit) {
          stillOver.add(path);
          // Growth ratchet (#2351): fail if current > snapshot.
          final snapshot = grandfatheredSnapshot[path]!.lines;
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
          'a comment explaining why more lines are justified — and '
          'increment the entry\'s `bumps` counter by 1 in the same edit '
          '(at >= $reGrandfatherBumpLimit bumps an open decomposition '
          'issue must be referenced, #3141).\n'
          '${grownFiles.join("\n")}',
    );

    // Shrink ratchet (#1680): a grandfathered file decomposed below the
    // limit must be removed from the snapshot map so the debt baseline
    // stays honest.
    final staleBaseline = grandfatheredSnapshot.keys.toSet().difference(
      stillOver,
    );
    expect(
      staleBaseline,
      isEmpty,
      reason:
          'These files are no longer over $lineLimit lines — remove '
          'them from the `grandfatheredSnapshot` map in this test so '
          'the debt baseline stays honest:\n${staleBaseline.join("\n")}',
    );
  });

  test('anti-re-grandfathering ratchet (#3141): '
      '>= $reGrandfatherBumpLimit snapshot bumps require an open '
      'decomposition issue', () {
    // Repeatedly re-grandfathering a file upward is how god files grow
    // forever via "justified +N" bumps. Once a file has accumulated
    // [reGrandfatherBumpLimit] bumps, its entry must reference the OPEN
    // GitHub issue that tracks decomposing it (and that issue must stay
    // open until the file graduates below the cap).
    final missingIssue = <String>[];
    final invalidIssue = <String>[];
    for (final MapEntry(key: path, value: snap)
        in grandfatheredSnapshot.entries) {
      final issue = snap.decompositionIssue;
      if (issue != null && issue <= 0) {
        invalidIssue.add('$path  (decompositionIssue: $issue)');
      }
      if (snap.bumps >= reGrandfatherBumpLimit && issue == null) {
        missingIssue.add('$path  (${snap.bumps} bumps, no issue)');
      }
    }

    expect(
      invalidIssue,
      isEmpty,
      reason:
          'decompositionIssue must be a real GitHub issue number:\n'
          '${invalidIssue.join("\n")}',
    );

    expect(
      missingIssue,
      isEmpty,
      reason:
          'These grandfathered files have been re-grandfathered upward '
          '$reGrandfatherBumpLimit+ times without an open decomposition '
          'issue. File a decomposition issue for each file (what to '
          'extract, along which seams, done = under the '
          '$lineLimit-line cap) and record its number as '
          '`decompositionIssue:` on the snapshot entry — the bump '
          'pattern stops here (#3141):\n${missingIssue.join("\n")}',
    );
  });

  /// The libraries of every scanned lib/ file, read once and shared by
  /// the library-budget and part-mixin tests below.
  List<SharedStateLibrary>? cachedLibraries;
  List<SharedStateLibrary> scannedLibraries() =>
      cachedLibraries ??= sharedStateLibraries({
        for (final entity in Directory('lib').listSync(recursive: true))
          if (entity is File && isScanned(entity.path.replaceAll(r'\', '/')))
            entity.path.replaceAll(r'\', '/'): entity.readAsStringSync(),
      });

  // ---------------------------------------------------------------
  // Second axis (#4033): the library — declaring file + hand-written
  // parts — measured against an exact, decrease-only baseline.
  // ---------------------------------------------------------------

  // Library path (the declaring file) → pinned total line count across
  // that file and its hand-written `part` files. Measured 2026-09-10.
  //
  // NEVER raise an entry. Lower it in the same PR that shrinks the
  // library, and delete it once the library is at or under the cap.
  const libraryBaseline = <String, int>{
    // #4034 — 2 594 → 2 483: seven clusters of shared mutable state left
    // for owned collaborators (engine-data fence, voltage watch, parked
    // prompt, identity read, odometer tracker, run state, fuel
    // accumulator) and the gear-coaching metric became a pure function.
    // No private field is written from more than one file any more.
    // #4068 — 2483 → 2481: the two dead `stopped`/`started` setters left the drop-host adapter; one `finalise()` forwarder replaced them.
    // #4162 — 2481 → 2476: `currentState` is a projection of the run
    // state's one documented precedence instead of a second if-chain.
    // #4384 — 2476 → 2479: the silent-bus verdict gained its motion term,
    // so a mute ELM at road speed can no longer read as engine-off.
    // #4385 — 2479 → 2483: the owner's park is readable off the controller
    // (`linkOwnerParked`) so the degraded banner can stop saying
    // "reconnecting" over a supervisor that is not dialing.
    // #4386 — 2483 → 2488: and whether automatic recovery is exhausted.
    // #4330 — 2488 → 2501: `_finaliseSummary` stamps the consumption model
    // version, so an OBD2 trip stops persisting `cmv: null`.
    'lib/features/obd2/data/session/trip_recording_controller.dart': 2501,
    // #4035 — 1 541 → 1 517: the pure ELM AT grammar (the `ATI` command,
    // the firmware-string parse, the reset-command test) left the library.
    // #4315 — 1 517 → 1 368: the dead pull fuel-rate entry point, the
    // breadcrumb field only it read, and the ten precision / mixture read
    // primitives only it called left with the reader.
    'lib/features/obd2/data/session/obd2_service.dart': 1368,
    // #4035 — 1 479 across 7 files → 1 365 across 6: the direct-channel
    // pointer became an owned slot carrying the #3244 close-by-identity
    // rule, and the connect-trace scope + the no-scan profile fallbacks
    // became libraries of their own.
    'lib/features/obd2/data/session/obd2_connection_service.dart': 1365,
    // #4036 — 1 466 → 1 403: the last-trip identity and the pipeline
    // selection became owned collaborators, and the WAL snapshot's two
    // pure controller reads a library of their own.
    // #4162 — 1403 → 1384: the no-movement discard log joined its guard and
    // the empty WAL-seed summary became a shared constant, paying for the
    // one publish funnel every state write now walks through.
    // #4311 — 1384 → 1382: the WAL's stopped-controller guard is a pure
    // controller read in active_snapshot_from_controller.dart.
    // C1 (#4162, fixed in the #4312 commit) — 1382 → 1381: startTrip's two
    // identical needsPicker returns collapsed, paying for the new guard.
    // #4314 — 1381 → 1379: clearing the WAL row drops its paused row too
    // (a standalone helper), and the catch around a repository call that
    // already swallows its own failures went.
    // #4328 — 1379 → 1347: the history row a stop saves (and the one a
    // recovered trip saves) is built in standalone finished_trip_entry.dart,
    // beside the one-trip-one-id rule it now carries.
    // #4378 — 1347 → 1329: the recovered finalise's Riverpod reads moved
    // into standalone recovered_finalise_deps.dart, paying for the
    // pending-save keep on the failed-write path.
    'lib/features/trips/providers/trip_recording_provider.dart': 1329,
    // #4037 — 1 032 across 5 files → 756 across 3: the pin/wake-lock
    // state became an owned collaborator and the body a plain widget.
    // #4378 — 756 → 747: what a stop tells the user about persistence is
    // one decision in standalone trip_stop_snack_bar.dart, which is where
    // the failed-write case and its retry landed.
    'lib/features/trips/presentation/screens/trip_recording_screen.dart': 747,
    // #4322 — 973 → 967: the tankFuelKey rule left for the domain
    // `tankFuelKeyOf`, read from the evidence-only tank blend.
    // #4428 — 967 → 984: `add` is the one save whose device location is
    // evidence about the record being written, so it reads the detected
    // country (guarded) and hands it to the repository's currency rule.
    'lib/features/fill_ups/providers/consumption_providers.dart': 984,
    'lib/features/obd2/data/transport/flutter_blue_plus_elm_channel.dart': 948,
    // #4233 — 910 → 900: the profile-η_v rule moved to a pure domain
    // function (then shared with the pull reader); the fuzzy stage call
    // sites and their context getter took back 12 of the 22 lines.
    // #4315 — 900 → 893: the comments that mirrored the deleted pull
    // reader's chain.
    'lib/features/obd2/data/session/live_sample_snapshot.dart': 893,
    'lib/features/profile/presentation/widgets/profile_edit_sheet.dart': 855,
    'lib/features/obd2/data/session/obd2_self_test_driver.dart': 828,
    // #4428 — 824 → 836: the form carries the ISO code a scanned
    // receipt printed through to the saved record, so a CHF fill is
    // not stored under the profile's currency.
    'lib/features/fill_ups/presentation/screens/add_fill_up_screen.dart': 836,
    'lib/features/fill_ups/presentation/widgets/fuel_type_efficiency_card.dart': 810,
    // #4317 — 746 → 731: the pre-launch service batch and its error shield
    // left; the runtime services are a library of their own.
    // #4319 — 731 → 677: the launch graph and the widget probe became
    // libraries of their own (launch_critical_path, widget_launch_probe).
    'lib/app/app_initializer.dart': 677,
    'lib/features/obd2/data/obd2_comm_diagnostics.dart': 726,
    'lib/features/vehicle/presentation/screens/edit_vehicle_screen.dart': 714,
    'lib/features/obd2/data/protocol/adapter_registry.dart': 706,
    'lib/features/obd2/data/obd2_connect_trace_log.dart': 627,
    // #4384 — 604 → 610: the `asleep` park in `_dropTail` gained its
    // motion term (a mute bus on a moving car is a broken link, not a
    // parked car) plus the comment that says why.
    'lib/features/obd2/data/session/obd2_link_supervisor.dart': 610,
    'lib/features/obd2/presentation/widgets/obd2_adapter_picker.dart': 601,
    // #4068 — 586 → 581: both grace finalisers collapse their flag writes into `_host.finalise()`.
    // #4385 — 579 → 611: the owner's park / stand-down reaches the session
    // journal (#4195 invariant 8) and the banner, through the reattach
    // source's existing level read — no new subscription, no new authority.
    // #4386 — 611 → 637: the #4196 unverified streak's 4x cap emits an
    // honest terminal condition instead of looping silently for the drive.
    'lib/features/obd2/data/session/dropped_session_manager.dart': 637,
    'lib/features/driving_score/data/driving_score_calculator.dart': 556,
    'lib/features/profile/presentation/screens/developer_tools/pump_ocr_tester_screen.dart': 525,
    // #4073 — 523 → 502: the private percentile copy moved to core/utils/stats.dart.
    'lib/features/trips/domain/services/gear_inference.dart': 502,
    'lib/features/receipts_ocr/presentation/widgets/ocr_trace_steps_panel.dart': 509,
    'lib/features/obd2/data/session/auto_trip_coordinator.dart': 496,
    'lib/features/search/presentation/screens/search_criteria_screen.dart': 473,
    'lib/features/trips/presentation/widgets/vehicle_baseline_section.dart': 454,
    'lib/features/trips/data/trip_history_entry.dart': 450,
    'lib/features/obd2/data/transport/bluetooth_obd2_transport.dart': 448,
    'lib/features/search/presentation/widgets/search_results_list.dart': 440,
    'lib/features/fill_ups/domain/services/monthly_insights_aggregator.dart': 415,
    // #4338 — 413 → 412: markRelinkRequired now marks the relink owner
    // and rebuilds instead of copying the whole config by hand.
    'lib/core/sync/sync_provider.dart': 412,
  };

  test('no library in lib/ (declaring file + its hand-written parts) '
      'exceeds $lineLimit lines or its pinned baseline (#4033)', () {
    // #4346 — root/part aggregation is tool/architecture_graph.dart's
    // sharedStateLibraries: a library is a declaring file with hand-written
    // parts (generated parts excluded), never itself someone's part, and
    // its total is the effective lines of the root plus the parts that
    // exist. The exact baselines below pin that it measures what the
    // in-test aggregation measured before.
    final totals = <String, int>{};
    final composition = <String, List<String>>{};
    for (final library in scannedLibraries()) {
      totals[library.root] = library.lines;
      composition[library.root] = library.parts;
    }

    String describe(String path) =>
        '$path  (${totals[path]} lines across '
        '${composition[path]!.length + 1} files: '
        '${composition[path]!.join(", ")})';

    // 1. A library over the cap with no baseline entry is a new offender.
    final unbaselined = <String>[
      for (final MapEntry(key: path, value: total) in totals.entries)
        if (total > lineLimit && !libraryBaseline.containsKey(path))
          describe(path),
    ];
    expect(
      unbaselined,
      isEmpty,
      reason:
          'Library/-ies over $lineLimit lines with no baseline entry. A '
          '`part` file does not make the unit smaller — it shares the '
          'declaring library\'s private scope. Extract the code into a '
          'collaborator with its own private state instead of a part, or '
          'shrink the library below the cap. Offenders:\n'
          '${unbaselined.join("\n")}',
    );

    // 2. Growth ratchet: a pinned library must not exceed its baseline.
    final grown = <String>[];
    for (final MapEntry(key: path, value: pinned) in libraryBaseline.entries) {
      final total = totals[path];
      if (total == null || total <= pinned) continue;
      grown.add(
        '${describe(path)}, baseline $pinned, grew by ${total - pinned}',
      );
    }
    expect(
      grown,
      isEmpty,
      reason:
          'Library/-ies have GROWN beyond their pinned baseline. This '
          'ratchet only ever goes down: move the new code into a '
          'collaborator of its own rather than into another part.\n'
          '${grown.join("\n")}',
    );

    // 3. Undershoot ratchet: a win must be locked into the baseline in
    //    the same PR, or it can be silently re-spent later.
    final stale = <String>[];
    for (final MapEntry(key: path, value: pinned) in libraryBaseline.entries) {
      final total = totals[path];
      if (total == null) {
        stale.add(
          '$path  (no longer a multi-file library — remove the entry, '
          'baseline $pinned)',
        );
      } else if (total <= lineLimit) {
        stale.add(
          '${describe(path)} — now at or under the $lineLimit-line cap; '
          'REMOVE the entry (baseline $pinned)',
        );
      } else if (total < pinned) {
        stale.add(
          '${describe(path)} — lower the baseline to ${totals[path]} '
          '(was $pinned)',
        );
      }
    }
    expect(
      stale,
      isEmpty,
      reason:
          'Stale library baseline(s): these libraries are smaller than '
          'the map claims. Lower (or delete) the entry in the SAME PR so '
          'the win is locked in and cannot creep back:\n'
          '${stale.join("\n")}',
    );
  });

  // ---------------------------------------------------------------
  // #4346 — shared private state, not lines. A mixin declared in a part
  // file reaches the whole library's private scope: it is a slice of one
  // owner's state, not a collaborator. Moving code between parts leaves
  // this count unchanged; extracting a collaborator with its own private
  // state lowers it — which is the reduction that matters.
  // ---------------------------------------------------------------

  /// Declaring library -> number of mixins declared in its hand-written
  /// part files (`mixin Name` at the start of a line, comments ignored),
  /// as tool/architecture_graph.dart's sharedStateLibraries counts them.
  /// Libraries without part mixins have no entry. Measured with that
  /// scanner by pinning this map empty and copying back what the test
  /// reported. Exact in both directions like [libraryBaseline]: NEVER
  /// raise or add an entry; lower or delete it in the PR that extracts a
  /// collaborator.
  const partMixinBaseline = <String, int>{
    'lib/core/services/station_service_chain.dart': 1,
    'lib/features/fill_ups/presentation/screens/add_fill_up_screen.dart': 3,
    'lib/features/fill_ups/providers/consumption_providers.dart': 4,
    'lib/features/obd2/data/session/live_sample_snapshot.dart': 3,
    'lib/features/obd2/data/session/obd2_service.dart': 4,
    'lib/features/obd2/data/session/trip_recording_controller.dart': 9,
    'lib/features/obd2/presentation/widgets/obd2_adapter_picker.dart': 2,
    'lib/features/search/presentation/screens/search_criteria_screen.dart': 1,
    'lib/features/trips/presentation/screens/trip_recording_screen.dart': 3,
    'lib/features/trips/providers/trip_recording_provider.dart': 4,
    'lib/features/vehicle/presentation/screens/edit_vehicle_screen.dart': 3,
  };

  test('mixins sharing a library\'s private scope match the baseline, and '
      'each has a named state owner (#4346)', () {
    final libraries = scannedLibraries();
    final actual = {
      for (final library in libraries)
        if (library.partMixins.isNotEmpty)
          library.root: library.partMixins.length,
    };
    final drift = <String>[];
    for (final root in {...actual.keys, ...partMixinBaseline.keys}) {
      final now = actual[root] ?? 0;
      final pinned = partMixinBaseline[root] ?? 0;
      if (now > pinned) {
        drift.add('$root: $now part mixins (baseline $pinned) — extract a '
            'collaborator with its own state instead');
      } else if (now < pinned) {
        drift.add('$root: $now part mixins (baseline $pinned) — stale, '
            'lower the entry');
      }
    }
    drift.sort();
    final literal = (actual.keys.toList()..sort())
        .map((k) => "    '$k': ${actual[k]},")
        .join('\n');
    expect(
      drift,
      isEmpty,
      reason: 'Part-file mixins drifted from partMixinBaseline (#4346).\n'
          '${drift.join('\n')}\n\nUp-to-date baseline literal:\n$literal',
    );

    final ownerless = [
      for (final library in libraries)
        if (library.partMixins.isNotEmpty && library.owners.isEmpty)
          '${library.root} (${library.partMixins.join(', ')})',
    ];
    expect(
      ownerless,
      isEmpty,
      reason: 'These libraries declare part mixins that no class in the '
          'library mixes in, so their shared state has no explicit owner '
          '(#4346):\n${ownerless.join('\n')}',
    );
  });

}
