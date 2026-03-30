import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/features/setup/presentation/screens/setup_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// A fixed ActiveLanguage notifier for testing.
class _FixedActiveLanguage extends ActiveLanguage {
  final AppLanguage _language;
  _FixedActiveLanguage(this._language);

  @override
  AppLanguage build() => _language;
}

void main() {
  group('SetupScreen', () {
    List<Object> _setupOverrides() {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      return [
        ...test.overrides,
        activeLanguageProvider
            .overrideWith(() => _FixedActiveLanguage(AppLanguages.all.first)),
        userPositionNullOverride(),
      ];
    }

    testWidgets('renders language selection chips', (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      // Should find ChoiceChip widgets for languages
      expect(find.byType(ChoiceChip), findsAtLeast(1));
      // Check that some known language names appear
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('renders country selection chips', (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      // Country chips contain flag + name, e.g. "🇩🇪 Germany"
      // There should be at least one ChoiceChip for countries
      // (total chips = language chips + country chips)
      final chips = find.byType(ChoiceChip);
      // AppLanguages.all has 10 languages, Countries.all has multiple countries
      expect(chips, findsAtLeast(11));
    });

    testWidgets('renders continue button', (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      // Germany requires API key, so button text is 'Continue with demo data'
      expect(find.text('Continue with demo data'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('renders welcome text and gas station icon', (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      // Welcome text from l10n?.welcome ?? 'Fuel Prices'
      expect(find.text('Fuel Prices'), findsOneWidget);
    });
  });
}
