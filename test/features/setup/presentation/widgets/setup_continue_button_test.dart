import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/widgets/setup_continue_button.dart';

const _germany = CountryConfig(
  code: 'DE',
  name: 'Deutschland',
  flag: '🇩🇪',
  locale: 'de_DE',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'PLZ',
  requiresApiKey: true,
);

const _france = CountryConfig(
  code: 'FR',
  name: 'France',
  flag: '🇫🇷',
  locale: 'fr_FR',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'Code postal',
  requiresApiKey: false,
);

void main() {
  group('SetupContinueButton', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      required CountryConfig country,
      required bool apiKeyEmpty,
      bool isLoading = false,
      VoidCallback? onPressed,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupContinueButton(
              isLoading: isLoading,
              country: country,
              apiKeyEmpty: apiKeyEmpty,
              onPressed: onPressed ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets(
        'reads "Continue with demo data" when the country requires a key '
        'but the user has not entered one', (tester) async {
      await pumpButton(tester, country: _germany, apiKeyEmpty: true);
      expect(find.text('Continue with demo data'), findsOneWidget);
    });

    testWidgets(
        'reads plain "Continue" when the country requires a key and the '
        'user has supplied one', (tester) async {
      await pumpButton(tester, country: _germany, apiKeyEmpty: false);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Continue with demo data'), findsNothing);
    });

    testWidgets(
        'reads plain "Continue" when the country does not require a key',
        (tester) async {
      await pumpButton(tester, country: _france, apiKeyEmpty: true);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('replaces the label with a spinner while isLoading is true',
        (tester) async {
      await pumpButton(
        tester,
        country: _germany,
        apiKeyEmpty: false,
        isLoading: true,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('disables the button while isLoading is true', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        country: _germany,
        apiKeyEmpty: false,
        isLoading: true,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('forwards taps to onPressed when not loading',
        (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        country: _germany,
        apiKeyEmpty: false,
        onPressed: () => taps++,
      );
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });

    testWidgets('announces "Loading" via Semantics when loading',
        (tester) async {
      await pumpButton(
        tester,
        country: _germany,
        apiKeyEmpty: false,
        isLoading: true,
      );
      expect(find.bySemanticsLabel('Loading'), findsAtLeast(1));
    });
  });
}
