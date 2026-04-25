import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/features/setup/presentation/widgets/api_key_step.dart';

import '../../../../helpers/pump_app.dart';

/// Recording fake for ActiveCountry that returns a fixed config without
/// touching profile/storage providers. Mirrors the pattern used by the
/// CountryLanguageStep tests.
class _FakeActiveCountry extends ActiveCountry {
  _FakeActiveCountry(this._initial);

  final CountryConfig _initial;

  @override
  CountryConfig build() => _initial;

  @override
  Future<void> select(CountryConfig country) async {
    state = country;
  }
}

/// Country with no registration URL — exercises the branch that omits
/// the OutlinedButton link.
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

/// Country with no attribution string — exercises the branch that omits
/// the trailing attribution line.
const _germanyNoAttribution = CountryConfig(
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

void main() {
  group('ApiKeyStep', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    List<Object> overridesFor({CountryConfig? country}) {
      return [
        activeCountryProvider.overrideWith(
          () => _FakeActiveCountry(country ?? Countries.germany),
        ),
      ];
    }

    testWidgets(
        'renders title, description, key icon, TextField, and helper note',
        (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      // l10n strings (English locale by default in pumpApp).
      expect(find.text('API key setup'), findsOneWidget);
      expect(
        find.text(
          'Register for a free API key, or skip to explore the app with '
          'demo data.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Free registration. Data from government price transparency '
          'agencies.',
        ),
        findsOneWidget,
      );

      // Exactly one TextField for the API key.
      expect(find.byType(TextField), findsOneWidget);

      // The leading "key" icon at the top of the step.
      expect(find.byIcon(Icons.key), findsAtLeast(1));
    });

    testWidgets(
        'shows no validation indicator while the controller is empty '
        '(_isFormatValid stays null)', (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets(
        'shows green check after typing a valid UUID once the 500 ms '
        'debounce elapses', (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      const validUuid = '12345678-1234-1234-1234-123456789abc';
      await tester.enterText(find.byType(TextField), validUuid);
      // Before debounce: no indicator yet.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.check_circle), findsNothing);

      // After debounce: green check.
      await tester.pump(const Duration(milliseconds: 600));
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets(
        'shows red error icon and error text after typing an invalid key '
        'once the debounce elapses', (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      await tester.enterText(find.byType(TextField), 'not-a-uuid');
      await tester.pump(const Duration(milliseconds: 600));

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red);
      expect(
        find.text('Invalid format — expected UUID (8-4-4-4-12)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets(
        'pre-filled valid value is validated synchronously on initState '
        '(no debounce wait needed)', (tester) async {
      controller.text = '12345678-1234-1234-1234-123456789abc';

      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      // No `tester.pump` for a debounce — initState calls _evaluateFormat
      // directly. pumpApp already did pumpAndSettle.
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);
    });

    testWidgets(
        'pre-filled invalid value renders the error indicator immediately',
        (tester) async {
      controller.text = 'definitely-not-a-uuid';

      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red);
    });

    testWidgets(
        'renders the country-specific registration button using '
        'apiProvider when apiKeyRegistrationUrl is set', (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(country: Countries.germany),
      );

      // Germany has both apiProvider and apiKeyRegistrationUrl.
      expect(
        find.text('${Countries.germany.apiProvider} Registration'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);

      // Active country attribution string is displayed.
      expect(find.text(Countries.germany.attribution!), findsOneWidget);
    });

    testWidgets(
        'omits the registration button when apiKeyRegistrationUrl is null',
        (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(country: _germanyNoUrl),
      );

      expect(find.byIcon(Icons.open_in_new), findsNothing);
      expect(find.text('Tankerkoenig Registration'), findsNothing);
    });

    testWidgets('omits the attribution line when attribution is null',
        (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(country: _germanyNoAttribution),
      );

      // Sanity check — registration button still renders.
      expect(find.text('Tankerkoenig Registration'), findsOneWidget);
      // No attribution text below.
      expect(find.text(Countries.germany.attribution!), findsNothing);
    });

    testWidgets(
        'disposing while a debounce timer is pending does not throw '
        '(timer is cancelled in dispose)', (tester) async {
      await pumpApp(
        tester,
        ApiKeyStep(apiKeyController: controller),
        overrides: overridesFor(),
      );

      // Trigger a fresh debounce window…
      await tester.enterText(find.byType(TextField), 'pending');
      await tester.pump(const Duration(milliseconds: 100));

      // …then unmount the widget before the 500 ms timer fires.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      // Advance past the original debounce. If dispose forgot to cancel
      // the timer, the callback would call setState on an unmounted
      // state and Flutter would throw.
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
    });
  });
}
