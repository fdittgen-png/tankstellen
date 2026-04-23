import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the ARB-fragment build pattern (see `docs/guides/ARB_FRAGMENTS.md`).
///
/// Three invariants:
///   1. Every `<feature>_en.arb` has a matching `<feature>_de.arb` with the
///      same set of keys. Catches "worker added an English key and forgot
///      the German translation" early.
///   2. No two fragments for the same locale share a key name. This is the
///      whole point of the pattern — if fragments collide, `build_arb.dart`
///      produces undefined output.
///   3. Running `dart run tool/build_arb.dart` would produce output
///      byte-identical to the committed `lib/l10n/app_en.arb` /
///      `lib/l10n/app_de.arb`. Catches "someone hand-edited the generated
///      file and forgot to rerun the script".
void main() {
  const fragmentsDir = 'lib/l10n/_fragments';
  const l10nDir = 'lib/l10n';
  const locales = <String>['en', 'de'];

  group('ARB fragments consistency', () {
    test('each feature fragment has matching en/de files with same keys', () {
      final dir = Directory(fragmentsDir);
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'Fragments directory missing: $fragmentsDir',
      );

      final byFeature = <String, Map<String, File>>{};
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.arb')) continue;
        final name = entity.uri.pathSegments.last;
        // `_base_en.arb` / `_base_de.arb` — skip (legacy keys, not a feature).
        if (name.startsWith('_base_')) continue;
        final match = RegExp(r'^(.+)_([a-z]{2})\.arb$').firstMatch(name);
        if (match == null) {
          fail(
            'Fragment file `$name` does not follow `<feature>_<locale>.arb` naming.',
          );
        }
        final feature = match.group(1)!;
        final locale = match.group(2)!;
        byFeature.putIfAbsent(feature, () => <String, File>{})[locale] =
            entity;
      }

      for (final entry in byFeature.entries) {
        final feature = entry.key;
        final files = entry.value;
        for (final locale in locales) {
          expect(
            files.containsKey(locale),
            isTrue,
            reason:
                'Feature `$feature` is missing `${feature}_$locale.arb` — '
                'every fragment must have both en and de variants.',
          );
        }
        // Metadata entries (`@key`, `@@locale`) are structural and
        // English-only — German/other locales do not redeclare them.
        // Parity is checked on real user-facing keys only.
        final enKeys = _realKeys(_loadKeys(files['en']!));
        final deKeys = _realKeys(_loadKeys(files['de']!));
        expect(
          deKeys.toSet(),
          equals(enKeys.toSet()),
          reason:
              'Fragment `$feature` has diverging keys between en and de. '
              'Add the missing translation or remove the stray key.',
        );
      }
    });

    test('no two fragments share a key name (same locale)', () {
      for (final locale in locales) {
        final seen = <String, String>{};
        for (final entity in Directory(fragmentsDir).listSync()) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last;
          if (!name.endsWith('_$locale.arb')) continue;
          // The base fragment is intentionally the fallback bucket for
          // not-yet-migrated keys; it always appears first and its keys are
          // allowed to be "owned" by it. We still need to detect duplicates
          // BETWEEN non-base fragments (and between a non-base and base).
          final keys = _loadKeys(entity);
          // Strip ARB metadata entries — only real keys and @key blocks
          // can collide; @@locale-style are allowed to repeat trivially.
          final real = keys.where((k) => !k.startsWith('@@'));
          for (final key in real) {
            final prior = seen[key];
            if (prior != null) {
              fail(
                'Duplicate ARB key `$key` in both `$prior` and `$name` '
                '(locale `$locale`). Rename one.',
              );
            }
            seen[key] = name;
          }
        }
      }
    });

    test('committed app_<locale>.arb matches a fresh fragment rebuild', () {
      // We reimplement the merge here (rather than shelling out to the Dart
      // build script) so the test runs under `flutter test` without needing
      // a separate `dart` invocation. The logic MUST mirror
      // `tool/build_arb.dart` — if you change the build script, update here.
      for (final locale in locales) {
        final committed = File('$l10nDir/app_$locale.arb').readAsStringSync();
        final rebuilt = _rebuild(locale, fragmentsDir);
        expect(
          rebuilt,
          equals(committed),
          reason:
              'app_$locale.arb is out of sync with the fragments. '
              'Run `dart run tool/build_arb.dart` and commit the result.',
        );
      }
    });
  });
}

Iterable<String> _loadKeys(File file) {
  final raw = file.readAsStringSync();
  final parsed = jsonDecode(raw) as Map<String, dynamic>;
  return parsed.keys;
}

/// Filters out ARB metadata entries (`@key`, `@@locale`). Only real
/// user-facing keys are compared across locales — metadata is allowed
/// to exist only in the English template.
Iterable<String> _realKeys(Iterable<String> keys) =>
    keys.where((k) => !k.startsWith('@'));

String _rebuild(String locale, String fragmentsDir) {
  final merged = <String, dynamic>{};
  final keySource = <String, String>{};

  void mergeFile(File file) {
    final raw = file.readAsStringSync();
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in parsed.entries) {
      if (merged.containsKey(entry.key)) {
        final prior = keySource[entry.key] ?? '(unknown)';
        fail(
          'Duplicate ARB key `${entry.key}` in both `$prior` and '
          '`${file.uri.pathSegments.last}` during rebuild.',
        );
      }
      merged[entry.key] = entry.value;
      keySource[entry.key] = file.uri.pathSegments.last;
    }
  }

  final base = File('$fragmentsDir/_base_$locale.arb');
  if (!base.existsSync()) {
    fail('Missing base fragment: ${base.path}');
  }
  mergeFile(base);

  final featureFragments = Directory(fragmentsDir)
      .listSync()
      .whereType<File>()
      .where((f) {
        final n = f.uri.pathSegments.last;
        if (n.startsWith('_base_')) return false;
        return n.endsWith('_$locale.arb');
      })
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in featureFragments) {
    mergeFile(f);
  }

  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert(merged)}\n';
}
