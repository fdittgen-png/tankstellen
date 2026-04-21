import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces structural parity between `app_en.arb` (source of truth)
/// and the 22 other locale ARBs (#724).
///
/// Three levels of assertion:
///
/// 1. **No typos / orphan keys** — every non-EN locale's keys must
///    be a subset of the English keys. An extra key means someone
///    translated something that no longer exists, or mis-spelled a
///    key name. Catches copy-paste errors across locales.
///
/// 2. **No regressions** — the current per-locale key count is
///    baselined in [_baseline]. A locale can only gain keys (closing
///    the drift), never lose them. When you add translations, bump
///    the number here.
///
/// 3. **Drift visibility** — the test prints a summary of the gap
///    per locale so reviewers can see at a glance where translations
///    are lagging.
///
/// When a CI run shows "LOCALE CAN GROW", bump [_baseline] to the
/// new count and commit; otherwise CI fails regression-style.
void main() {
  /// Minimum number of keys each locale must have (regression guard).
  /// Captured on 2026-04-20. Bump as translations land.
  const Map<String, int> baseline = _baseline;

  final l10nDir = Directory('lib/l10n');
  final arbs = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  final englishFile = arbs.firstWhere(
    (f) => f.path.endsWith('app_en.arb'),
    orElse: () => throw StateError('app_en.arb missing — cannot run parity test'),
  );
  final englishKeys = _readKeys(englishFile);

  test('app_en.arb has a non-trivial number of keys (sanity check)', () {
    expect(englishKeys.length, greaterThan(100),
        reason: 'English ARB looks broken — expected >100 keys');
  });

  test('ARB file count matches the baseline locale count', () {
    expect(arbs.length, baseline.length,
        reason: 'A new ARB was added without a baseline entry, or an '
            'ARB was removed without removing the baseline entry. '
            'Current files: ${arbs.map((f) => _localeFromPath(f.path)).toList()..sort()}');
  });

  for (final file in arbs) {
    final locale = _localeFromPath(file.path);
    if (locale == 'en') continue;
    final keys = _readKeys(file);
    final baseCount = baseline[locale];

    group('locale $locale', () {
      test('every key is a subset of English (no orphan / mis-spelled keys)',
          () {
        final extras = keys.difference(englishKeys);
        expect(
          extras,
          isEmpty,
          reason:
              'Locale $locale has ${extras.length} keys that are not in '
              'app_en.arb: $extras. Either remove them or add the key to '
              'app_en.arb first.',
        );
      });

      test('key count has not regressed below the baseline', () {
        expect(baseCount, isNotNull,
            reason: 'Locale $locale missing from baseline map');
        expect(
          keys.length,
          greaterThanOrEqualTo(baseCount!),
          reason:
              'Locale $locale dropped below its baseline '
              '(${keys.length} < $baseCount). Someone deleted a '
              'translation without updating the baseline.',
        );
      });

      test('(info) drift summary', () {
        final missing = englishKeys.difference(keys);
        final pct = (keys.length * 100 / englishKeys.length).toStringAsFixed(0);
        // ignore: avoid_print — test diagnostic output only
        print('  $locale: ${keys.length}/${englishKeys.length} keys '
            '($pct%), ${missing.length} missing'
            '${keys.length > (baseCount ?? 0) ? " — LOCALE CAN GROW: update baseline to ${keys.length}" : ""}');
      });
    });
  }
}

Set<String> _readKeys(File f) {
  final raw = f.readAsStringSync();
  final map = json.decode(raw) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@')).toSet();
}

String _localeFromPath(String p) {
  final name = p.split(RegExp(r'[/\\]')).last; // app_xx.arb
  return name.replaceFirst('app_', '').replaceFirst('.arb', '');
}

/// Current per-locale key counts. Captured 2026-04-20. Translators
/// bump these when filling gaps — the regression test then catches
/// accidental removals. Locales left out of this map cause the test
/// to fail, forcing an explicit decision on new locales.
const Map<String, int> _baseline = {
  'en': 800,
  'de': 800,
  'fr': 617,
  'bg': 300,
  'cs': 300,
  'da': 300,
  'el': 300,
  'es': 300,
  'et': 300,
  'fi': 300,
  'hr': 300,
  'hu': 300,
  'it': 300,
  'lt': 300,
  'lv': 300,
  'nb': 300,
  'nl': 300,
  'pl': 300,
  'pt': 300,
  'ro': 300,
  'sk': 300,
  'sl': 300,
  'sv': 300,
};
