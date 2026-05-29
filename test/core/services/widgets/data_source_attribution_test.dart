// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/widgets/data_source_attribution.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2270 — the per-source data attribution must be surfaced for the active
/// country, satisfying the open-data licences that mandate visible credit
/// (CC BY / Licence Ouverte / OGL / IODL). These tests assert the active
/// country's `FuelServicePolicy.attribution` + `license` actually render.

class _FixedCountry extends ActiveCountry {
  _FixedCountry(this._country);
  final CountryConfig _country;
  @override
  CountryConfig build() => _country;
}

Future<void> _pump(WidgetTester tester, CountryConfig country) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeCountryProvider.overrideWith(() => _FixedCountry(country)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DataSourceAttribution()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DataSourceAttribution (#2270)', () {
    testWidgets('surfaces the active country\'s source + licence (DE)',
        (tester) async {
      await _pump(tester, Countries.germany);

      final policy = CountryServiceRegistry.policyFor('DE')!;
      expect(policy.attribution, 'Tankerkönig');
      expect(policy.license, 'CC BY 4.0');

      // Both the provider name and the licence must be visible on screen.
      expect(
        find.textContaining(policy.attribution),
        findsOneWidget,
        reason: 'the active source name must be rendered',
      );
      expect(
        find.textContaining(policy.license),
        findsOneWidget,
        reason: 'the source licence must be rendered',
      );
    });

    testWidgets('renders France Licence Ouverte attribution', (tester) async {
      await _pump(tester, Countries.france);

      final policy = CountryServiceRegistry.policyFor('FR')!;
      expect(find.textContaining(policy.attribution), findsOneWidget);
      expect(find.textContaining(policy.license), findsOneWidget);
      // Sanity: France's licence is the Licence Ouverte the screen must credit.
      expect(policy.license, contains('Licence Ouverte'));
    });

    testWidgets('renders Italy IODL attribution', (tester) async {
      await _pump(tester, Countries.italy);
      final policy = CountryServiceRegistry.policyFor('IT')!;
      expect(find.textContaining(policy.attribution), findsOneWidget);
      expect(find.textContaining(policy.license), findsOneWidget);
      expect(policy.license, contains('IODL'));
    });

    testWidgets('renders Mexico attribution', (tester) async {
      await _pump(tester, Countries.mexico);
      final policy = CountryServiceRegistry.policyFor('MX')!;
      expect(find.textContaining(policy.attribution), findsOneWidget);
      expect(find.textContaining(policy.license), findsOneWidget);
    });

    testWidgets('renders nothing for an unregistered country', (tester) async {
      // A CountryConfig whose code has no registry entry → no policy → the
      // widget collapses rather than showing a half-empty credit.
      const unknown = CountryConfig(
        code: 'ZZ',
        name: 'Nowhere',
        flag: '🏴',
        locale: 'en',
        postalCodeLength: 5,
        postalCodeRegex: r'^\d{5}$',
        postalCodeLabel: 'ZIP',
      );
      expect(CountryServiceRegistry.policyFor('ZZ'), isNull);

      await _pump(tester, unknown);
      expect(find.byType(Text), findsNothing);
    });
  });
}
