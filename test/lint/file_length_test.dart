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
    // #3743 (epic item 5) — the config moved into its owning feature;
    // the key follows the file, snapshot unchanged.
    'lib/features/trips/data/trips_sync.dart': (
      lines: 433,
      bumps: 1,
      decompositionIssue: null,
    ),
    'lib/features/trips/presentation/widgets/broken_map_widgets.dart': (
      lines: 439,
      bumps: 0,
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
}
