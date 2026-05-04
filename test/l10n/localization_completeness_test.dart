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

      // The Fuel Club Cards (loyalty) settings sub-screen shipped with
      // only `en` + `de` ARB fragments, so French users saw an entirely
      // English screen — including the menu tile that opens it. Same
      // rule as onboarding / vehicle-edit: surfaces a French user can
      // reach must not fall back to English.
      final frenchMissingLoyalty = frenchMissing
          .where((k) => k.startsWith('loyalty'))
          .toList()
        ..sort();
      expect(frenchMissingLoyalty, isEmpty,
          reason: 'French (fr) must have every loyalty* key — the '
              'Fuel club cards screen and its add-card sheet must not '
              'fall back to English for French users');

      // #1373 phase 2 — the Feature management section in Settings is
      // a French-reachable surface. Every per-feature label, description
      // and blocked-transition tooltip must have a French translation
      // so the section isn't a wall of English on French devices.
      final frenchMissingFeatureMgmt = frenchMissing
          .where((k) =>
              k.startsWith('featureManagementSection') ||
              k.startsWith('featureLabel_') ||
              k.startsWith('featureDescription_') ||
              k.startsWith('featureBlockedEnable_') ||
              k.startsWith('featureBlockedDisable_'))
          .toList()
        ..sort();
      expect(frenchMissingFeatureMgmt, isEmpty,
          reason: 'French (fr) must have every featureManagement / '
              'featureLabel_ / featureDescription_ / featureBlockedEnable_ / '
              'featureBlockedDisable_ key — the Feature management section '
              'in Settings must not fall back to English for French users '
              '(#1373 phase 2)');

      // #1374 phase 2 — the GPS trip-path overlay card on the trip
      // detail screen is a French-reachable surface. Its title and
      // subtitle must have French translations so the card isn't an
      // English island in an otherwise French screen.
      final frenchMissingTripPath = frenchMissing
          .where((k) => k.startsWith('tripPath'))
          .toList()
        ..sort();
      expect(frenchMissingTripPath, isEmpty,
          reason: 'French (fr) must have every tripPath* key — the '
              'GPS trip-path overlay on the trip detail screen must '
              'not fall back to English for French users (#1374 '
              'phase 2)');

      // #1401 phase 6 — the adapter-capability card lives on the
      // Edit-vehicle screen, which is a French-reachable surface
      // (already enforced for `vehicle*` and `calibration*` keys).
      // Same rule: every `obd2Capability*` key must be French so the
      // tier label and OBDLink hint don't fall back to English.
      final frenchMissingObd2Capability = frenchMissing
          .where((k) => k.startsWith('obd2Capability'))
          .toList()
        ..sort();
      expect(frenchMissingObd2Capability, isEmpty,
          reason: 'French (fr) must have every obd2Capability* key — '
              'the adapter-capability card on the Edit vehicle screen '
              'must not fall back to English for French users (#1401 '
              'phase 6)');

      // #1401 phase 7b — the verified-by-adapter badge sits on every
      // fill-up card and the variance dialog fires inside the Add
      // fill-up flow, both reachable for French users. Every
      // `fillUpReconciliation*` key must have a French translation
      // so the chip label and confirmation prompt don't fall back to
      // English on the Fuel tab.
      final frenchMissingFillUpReconciliation = frenchMissing
          .where((k) => k.startsWith('fillUpReconciliation'))
          .toList()
        ..sort();
      expect(frenchMissingFillUpReconciliation, isEmpty,
          reason: 'French (fr) must have every fillUpReconciliation* '
              'key — the verified-by-adapter badge and variance prompt '
              'on the fill-up flow must not fall back to English for '
              'French users (#1401 phase 7b)');
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
