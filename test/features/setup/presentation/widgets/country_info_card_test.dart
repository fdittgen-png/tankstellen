import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/widgets/country_info_card.dart';
import 'package:tankstellen/features/setup/presentation/widgets/country_status_badge.dart';

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
  fuelTypes: ['e5', 'e10', 'diesel'],
);

const _demoCountry = CountryConfig(
  code: 'XX',
  name: 'Demoland',
  flag: '🏳',
  locale: 'en_US',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'ZIP',
  requiresApiKey: false,
  fuelTypes: ['e5', 'diesel'],
);

void main() {
  group('CountryInfoCard', () {
    Future<void> pumpCard(WidgetTester tester, CountryConfig country) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryInfoCard(country: country),
          ),
        ),
      );
    }

    testWidgets('renders the country name and the data-source line',
        (tester) async {
      await pumpCard(tester, _germany);
      expect(find.text('Deutschland'), findsOneWidget);
      expect(find.text('Data: Tankerkoenig'), findsOneWidget);
    });

    testWidgets('renders "Data: Demo" when no apiProvider is configured',
        (tester) async {
      await pumpCard(tester, _demoCountry);
      expect(find.text('Data: Demo'), findsOneWidget);
    });

    testWidgets('renders the comma-joined fuel types line', (tester) async {
      await pumpCard(tester, _germany);
      expect(find.text('Fuel types: e5, e10, diesel'), findsOneWidget);
    });

    testWidgets('embeds a CountryStatusBadge for the API-key requirement',
        (tester) async {
      await pumpCard(tester, _germany);
      expect(find.byType(CountryStatusBadge), findsOneWidget);
    });

    testWidgets(
        'wraps the whole card in a Semantics envelope so screen readers '
        'announce one sentence instead of every detail twice',
        (tester) async {
      await pumpCard(tester, _germany);
      // The combined semantics label includes the API-key requirement and
      // the fuel-types list — match a substring so this stays robust to
      // tweaks elsewhere in the sentence.
      final sem = find.bySemanticsLabel(
        RegExp(r'Deutschland.*API key required.*e5, e10, diesel'),
      );
      expect(sem, findsAtLeast(1));
    });

    testWidgets(
        'wraps the visual flag/title/fuels in ExcludeSemantics so they '
        "don't double up with the parent Semantics label", (tester) async {
      await pumpCard(tester, _germany);
      expect(find.byType(ExcludeSemantics), findsAtLeast(3));
    });
  });
}
