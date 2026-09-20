// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #4402 — a hand-written `_fragments/<feature>_<locale>.arb` must reach
// `app_<locale>.arb` through the documented pipeline, for every locale,
// not just the two that are rebuilt from scratch.
//
// Before this, `build_arb.dart` merged fragments for `en` and `de` only.
// 55 French fragments sat on disk and none was read: the documented three
// commands left `app_fr.arb` holding whatever autofill had put there, and
// the fold happened by hand. Nothing detected the gap — a machine-filled
// English value IS a value, so every coverage gate stayed green.
//
// Two halves, because "fixable" and "detectable" are different
// properties and the issue asked for both:
//
//   * the REPO half asserts the real tree is folded — it is the guard
//     that goes red if someone edits a fragment and forgets the pipeline,
//     or hand-edits `app_fr.arb` away from its fragment;
//   * the TOOL half drives `build_arb.dart` in a throwaway repo-shaped
//     sandbox, the `autofill_locales_test.dart` idiom, so the behaviour
//     is pinned independently of what the real fragments happen to say.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Locales `build_arb.dart` rebuilds wholesale; everything else is
/// autofilled and then overlaid. Mirrors `_sourceLocales` in the tool.
const Set<String> _sourceLocales = {'en', 'de'};

/// What `autofill_locales.dart` stamps on a machine-filled entry.
const String _mtField = 'x-mt';
const String _mtDescription = 'MT — needs native review';

