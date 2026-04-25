import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#923 final): feature `presentation/
/// screens/` files MUST NOT reach for `textTheme.titleMedium`,
/// `textTheme.titleLarge`, or `textTheme.headlineSmall` directly when
/// rendering a section heading. Use `SectionHeader`
/// (`lib/core/widgets/section_header.dart`) instead.
///
/// The design-system epic (#923) collapsed 60+ inline title-theme
/// `copyWith(...)` callsites onto a single canonical heading widget so
/// that font weight, padding, semantic role, and dark-mode tinting stay
/// consistent. This scan locks in the migration: once a screen ships a
/// new inline `textTheme.titleX` style, the test trips and the author
/// has to use `SectionHeader` (or, for the rare value-display case,
/// document the reason in the allowlist below).
///
/// Scope: only `lib/features/**/presentation/screens/*.dart`. Widget
/// files (`presentation/widgets/`) hold the inner-card / value-display
/// styles that are NOT section headers, so the rule does not extend
/// to them — they get reviewed individually.
///
/// The allowlist below is the closed set of pre-existing screen-level
/// title-theme uses that survived #923's migration. Each entry cites
/// the line, the style, and the reason it isn't a section header (or
/// is a deferred case). New entries must follow the same comment
/// format — adding an unexplained allowlist entry defeats the lint.
void main() {
  test(
    'no inline `textTheme.titleMedium / titleLarge / headlineSmall` in '
    'lib/features/**/presentation/screens/*.dart (#923 final)',
    () {
      // Path : rationale-comment map. The map preserves the
      // grep-derived list of pre-existing legitimate uses; everything
      // not in the map is either a section header (use SectionHeader)
      // or deferred (file-level entry with a #923-deferred citation).
      // Each entry is a pre-existing legitimate use surfaced when this
      // lint first ran against master. The grouped block below is the
      // running rationale list — keep adjacent to the Set so future
      // additions stay justified.
      //
      // - carbon_dashboard_screen.dart  : `titleLarge` for big total
      //   cost / total CO2 numbers on two SectionCards. Numeric
      //   value emphasis, not a heading.
      // - ev/ev_station_detail_screen.dart : `titleMedium` "Connectors"
      //   label. Migration to SectionHeader tracked as #923-followup.
      // - alerts_screen.dart : `titleMedium` "Radius alerts (n)"
      //   header with a trailing IconButton. Migration to
      //   SectionHeader.trailing tracked as #923-followup.
      // - price_history_screen.dart : `titleMedium` fuel-type display
      //   inside a card. Value display, not a heading.
      // - add_charging_log_screen.dart : `headlineSmall` centered
      //   empty-state ("Add a vehicle first"). Empty states use a
      //   larger style than SectionHeader.
      // - trip_detail_screen.dart : `titleMedium` "Summary" inside a
      //   SectionCard with its own padding. Migration tracked as
      //   #923-followup.
      // - trip_recording_screen.dart : `titleLarge` for big metric
      //   values (distance, duration). Value display, not a heading.
      // - add_fill_up_screen.dart : `headlineSmall` empty state +
      //   `titleMedium` station-name confirmation row. Both
      //   value/empty displays, not section headers.
      // - search/ev_station_detail_screen.dart : `titleMedium`
      //   "Your rating" tile label inside a Card. Migration tracked
      //   separately.
      // - station_detail_screen.dart : deferred — needs PageScaffold
      //   `title: Widget` variant (#923-deferred). Two uses:
      //   `titleLarge` in Hero flight + `titleMedium` "Price History"
      //   section header.
      const allowlist = <String>{
        'lib/features/carbon/presentation/screens/carbon_dashboard_screen.dart',
        'lib/features/ev/presentation/screens/ev_station_detail_screen.dart',
        'lib/features/alerts/presentation/screens/alerts_screen.dart',
        'lib/features/price_history/presentation/screens/price_history_screen.dart',
        'lib/features/consumption/presentation/screens/add_charging_log_screen.dart',
        'lib/features/consumption/presentation/screens/trip_detail_screen.dart',
        'lib/features/consumption/presentation/screens/trip_recording_screen.dart',
        'lib/features/consumption/presentation/screens/add_fill_up_screen.dart',
        'lib/features/search/presentation/screens/ev_station_detail_screen.dart',
        'lib/features/station_detail/presentation/screens/station_detail_screen.dart',
      };

      final re = RegExp(
        r'textTheme\.(titleMedium|titleLarge|headlineSmall)\b',
      );

      final offenders = <String>[];
      for (final entity
          in Directory('lib/features').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        final posix = entity.path.replaceAll('\\', '/');
        if (!posix.contains('/presentation/screens/')) continue;
        if (allowlist.any(posix.endsWith)) continue;

        final src = entity.readAsStringSync();
        for (final m in re.allMatches(src)) {
          final line = src.substring(0, m.start).split('\n').length;
          offenders.add('$posix:$line  ${m.group(0)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Inline textTheme.title* / headlineSmall found. Use '
            'SectionHeader (lib/core/widgets/section_header.dart). '
            'See #923. Offending sites:\n${offenders.join("\n")}',
      );
    },
  );
}
