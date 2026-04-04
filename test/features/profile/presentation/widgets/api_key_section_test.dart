import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/profile/presentation/widgets/api_key_section.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('ApiKeySection', () {
    testWidgets('shows "Not configured" when no fuel API key set',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(false);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      expect(find.text('Not configured'), findsOneWidget);
    });

    testWidgets('shows "Configured" when fuel API key exists',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(true);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      expect(find.text('Configured'), findsOneWidget);
    });

    testWidgets('shows EV API key section', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(false);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      expect(find.textContaining('EV Charging'), findsOneWidget);
      expect(find.textContaining('OpenChargeMap'), findsOneWidget);
    });

    testWidgets('shows "App default key" when no custom EV key',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(true);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      expect(find.text('App default key'), findsOneWidget);
    });

    testWidgets('shows "Custom key" when custom EV key is set',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(true);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(true);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      expect(find.text('Custom key'), findsOneWidget);
    });

    testWidgets('shows fuel station icon and EV station icon',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(false);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });

    testWidgets('shows edit buttons for both API key sections',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(false);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      // Two edit buttons, one per key section
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
    });

    testWidgets('shows green check icon when key is configured',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(true);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      // EV section always shows configured (isConfigured: true)
      // Fuel section configured when hasApiKey is true
      // Both show check_circle icons
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('shows red cancel icon when fuel key is not configured',
        (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(false);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      // Fuel section not configured → cancel icon
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      // EV section always configured → check_circle
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows registration links', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);
      when(() => storage.mock.hasApiKey()).thenReturn(false);
      when(() => storage.mock.hasCustomEvApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: ApiKeySection()),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
        ],
      );

      // Two registration links (localized as "Registration")
      expect(find.text('Registration'), findsNWidgets(2));
    });
  });
}
