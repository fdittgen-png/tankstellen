// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Proves `tool/autofill_locales.dart` makes the #1699 completeness gate
// un-trippable by an en+de-only fragment addition (#2335).
//
// The tool hard-codes the `lib/l10n` path, so we drive it through a
// throwaway repo-shaped temp directory (a `lib/l10n` subtree + a copy of
// the two tool scripts) via `dart run`. This keeps the real tree
// untouched while exercising the exact production code path.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('autofill_locales (#2335)', () {
    late Directory sandbox;
    late Directory l10n;
    late File toolBuild;
    late File toolAutofill;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('autofill_test_');
      l10n = Directory('${sandbox.path}/lib/l10n')..createSync(recursive: true);
      final toolDir = Directory('${sandbox.path}/tool')..createSync();

      // Copy the real tool scripts so we exercise production logic.
      toolAutofill = File('${toolDir.path}/autofill_locales.dart');
      File('tool/autofill_locales.dart').copySync(toolAutofill.path);
      toolBuild = File('${toolDir.path}/autofill_runner.dart')
        ..writeAsStringSync(
          "import 'autofill_locales.dart' as a;\n"
          'void main(List<String> args) => a.main(args);\n',
        );
    });

    tearDown(() {
      if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
    });

    void writeArb(String locale, Map<String, dynamic> data) {
      final body =
          '${const JsonEncoder.withIndent('  ').convert(data)}\n';
      File('${l10n.path}/app_$locale.arb').writeAsStringSync(body);
    }

    Map<String, dynamic> readArb(String locale) =>
        jsonDecode(File('${l10n.path}/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;

    Future<ProcessResult> runAutofill([List<String> args = const []]) {
      return Process.run(
        'dart',
        ['run', toolBuild.path, ...args],
        workingDirectory: sandbox.path,
        runInShell: false,
      );
    }

    /// Real (non-metadata) key set of a locale ARB.
    Set<String> realKeys(String locale) => readArb(locale)
        .keys
        .where((k) => !k.startsWith('@'))
        .toSet();

    test(
        'an en+de-only key addition is auto-filled into all other locales — '
        'the #1699 gate can no longer be tripped', () async {
      // Baseline: en + de + three partial locales, all complete.
      const common = {
        'appTitle': 'Sparkilo',
        'search': 'Search',
      };
      writeArb('en', {'@@locale': 'en', ...common});
      writeArb('de', {'@@locale': 'de', 'appTitle': 'Sparkilo', 'search': 'Suche'});
      writeArb('fr', {'@@locale': 'fr', 'appTitle': 'Sparkilo', 'search': 'Rechercher'});
      writeArb('bg', {'@@locale': 'bg', 'appTitle': 'Sparkilo', 'search': 'Търсене'});
      writeArb('en_XA', {'@@locale': 'en_XA', 'appTitle': '⟦Sparkilo⟧', 'search': '⟦Search⟧'});

      // The contributor edits ONLY en + de (as if via fragments): adds a
      // new key with placeholder metadata. No other locale is touched.
      writeArb('en', {
        '@@locale': 'en',
        ...common,
        'stationCount': '{count} stations',
        '@stationCount': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      });
      writeArb('de', {
        '@@locale': 'de',
        'appTitle': 'Sparkilo',
        'search': 'Suche',
        'stationCount': '{count} Tankstellen',
      });

      // Before autofill: fr/bg are missing the new key (gate would trip).
      expect(realKeys('fr').contains('stationCount'), isFalse);
      expect(realKeys('bg').contains('stationCount'), isFalse);

      final result = await runAutofill();
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      // After autofill: every non-en/de, non-pseudo locale holds 100% of
      // the English keys — the #1699 gate's invariant.
      final enKeys = realKeys('en');
      for (final locale in const ['fr', 'bg']) {
        expect(realKeys(locale), containsAll(enKeys),
            reason: '$locale must hold every app_en.arb key after autofill');
      }

      // en + de are the human source — autofill must NOT touch them.
      expect(realKeys('de').contains('stationCount'), isTrue);
      expect(readArb('de')['stationCount'], '{count} Tankstellen',
          reason: 'existing German translation must be preserved verbatim');

      // The pseudo-locale is owned by gen_pseudo_arb.dart — autofill skips
      // it (it stays at its original 2 keys, untouched here).
      expect(realKeys('en_XA'), {'appTitle', 'search'},
          reason: 'autofill must not touch the en_XA pseudo-locale');
    });

    test('machine-filled entries carry the MT marker + English value', () async {
      writeArb('en', {
        '@@locale': 'en',
        'greeting': 'Hello',
      });
      writeArb('de', {'@@locale': 'de', 'greeting': 'Hallo'});
      writeArb('fr', {'@@locale': 'fr'}); // empty — needs fill

      final r = await runAutofill();
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');

      final fr = readArb('fr');
      expect(fr['greeting'], 'Hello',
          reason: 'machine-fill uses the English value as a fallback');
      final meta = fr['@greeting'] as Map<String, dynamic>;
      expect(meta['x-mt'], 'needs-native-review',
          reason: 'machine-filled entries must carry the findable MT marker');
      expect(meta['description'], 'MT — needs native review');
    });

    test('existing human translations are never overwritten', () async {
      writeArb('en', {'@@locale': 'en', 'search': 'Search', 'map': 'Map'});
      writeArb('de', {'@@locale': 'de', 'search': 'Suche', 'map': 'Karte'});
      // fr has a human translation for `search`, missing `map`.
      writeArb('fr', {'@@locale': 'fr', 'search': 'Rechercher'});

      final r = await runAutofill();
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');

      final fr = readArb('fr');
      expect(fr['search'], 'Rechercher',
          reason: 'human translation must survive autofill');
      expect(fr.containsKey('@search'), isFalse,
          reason: 'no MT marker on a key that was already translated');
      expect(fr['map'], 'Map', reason: 'missing key machine-filled');
    });

    test('idempotent — a second run produces byte-identical output', () async {
      writeArb('en', {'@@locale': 'en', 'a': 'A', 'b': 'B'});
      writeArb('de', {'@@locale': 'de', 'a': 'A', 'b': 'B'});
      writeArb('fr', {'@@locale': 'fr', 'a': 'A'});

      final r1 = await runAutofill();
      expect(r1.exitCode, 0, reason: '${r1.stdout}\n${r1.stderr}');
      final after1 = File('${l10n.path}/app_fr.arb').readAsStringSync();

      final r2 = await runAutofill();
      expect(r2.exitCode, 0, reason: '${r2.stdout}\n${r2.stderr}');
      final after2 = File('${l10n.path}/app_fr.arb').readAsStringSync();

      expect(after2, after1, reason: 'autofill must be idempotent');
      // --check on a complete tree must succeed (exit 0).
      final check = await runAutofill(const ['--check']);
      expect(check.exitCode, 0,
          reason: '--check must pass once the tree is complete');
    });

    test('drops a locale-only key that no longer exists in English', () async {
      writeArb('en', {'@@locale': 'en', 'keep': 'Keep'});
      writeArb('de', {'@@locale': 'de', 'keep': 'Behalten'});
      // fr carries a stale key that English dropped.
      writeArb('fr', {'@@locale': 'fr', 'keep': 'Garder', 'stale': 'Périmé'});

      final r = await runAutofill();
      expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');

      final fr = realKeys('fr');
      expect(fr.contains('stale'), isFalse,
          reason: 'orphan key must be dropped to stay a subset of English');
      expect(fr.contains('keep'), isTrue);
    });
  });
}
