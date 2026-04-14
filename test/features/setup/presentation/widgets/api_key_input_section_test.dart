import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/widgets/api_key_input_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

const _germany = CountryConfig(
  code: 'DE',
  name: 'Deutschland',
  flag: '🇩🇪',
  locale: 'de_DE',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'PLZ',
  requiresApiKey: true,
  apiProvider: 'Tankerkoenig',
  apiKeyRegistrationUrl: 'https://creativecommons.tankerkoenig.de/',
);

const _germanyNoUrl = CountryConfig(
  code: 'DE',
  name: 'Deutschland',
  flag: '🇩🇪',
  locale: 'de_DE',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'PLZ',
  requiresApiKey: true,
  apiProvider: 'Tankerkoenig',
);

void main() {
  group('ApiKeyInputSection', () {
    Future<void> pumpSection(
      WidgetTester tester, {
      required bool? formatValid,
      CountryConfig country = _germany,
      TextEditingController? controller,
    }) async {
      final ctrl = controller ?? TextEditingController();
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ApiKeyInputSection(
                country: country,
                controller: ctrl,
                formatValid: formatValid,
                l10n: null,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows no validation indicator when format state is null',
        (tester) async {
      await pumpSection(tester, formatValid: null);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('shows green check when the format is valid', (tester) async {
      await pumpSection(tester, formatValid: true);
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);
    });

    testWidgets('shows red error icon and error text when format is invalid',
        (tester) async {
      await pumpSection(tester, formatValid: false);
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red);
      expect(
        find.text('Invalid format — expected UUID (8-4-4-4-12)'),
        findsOneWidget,
      );
    });

    testWidgets('renders the registration button when a URL is configured',
        (tester) async {
      await pumpSection(tester, formatValid: null);
      expect(find.text('Tankerkoenig Registration'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('omits the registration button when no URL is configured',
        (tester) async {
      await pumpSection(tester, formatValid: null, country: _germanyNoUrl);
      expect(find.text('Tankerkoenig Registration'), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('routes typed text into the supplied controller',
        (tester) async {
      final controller = TextEditingController();
      await pumpSection(tester, formatValid: null, controller: controller);
      await tester.enterText(find.byType(TextField), 'abc-123');
      expect(controller.text, 'abc-123');
    });

    testWidgets('renders the terms-of-use disclaimer with provider name',
        (tester) async {
      await pumpSection(tester, formatValid: null);
      expect(
        find.textContaining('Tankerkoenig'),
        findsAtLeast(1),
      );
      expect(
        find.textContaining('Data redistribution is prohibited.'),
        findsOneWidget,
      );
    });
  });
}
