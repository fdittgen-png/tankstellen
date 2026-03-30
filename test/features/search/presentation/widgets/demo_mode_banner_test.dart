import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/search/presentation/widgets/demo_mode_banner.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('DemoModeBanner', () {
    testWidgets(
      'shows demo banner when country requires API key and no key configured',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          DemoModeBanner(country: Countries.germany),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.germany),
          ],
        );

        // Germany requires API key, no key configured → demo banner shown
        expect(find.byType(MaterialBanner), findsOneWidget);
        expect(find.textContaining('Demo mode'), findsOneWidget);
      },
    );

    testWidgets(
      'shows country info when country does not require API key',
      (tester) async {
        final storage = mockHiveStorageOverride();

        await pumpApp(
          tester,
          DemoModeBanner(country: Countries.france),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.france),
          ],
        );

        // France does not require API key → show country info bar
        expect(find.byType(MaterialBanner), findsNothing);
        expect(find.text('France'), findsNothing); // name is part of combined text
        expect(
          find.textContaining('Prix-Carburants'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows nothing when country requires API key and key is configured',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey()).thenReturn(true);

        await pumpApp(
          tester,
          DemoModeBanner(country: Countries.germany),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.germany),
          ],
        );

        // API key is present → SizedBox.shrink (nothing visible)
        expect(find.byType(MaterialBanner), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );

    testWidgets(
      'shows Setup button in demo banner',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey()).thenReturn(false);

        await pumpApp(
          tester,
          DemoModeBanner(country: Countries.germany),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.germany),
          ],
        );

        // The demo banner should have a "Setup" TextButton
        expect(find.widgetWithText(TextButton, 'Setup'), findsOneWidget);
      },
    );
  });
}
