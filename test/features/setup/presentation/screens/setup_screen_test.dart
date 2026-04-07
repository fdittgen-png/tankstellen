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

    testWidgets('shows no validation indicator when API key field is empty',
        (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      // No check or error icons when the field is empty
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('shows error indicator for invalid UUID format',
        (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      // Enter invalid key
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'not-a-valid-key');

      // Wait for debounce (500ms) + settle
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows check indicator for valid UUID format',
        (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      // Enter valid UUID key
      final textField = find.byType(TextField);
      await tester.enterText(
        textField,
        '12345678-1234-1234-1234-123456789abc',
      );

      // Wait for debounce (500ms) + settle
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('shows error text for invalid UUID format', (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'bad-key');

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // The l10n error message or English fallback
      expect(
        find.textContaining('UUID'),
        findsOneWidget,
      );
    });

    testWidgets('clears validation state when field is emptied',
        (tester) async {
      await pumpApp(
        tester,
        const SetupScreen(),
        overrides: _setupOverrides(),
      );

      final textField = find.byType(TextField);

      // Enter invalid key
      await tester.enterText(textField, 'bad');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Clear the field
      await tester.enterText(textField, '');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // No validation icons when empty
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
