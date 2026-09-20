// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'french_required_prefixes.dart';

void main() {
  group('Localization completeness', () {
    late Map<String, dynamic> referenceArb;
    late Set<String> referenceKeys;
    late List<File> arbFiles;

    setUp(() {
      final l10nDir = Directory('lib/l10n');
      expect(l10nDir.existsSync(), isTrue,
          reason: 'lib/l10n directory must exist');

      arbFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList();

      // Load the English reference file
      final referenceFile =
          arbFiles.firstWhere((f) => f.path.contains('app_en.arb'));
      referenceArb =
          jsonDecode(referenceFile.readAsStringSync()) as Map<String, dynamic>;

      // Extract non-metadata keys (keys that don't start with @ or @@)
      referenceKeys = referenceArb.keys
          .where((k) => !k.startsWith('@'))
          .toSet();
    });

    test('reference (app_en.arb) has translatable keys', () {
      expect(referenceKeys, isNotEmpty,
          reason: 'app_en.arb should have at least one translatable key');
      // Sanity check: should have common keys
      expect(referenceKeys, contains('appTitle'));
      expect(referenceKeys, contains('search'));
      expect(referenceKeys, contains('favorites'));
    });

    test('all locale ARB files exist and are valid JSON', () {
      expect(arbFiles.length, greaterThanOrEqualTo(2),
          reason: 'Should have at least en + one other locale');

      for (final file in arbFiles) {
        final content = file.readAsStringSync();
        expect(
          () => jsonDecode(content),
          returnsNormally,
          reason: '${file.path} should be valid JSON',
        );
      }
    });

    test('every locale has the same keys as app_en.arb', () {
      final missingReport = <String, List<String>>{};

      for (final file in arbFiles) {
        if (file.path.contains('app_en.arb')) continue;

        final locale = _extractLocale(file.path);
        final arb =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final localeKeys =
            arb.keys.where((k) => !k.startsWith('@')).toSet();

        final missing = referenceKeys.difference(localeKeys);
        if (missing.isNotEmpty) {
          missingReport[locale] = missing.toList()..sort();
        }
      }

      if (missingReport.isNotEmpty) {
        final buffer = StringBuffer('Missing localization keys:\n');
        for (final entry in missingReport.entries) {
          buffer.writeln(
              '  ${entry.key}: ${entry.value.length} missing — ${entry.value.join(", ")}');
        }
        // Print the report but don't fail — missing translations fall back
        // to English at runtime. This serves as documentation of gaps.
        // ignore: avoid_print
        print(buffer.toString());
      }

      // German (primary) must be complete — it's the app's main language.
      // Other locales get a softer check.
      final germanMissing = missingReport['de'];
      expect(germanMissing, isNull,
          reason: 'German (de) must have all keys from app_en.arb');

      // French is the project's primary user locale (#495). A handful of
      // core French-reachable surfaces must NOT fall back to English even
      // though other locales may. Those surfaces are declared, one prefix
      // per line, in `french_required_prefixes.dart` — adding a new
      // French-reachable surface is a one-line data edit there, no test
      // logic change. Each prefix's rationale (and originating incident) is
      // documented alongside it in that file.
      final frenchMissing = missingReport['fr'] ?? const <String>[];
      final frenchMissingRequired = frenchMissing
          .where((k) =>
              kFrenchRequiredPrefixes.any((prefix) => k.startsWith(prefix)))
          .toList()
        ..sort();
      expect(frenchMissingRequired, isEmpty,
          reason: 'French (fr) must translate every key matching a '
              'required surface prefix in french_required_prefixes.dart — '
              'these core surfaces (onboarding, Edit vehicle, Feature '
              'management, loyalty cards, trip-path, fill-up reconciliation, '
              'auto-record consent, …) must not fall back to English for '
              'French users. Add a prefix to french_required_prefixes.dart '
              'when a new French-reachable surface ships.');
    });

    // #1699 — all 22 partial locales were brought to 100% coverage of
    // the app_en.arb template (en/de/fr were already complete). This
    // gate keeps it that way: it emits the untranslated-messages report
    // to the CI log and FAILS if any locale regresses, so a new
    // app_en.arb key added without a translation in every
    // app_<locale>.arb is caught before merge rather than silently
    // falling back to English in production.
    test('every locale ARB is fully translated — no coverage '
        'regressions (#1699)', () {
      final missingReport = <String, List<String>>{};

      for (final file in arbFiles) {
        if (file.path.contains('app_en.arb')) continue;

        final locale = _extractLocale(file.path);
        final arb =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final localeKeys =
            arb.keys.where((k) => !k.startsWith('@')).toSet();

        final missing = referenceKeys.difference(localeKeys);
        if (missing.isNotEmpty) {
          missingReport[locale] = missing.toList()..sort();
        }
      }

      // Untranslated-messages report — always emitted to the CI log.
      if (missingReport.isEmpty) {
        // ignore: avoid_print
        print('Translation coverage: all ${arbFiles.length - 1} locales '
            'at 100% of ${referenceKeys.length} app_en.arb keys.');
      } else {
        final buffer = StringBuffer(
            'Translation coverage regression — locales below 100%:\n');
        for (final entry in missingReport.entries) {
          buffer.writeln('  ${entry.key}: ${entry.value.length} '
              'untranslated — ${entry.value.join(", ")}');
        }
        // ignore: avoid_print
        print(buffer.toString());
      }

      expect(missingReport, isEmpty,
          reason: 'Every locale ARB must contain every app_en.arb key. '
              'All offered locales reached 100% coverage in #1699; a key '
              'added to app_en.arb must be translated into every '
              'app_<locale>.arb in the same change. See the printed '
              'report above for the untranslated keys.');
    });

    test('no locale has extra keys not in app_en.arb', () {
      final extraReport = <String, List<String>>{};

      for (final file in arbFiles) {
        if (file.path.contains('app_en.arb')) continue;

        final locale = _extractLocale(file.path);
        final arb =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final localeKeys =
            arb.keys.where((k) => !k.startsWith('@')).toSet();

        final extra = localeKeys.difference(referenceKeys);
        if (extra.isNotEmpty) {
          extraReport[locale] = extra.toList()..sort();
        }
      }

      if (extraReport.isNotEmpty) {
        final buffer = StringBuffer('Extra keys not in app_en.arb:\n');
        for (final entry in extraReport.entries) {
          buffer.writeln(
              '  ${entry.key}: ${entry.value.length} extra — ${entry.value.join(", ")}');
        }
        // Extra keys are informational — they may be intentional overrides
        // or leftover from removed features. Print for visibility.
        // ignore: avoid_print
        print(buffer.toString());
      }
    });

    // #2857 shipped English on the alerts screen: the keys were PRESENT and
    // held the English value, which every presence gate above accepts. The
    // fix was a two-key special case here. #4436 found four more of the same
    // thing — `onboardingTitle` was literally "Set up Sparkilo" on the first
    // screen a French user ever sees — so the check is no longer scoped to
    // the keys that happened to get reported. It covers every key under a
    // declared French-reachable surface, which is what
    // `french_required_prefixes.dart` already says it means.
    group('French required surfaces are TRANSLATED, not just present '
        '(#2857, #4436)', () {
      // Both helpers read the enclosing group's `setUp`-initialised state,
      // so they may only be called from inside a test body. A `setUpAll`
      // here would run BEFORE that `setUp` and read an uninitialised
      // `late` local — which passes locally, because an earlier test in
      // the file has already assigned it, and fails the moment a CI shard
      // hands this group its tests without the ones above.
      Map<String, dynamic> frenchArb() => jsonDecode(
            arbFiles
                .firstWhere((f) => f.path.endsWith('app_fr.arb'))
                .readAsStringSync(),
          ) as Map<String, dynamic>;

      List<String> frenchRequiredKeys() => referenceArb.keys
          .where((k) => !k.startsWith('@'))
          .where((k) =>
              kFrenchRequiredPrefixes.any((prefix) => k.startsWith(prefix)))
          .toList()
        ..sort();

      test('the surface list actually matches keys — an empty match would '
          'make every assertion below vacuous', () {
        final requiredKeys = frenchRequiredKeys();
        expect(requiredKeys, isNotEmpty);
        expect(requiredKeys, contains('onboardingTitle'));
        expect(requiredKeys, contains('alertsStationSectionTitle'));
      });

      test('no required key holds the English string', () {
        final fr = frenchArb();
        final english = <String>[];
        for (final key in frenchRequiredKeys()) {
          if (kFrenchEnglishIdentical.containsKey(key)) continue;
          if (fr[key] == referenceArb[key]) english.add(key);
        }
        expect(english, isEmpty,
            reason: 'these keys are on a surface `french_required_prefixes'
                '.dart` declares must carry real French, and they hold the '
                'English string — an untranslated autofill placeholder a '
                'French user reads (#2857, #4436). Translate them in a '
                '`lib/l10n/_fragments/<feature>_fr.arb` fragment so the '
                'pipeline owns the value (#4402), or — if the string is '
                'genuinely identical in both languages — add it to '
                '`kFrenchEnglishIdentical` WITH the reason: '
                '${english.join(', ')}');
      });

      test('the identical-by-design allow-list has no dead entries', () {
        // An exemption that stopped applying is worse than no exemption: it
        // silently covers whatever that key becomes next.
        final fr = frenchArb();
        final dead = <String>[];
        for (final key in kFrenchEnglishIdentical.keys) {
          if (!referenceArb.containsKey(key)) {
            dead.add('$key (no longer exists in app_en.arb)');
          } else if (fr[key] != referenceArb[key]) {
            dead.add('$key (now differs from English — exemption unused)');
          }
        }
        expect(dead, isEmpty,
            reason: 'remove these from kFrenchEnglishIdentical: '
                '${dead.join(', ')}');
      });

      test('every exemption carries a non-empty reason', () {
        for (final entry in kFrenchEnglishIdentical.entries) {
          expect(entry.value.trim(), isNotEmpty,
              reason: '${entry.key} is exempt with no stated reason');
        }
      });
    });
  });
}

/// Extract the locale code from an ARB file path like `.../app_de.arb` -> `de`.
String _extractLocale(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  // app_de.arb -> de
  return fileName
      .replaceAll('app_', '')
      .replaceAll('.arb', '');
}