Map<String, dynamic> _readArb(File f) =>
    jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('the real tree: every overlay fragment reaches its app_<locale>.arb',
      () {
    final fragments = Directory('lib/l10n/_fragments')
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = f.uri.pathSegments.last;
          if (name.startsWith('_base_')) return false;
          return name.endsWith('.arb');
        })
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    /// locale -> key -> (fragment file, value)
    final byLocale = <String, Map<String, (String, dynamic)>>{};
    for (final f in fragments) {
      final name = f.uri.pathSegments.last;
      final locale = name.substring(
          name.lastIndexOf('_') + 1, name.length - '.arb'.length);
      if (_sourceLocales.contains(locale)) continue;
      final into = byLocale.putIfAbsent(locale, () => {});
      for (final e in _readArb(f).entries) {
        if (e.key.startsWith('@')) continue;
        into[e.key] = (name, e.value);
      }
    }

    test('there is at least one overlay locale — otherwise this whole file '
        'is vacuous', () {
      expect(byLocale, isNotEmpty,
          reason: 'French has 55 fragments; if this is empty the naming '
              'convention changed and the guard stopped guarding');
      expect(byLocale.keys, contains('fr'));
    });

    for (final locale in ['fr']) {
      test('$locale — every fragment value is what app_$locale.arb ships',
          () {
        final app = _readArb(File('lib/l10n/app_$locale.arb'));
        final wrong = <String>[];
        for (final e in (byLocale[locale] ?? {}).entries) {
          final (source, want) = e.value;
          if (!app.containsKey(e.key)) {
            wrong.add('${e.key}: absent from app_$locale.arb ($source)');
          } else if (app[e.key] != want) {
            wrong.add('${e.key}: app_$locale.arb has ${app[e.key]}, '
                '$source has $want');
          }
        }
        expect(wrong, isEmpty,
            reason: 'run `dart run tool/build_arb.dart` and commit — or, if '
                'the app_$locale.arb wording is the better one, port it '
                'INTO the fragment. The fragment is the source of truth '
                '(#4402), so a divergence is never resolved by editing the '
                'generated file.\n${wrong.join('\n')}');
      });

      test('$locale — a fragment-owned key no longer claims it needs a '
          'native review', () {
        final app = _readArb(File('lib/l10n/app_$locale.arb'));
        final stale = <String>[];
        for (final key in (byLocale[locale] ?? {}).keys) {
          final meta = app['@$key'];
          if (meta is! Map) continue;
          if (meta.containsKey(_mtField) ||
              meta['description'] == _mtDescription) {
            stale.add(key);
          }
        }
        expect(stale, isEmpty,
            reason: 'these keys have a hand-written $locale translation in a '
                'fragment but are still marked machine-filled, so a '
                'translator sweeping for `$_mtField` would redo work that is '
                'already done: ${stale.take(10).join(', ')}');
      });
    }
  });

  group('tool/build_arb.dart overlay behaviour (sandboxed)', () {
    late Directory sandbox;
    late Directory l10n;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('overlay_test_');
      l10n = Directory('${sandbox.path}/lib/l10n')..createSync(recursive: true);
      Directory('${l10n.path}/_fragments').createSync();
      final toolDir = Directory('${sandbox.path}/tool')..createSync();
      for (final name in ['build_arb.dart', 'autofill_locales.dart']) {
        File('tool/$name').copySync('${toolDir.path}/$name');
      }
    });

    tearDown(() {
      if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
    });

    void write(String path, Map<String, dynamic> data) {
      File('${sandbox.path}/$path').writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(data)}\n');
    }

    ProcessResult build() => Process.runSync(
          'dart',
          ['run', 'tool/build_arb.dart'],
          workingDirectory: sandbox.path,
        );

    /// The minimum repo shape the tool needs: two base fragments and the
    /// generated files autofill reads and rewrites.
    void seed({
      required Map<String, dynamic> english,
      Map<String, dynamic> frenchFile = const {},
    }) {
      write('lib/l10n/_fragments/_base_en.arb',
          {'@@locale': 'en', ...english});
      write('lib/l10n/_fragments/_base_de.arb', {'@@locale': 'de'});
      write('lib/l10n/app_en.arb', {'@@locale': 'en', ...english});
      write('lib/l10n/app_de.arb', {'@@locale': 'de'});
      write('lib/l10n/app_fr.arb', {'@@locale': 'fr', ...frenchFile});
    }

    test('a French fragment overrides the machine-filled English and the '
        'marker is withdrawn', () {
      seed(english: {'greet': 'Hello', 'other': 'Bye'});
      write('lib/l10n/_fragments/feature_fr.arb', {'greet': 'Bonjour'});

      final r = build();
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      final fr = _readArb(File('${l10n.path}/app_fr.arb'));
      expect(fr['greet'], 'Bonjour');
      expect(fr['@greet'], anyOf(isNull, isNot(contains(_mtField))));
      expect(fr['@greet'], anyOf(isNull, isNot(containsValue(_mtDescription))));
    });

    test('a key the fragment does not mention keeps its machine fill — the '
        'overlay owns the keys it names and nothing else', () {
      seed(english: {'greet': 'Hello', 'other': 'Bye'});
      write('lib/l10n/_fragments/feature_fr.arb', {'greet': 'Bonjour'});

      expect(build().exitCode, 0);
      final fr = _readArb(File('${l10n.path}/app_fr.arb'));
      expect(fr['other'], 'Bye');
      expect(fr['@other'], containsPair(_mtField, 'needs-native-review'));
    });

    test('a hand-maintained value with no fragment survives untouched — the '
        'thousands of unfragmented French keys are not rebuilt away', () {
      seed(
        english: {'greet': 'Hello', 'legacy': 'Old'},
        frenchFile: {'legacy': 'Ancien'},
      );
      write('lib/l10n/_fragments/feature_fr.arb', {'greet': 'Bonjour'});

      expect(build().exitCode, 0);
      final fr = _readArb(File('${l10n.path}/app_fr.arb'));
      expect(fr['legacy'], 'Ancien');
      expect(fr['greet'], 'Bonjour');
    });

    test('placeholder metadata survives the marker strip — losing it is a '
        'gen-l10n parse failure, not a cosmetic diff', () {
      seed(english: {
        'count': '{n} items',
        '@count': {
          'placeholders': {
            'n': {'type': 'int'}
          }
        },
      });
      write('lib/l10n/_fragments/feature_fr.arb', {'count': '{n} éléments'});

      expect(build().exitCode, 0);
      final fr = _readArb(File('${l10n.path}/app_fr.arb'));
      expect(fr['count'], '{n} éléments');
      expect((fr['@count'] as Map)['placeholders'], isNotNull);
      expect(fr['@count'], isNot(contains(_mtField)));
    });

    test('a fragment key English does not have fails loudly — autofill would '
        'silently drop it on the next run', () {
      seed(english: {'greet': 'Hello'});
      write('lib/l10n/_fragments/feature_fr.arb', {'ghost': 'Fantôme'});

      final r = build();
      expect(r.exitCode, isNot(0));
      expect('${r.stdout}${r.stderr}', contains('ghost'));
    });

    test('idempotent — a second run is byte-identical', () {
      seed(english: {'greet': 'Hello', 'other': 'Bye'});
      write('lib/l10n/_fragments/feature_fr.arb', {'greet': 'Bonjour'});

      expect(build().exitCode, 0);
      final first = File('${l10n.path}/app_fr.arb').readAsStringSync();
      expect(build().exitCode, 0);
      expect(File('${l10n.path}/app_fr.arb').readAsStringSync(), first);
    });

    test('a locale with no fragments is left exactly as autofill wrote it',
        () {
      seed(english: {'greet': 'Hello'});
      write('lib/l10n/app_it.arb', {'@@locale': 'it'});

      expect(build().exitCode, 0);
      final it = _readArb(File('${l10n.path}/app_it.arb'));
      expect(it['greet'], 'Hello');
      expect(it['@greet'], containsPair(_mtField, 'needs-native-review'));
    });

    test('source locales are still REBUILT, not overlaid — a key absent from '
        'the en fragments does not survive in app_en.arb', () {
      seed(english: {'greet': 'Hello'});
      write('lib/l10n/app_en.arb', {'@@locale': 'en', 'stale': 'Gone'});

      expect(build().exitCode, 0);
      final en = _readArb(File('${l10n.path}/app_en.arb'));
      expect(en.containsKey('stale'), isFalse);
      expect(en['greet'], 'Hello');
    });
  });
}
