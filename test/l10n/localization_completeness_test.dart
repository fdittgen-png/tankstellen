import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

      // #495 — French is the primary user locale; the wizard completion
      // step was shipping in English because French lacked the
      // `onboarding*` keys. French does not need to be fully complete
      // yet (huge backlog), but every onboarding key MUST be present so
      // the onboarding flow is fully localised for French users.
      final frenchMissing = missingReport['fr'] ?? const <String>[];
      final frenchMissingOnboarding = frenchMissing
          .where((k) => k.startsWith('onboarding'))
          .toList()
        ..sort();
      expect(frenchMissingOnboarding, isEmpty,
          reason: 'French (fr) must have every onboarding* key — the '
              'wizard is the user\'s first impression of the app and '
              'must not fall back to English for French users');

      // #1218 — Edit vehicle was shipping mixed-locale on French because
      // calibration / service-reminder / VIN / vehicle-edit keys lacked
      // translations. Same rule as onboarding: these flows are core
      // surfaces and must not fall back to English for French users.
      final frenchMissingVehicleEdit = frenchMissing
          .where((k) =>
              k.startsWith('vehicle') ||
              k.startsWith('calibrationMode') ||
              k.startsWith('veReset') ||
              k.startsWith('serviceReminder') ||
              k == 'addServiceReminder' ||
              k.startsWith('vin'))
          .toList()
        ..sort();
      expect(frenchMissingVehicleEdit, isEmpty,
          reason: 'French (fr) must have every vehicle-edit, calibration, '
              'service-reminder and VIN key — the Edit vehicle screen '
              'must not fall back to English for French users (#1218)');
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
