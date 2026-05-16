import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#1680): no *new* handwritten Dart file in `lib/`
/// may exceed [_lineLimit] lines.
///
/// The ~400-line norm keeps files reviewable and decomposable. This
/// guard enforces it for new files and **ratchets down** the existing
/// debt: the [_grandfathered] set lists the files that were already
/// over the limit when the guard was introduced. That set may only
/// **shrink** — when an oversized file is decomposed below the limit
/// it must be removed from the set; it can never be added to.
///
/// Generated files are not scanned: `.g.dart` / `.freezed.dart` and the
/// `lib/l10n/app_localizations*.dart` outputs of `flutter gen-l10n`
/// (each thousands of lines, none handwritten).
void main() {
  const lineLimit = 400;

  // Files already over the limit when the guard landed (#1680). Debt —
  // decompose these incrementally and delete each from this set as it
  // drops below the limit. NEVER add an entry here.
  const grandfathered = <String>{
    'lib/app/app_initializer.dart',
    'lib/core/background/background_service.dart',
    'lib/core/country/country_config.dart',
    'lib/core/services/country_service_registry.dart',
    'lib/features/consumption/data/obd2/adapter_registry.dart',
    'lib/features/consumption/data/obd2/auto_trip_coordinator.dart',
    'lib/features/consumption/data/obd2/elm327_parsers.dart',
    'lib/features/consumption/data/obd2/live_sample_snapshot.dart',
    'lib/features/consumption/data/obd2/obd2_service.dart',
    'lib/features/consumption/data/obd2/trip_recording_controller.dart',
    'lib/features/consumption/presentation/screens/add_fill_up_screen.dart',
    'lib/features/consumption/presentation/screens/trip_recording_screen.dart',
    'lib/features/consumption/presentation/widgets/broken_map_widgets.dart',
    'lib/features/consumption/presentation/widgets/obd2_adapter_picker.dart',
    'lib/features/consumption/presentation/widgets/trip_path_map_card.dart',
    'lib/features/consumption/providers/consumption_providers.dart',
    'lib/features/consumption/providers/trip_recording_provider.dart',
    'lib/features/feature_management/data/legacy_toggle_migrator.dart',
    'lib/features/map/presentation/widgets/station_map_layers.dart',
    'lib/features/profile/presentation/widgets/feature_management_section.dart',
    'lib/features/search/presentation/widgets/refuel_option_card.dart',
    'lib/features/vehicle/domain/entities/vehicle_profile.dart',
    'lib/features/vehicle/presentation/screens/edit_vehicle_screen.dart',
    'lib/features/vehicle/presentation/widgets/auto_record_section.dart',
    'lib/features/vehicle/presentation/widgets/calibration_section.dart',
    'lib/features/widget/data/home_widget_service.dart',
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

  test('no new Dart file in lib/ exceeds $lineLimit lines (#1680)', () {
    final offenders = <String>[];
    final stillOver = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!isScanned(path)) continue;
      final lines = entity.readAsLinesSync().length;
      if (lines <= lineLimit) continue;
      if (grandfathered.contains(path)) {
        stillOver.add(path);
      } else {
        offenders.add('$path  ($lines lines)');
      }
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

    // Ratchet: a grandfathered file decomposed below the limit must be
    // removed from `grandfathered` so the debt set only ever shrinks.
    final staleBaseline = grandfathered.difference(stillOver);
    expect(
      staleBaseline,
      isEmpty,
      reason:
          'These files are no longer over $lineLimit lines — remove '
          'them from the `grandfathered` set in this test so the debt '
          'baseline stays honest:\n${staleBaseline.join("\n")}',
    );
  });
}
