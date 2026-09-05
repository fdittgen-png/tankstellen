// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

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
        when(() => storage.mock.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const DemoModeBanner(country: Countries.germany),
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
      'shows nothing when country requires API key and key is configured',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey(any())).thenReturn(true);

        await pumpApp(
          tester,
          const DemoModeBanner(country: Countries.germany),
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
        when(() => storage.mock.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const DemoModeBanner(country: Countries.germany),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.germany),
          ],
        );

        // The demo banner should have a TextButton (the call-to-action).
        expect(find.byType(TextButton), findsOneWidget);
      },
    );

    testWidgets(
      'demo banner copy is jargon-free — no "API key" wording (#1696)',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const DemoModeBanner(country: Countries.germany),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.germany),
          ],
        );

        // #1696 — neither the banner content nor its action exposes the
        // "API key" jargon to a casual user.
        expect(find.textContaining('API key'), findsNothing);
        expect(find.textContaining('API-Schlüssel'), findsNothing);
        expect(find.text('Get live prices'), findsOneWidget);
      },
    );

    testWidgets(
      'a free-API country renders NOTHING here — its credit is the summary '
      'band\'s first segment (#3955)',
      (tester) async {
        final storage = mockHiveStorageOverride();

        await pumpApp(
          tester,
          const DemoModeBanner(country: Countries.france),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.france),
          ],
        );

        expect(find.byType(MaterialBanner), findsNothing);
        expect(find.textContaining('Prix-Carburants'), findsNothing);
      },
    );
  });
}
