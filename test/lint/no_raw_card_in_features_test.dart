import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#923 final): feature `presentation/
/// screens/` files MUST use `SectionCard`
/// (`lib/core/widgets/section_card.dart`) instead of the bare Material
/// `Card(...)` constructor.
///
/// The design-system epic (#923) phases 3a–3t replaced inline `Card(...)`
/// calls in feature screens with `SectionCard`, which gives consistent
/// elevation, padding, and dark-mode tinting. Reaching for the raw
/// `Card` constructor in `lib/features/**/presentation/screens/` trips
/// this scan, sending the author back to `SectionCard`.
///
/// Scope is intentionally narrowed to `presentation/screens/`. Reusable
/// card-widget primitives in `presentation/widgets/` (the dozens of
/// files named `*_card.dart`) ARE cards by contract — wrapping them in
/// SectionCard would be redundant or wrong. Those primitives stay on
/// raw `Card` because they implement the visual card themselves; the
/// rule applies to consumers (the screens), not the primitives.
///
/// Regex: `(?<![A-Za-z0-9_])Card\s*\(` — token-boundary before `Card`
/// so subclass calls (`StationCard`, `_StatCard`, `SectionCard`,
/// `ChargingCard`, …) are not matched. Adjacent identifier characters
/// disqualify a match.
///
/// The allowlist below pins the closed set of pre-existing screen-level
/// `Card(...)` uses that survived #923's migration. Each entry cites
/// the file and reason. Adding a new file requires the same
/// justification — adding an unexplained allowlist entry defeats the
/// lint.
void main() {
  test(
    'no raw `Card(...)` in lib/features/**/presentation/screens/*.dart '
    '(#923 final)',
    () {
      // Pre-existing legitimate raw `Card` uses in feature screens. All
      // are followups tracked under #923-followup; allowlisting locks
      // in the post-3a–3t baseline so the rest of the codebase stays
      // enforced.
      //
      // - gdpr_consent_screen.dart   : consent-step explanatory card.
      // - consumption_screen.dart    : two charging-charts cards.
      // - trip_detail_screen.dart    : trip-summary card.
      // - trip_recording_screen.dart : recording-controls card.
      // - ev/ev_station_detail_screen.dart : connectors/info card.
      // - price_history_screen.dart  : per-fuel-type chart card.
      // - profile_screen.dart        : profile header card.
      // - theme_settings_screen.dart : theme-preview card.
      // - search/ev_station_detail_screen.dart : rating tile card.
      // - sync/auth_screen.dart      : account-mode card.
      const allowlist = <String>{
        'lib/features/consent/presentation/screens/gdpr_consent_screen.dart',
        'lib/features/consumption/presentation/screens/consumption_screen.dart',
        'lib/features/consumption/presentation/screens/trip_detail_screen.dart',
        'lib/features/consumption/presentation/screens/trip_recording_screen.dart',
        'lib/features/ev/presentation/screens/ev_station_detail_screen.dart',
        'lib/features/price_history/presentation/screens/price_history_screen.dart',
        'lib/features/profile/presentation/screens/profile_screen.dart',
        'lib/features/profile/presentation/screens/theme_settings_screen.dart',
        'lib/features/search/presentation/screens/ev_station_detail_screen.dart',
        'lib/features/sync/presentation/screens/auth_screen.dart',
      };

      // Match the bare Material `Card(` constructor — any preceding
      // identifier character disqualifies the match, so subclass calls
      // (`StationCard(`, `SectionCard(`, …) are not flagged.
      final re = RegExp(r'(?<![A-Za-z0-9_])Card\s*\(');

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
        reason: 'Raw Card() found. Use SectionCard '
            '(lib/core/widgets/section_card.dart). See #923. '
            'Offending sites:\n${offenders.join("\n")}',
      );
    },
  );
}
