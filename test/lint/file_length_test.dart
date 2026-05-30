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
    'lib/app/app_initializer.dart': 934,
    'lib/core/background/background_service.dart': 782,
    'lib/core/country/country_config.dart': 723,
    // #2373 — re-grandfathered 868 → 887: one required `sourceUrl` field
    // added to every per-country FuelServicePolicy row (19 data lines) so
    // the country-service header can link the upstream data source.
    'lib/core/services/country_service_registry.dart': 887,
    'lib/features/consumption/data/obd2/adapter_registry.dart': 500,
    'lib/features/consumption/data/obd2/auto_trip_coordinator.dart': 726,
    'lib/features/consumption/data/obd2/elm327_parsers.dart': 457,
    'lib/features/consumption/data/obd2/live_sample_snapshot.dart': 471,
    // #2379 — re-grandfathered 1457 → 1468: threaded the
    // `logFailureAsError` flag through `connect()` (param + doc + the
    // guarded `if` around the now-conditional connect-failed trace) so a
    // recoverable connect attempt stops flooding the error log. Net +11;
    // decomposition is tracked separately by #2187/#2188.
    'lib/features/consumption/data/obd2/obd2_service.dart': 1468,
    'lib/features/consumption/data/obd2/trip_recording_controller.dart': 1235,
    'lib/features/consumption/presentation/screens/add_fill_up_screen.dart':
        496,
    // #2380 — +5: closest-station radar card at the top of the
    // recording column + a SingleChildScrollView wrap so the longer
    // column (radar + 5 metric cards + coaching card) scrolls instead
    // of overflowing on short viewports. Decomposition tracked under
    // the existing god-class follow-ups (#2187/#2188/#2190).
    'lib/features/consumption/presentation/screens/trip_recording_screen.dart':
        1069,
    'lib/features/consumption/presentation/widgets/broken_map_widgets.dart':
        439,
    'lib/features/consumption/presentation/widgets/obd2_adapter_picker.dart':
        439,
    'lib/features/consumption/presentation/widgets/trip_path_map_card.dart':
        463,
    'lib/features/consumption/providers/consumption_providers.dart': 879,
    'lib/features/consumption/providers/trip_recording_provider.dart': 1125,
    'lib/features/feature_management/data/legacy_toggle_migrator.dart': 647,
    'lib/features/map/presentation/widgets/station_map_layers.dart': 544,
    'lib/features/profile/presentation/widgets/feature_management_section.dart':
        706,
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
