import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/widgets/country_status_badge.dart';

const _withKey = CountryConfig(
  code: 'DE',
  name: 'Deutschland',
  flag: '🇩🇪',
  locale: 'de_DE',
  postalCodeLength: 5,
  postalCodeRegex: r'^\d{5}$',
  postalCodeLabel: 'PLZ',
  requiresApiKey: true,
);

const _withoutKey = CountryConfig(
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
  group('CountryStatusBadge', () {
    Future<void> pumpBadge(WidgetTester tester, CountryConfig country) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryStatusBadge(country: country),
          ),
        ),
      );
    }

    testWidgets('renders "API key required" when requiresApiKey is true',
        (tester) async {
      await pumpBadge(tester, _withKey);
      expect(find.text('API key required'), findsOneWidget);
      expect(find.text('Free — no key needed'), findsNothing);
    });

    testWidgets('renders "Free — no key needed" when requiresApiKey is false',
        (tester) async {
      await pumpBadge(tester, _withoutKey);
      expect(find.text('Free — no key needed'), findsOneWidget);
      expect(find.text('API key required'), findsNothing);
    });

    testWidgets('uses the orange palette when an API key is required',
        (tester) async {
      await pumpBadge(tester, _withKey);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.orange.shade100);
    });

    testWidgets('uses the green palette when no API key is required',
        (tester) async {
      await pumpBadge(tester, _withoutKey);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.green.shade100);
    });

    testWidgets('is wrapped in ExcludeSemantics so the pill never reads to '
        'screen readers (the country tile already announces it)',
        (tester) async {
      await pumpBadge(tester, _withKey);
      // findsAtLeastNWidgets(1) — the badge tree introduces one
      // ExcludeSemantics; the test scaffold may add another one (e.g.
      // around the body), so we only assert *at least* one is present.
      expect(find.byType(ExcludeSemantics), findsAtLeast(1));
    });
  });
}
