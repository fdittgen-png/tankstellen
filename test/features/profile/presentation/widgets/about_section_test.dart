// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/features/profile/presentation/widgets/about_section.dart';
import 'package:tankstellen/features/profile/providers/donation_links_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AboutSection', () {
    testWidgets('renders privacy policy link with correct text',
        (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('privacy policy URL points to GitHub Pages HTTPS URL',
        (_) async {
      expect(
        AppConstants.privacyPolicyUrl,
        startsWith('https://'),
        reason: 'Privacy policy must be served over HTTPS for Play Store',
      );
      expect(
        AppConstants.privacyPolicyUrl,
        contains('github.io'),
        reason: 'Privacy policy should be hosted on GitHub Pages',
      );
    });

    testWidgets('renders app version', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.textContaining(AppConstants.appVersion), findsOneWidget);
    });

    testWidgets('renders developer name', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text(AppConstants.developerName), findsOneWidget);
    });

    testWidgets('renders GitHub link', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text('fdittgen-png/tankstellen'), findsOneWidget);
    });

    testWidgets('renders donation section when donation links are visible '
        '(Android / F-Droid)', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
        overrides: [donationLinksVisibleProvider.overrideWithValue(true)],
      );

      expect(find.text('PayPal'), findsOneWidget);
      expect(find.text('Revolut'), findsOneWidget);
    });

    testWidgets('hides the entire donation block on iOS '
        '(App Review 3.1.1, #3536)', (tester) async {
      // Apple forbids donation mechanisms other than In-App Purchase —
      // the external PayPal / Revolut links must not render at all.
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
        overrides: [donationLinksVisibleProvider.overrideWithValue(false)],
      );

      expect(find.text('PayPal'), findsNothing);
      expect(find.text('Revolut'), findsNothing);
      expect(find.text('Support this project'), findsNothing);
    });

    testWidgets(
        'Tankerkoenig attribution row is tappable + carries the open-in-new affordance',
        (tester) async {
      // Per #1473 the attribution must link to the CC BY 4.0 page so a
      // user reading "Daten von Tankerkoenig.de" on the Parameters
      // screen can jump to the licence + dataset documentation.
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text(AppConstants.tankerkoenigAttribution),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNotNull,
          reason: 'attribution row must launch the CC BY 4.0 page on tap');
      expect(tile.trailing, isA<Icon>(),
          reason: 'attribution row should carry the open-in-new affordance');
    });

    testWidgets(
        'OSM map-data row renders the localized attribution with the brand '
        'kept literal (#2402)', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      // English wrapper from the `mapAttributionOsm` ARB key; the
      // OpenStreetMap brand survives verbatim.
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    });

    test('CreativeCommons URL constant is HTTPS and points at the CC BY page',
        () {
      expect(AppConstants.tankerkoenigCreativeCommonsUrl,
          'https://creativecommons.tankerkoenig.de/');
    });

    test(
        'Registration URL constant points at the onboarding host '
        '(not the legacy creativecommons one)', () {
      // The onboarding subdomain is the post-2026 home for new API
      // key requests; creativecommons remains the licence/data page,
      // covered by [tankerkoenigCreativeCommonsUrl].
      expect(AppConstants.tankerkoenigRegistrationUrl,
          'https://onboarding.tankerkoenig.de/');
      expect(AppConstants.tankerkoenigRegistrationUrl,
          isNot(contains('creativecommons')));
    });
  });
}
