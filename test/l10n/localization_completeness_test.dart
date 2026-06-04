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

    // #2857 — the redesigned alerts screen's "Station alerts" header shipped
    // as English-equal autofill placeholders in French (a primary locale).
    // The presence-based coverage gates above can't catch this (the keys ARE
    // present, just holding the English value), so assert value-distinctness
    // for the alerts-screen section labels a French user reads.
    test('French alerts-section labels are real translations, not English '
        'placeholders (#2857)', () {
      final frFile = arbFiles.firstWhere((f) => f.path.endsWith('app_fr.arb'));
      final fr = jsonDecode(frFile.readAsStringSync()) as Map<String, dynamic>;

      for (final key in const [
        'alertsStationSectionTitle',
        'alertsStationAdd',
      ]) {
        expect(fr[key], isNotNull,
            reason: 'app_fr.arb must contain $key');
        expect(fr[key], isNot(equals(referenceArb[key])),
            reason: 'French $key still equals the English value — it is an '
                'untranslated autofill placeholder. Provide a real French '
                'string in app_fr.arb (#2857).');
      }
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
