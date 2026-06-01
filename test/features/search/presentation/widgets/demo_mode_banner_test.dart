// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/search/presentation/widgets/demo_mode_banner.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Records every launchUrl call without touching the real platform channel,
/// so a tap on the country-service header link is verifiable in a unit test
/// (#2373). Mixes in [MockPlatformInterfaceMixin] so the verify-token guard
/// on [UrlLauncherPlatform.instance] accepts the assignment in test builds.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

void main() {
  group('DemoModeBanner', () {
    testWidgets(
      'shows demo banner when country requires API key and no key configured',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey()).thenReturn(false);

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
      'shows country info when country does not require API key',
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
      'country info bar wraps instead of clipping under large text (#1698)',
      (tester) async {
        // Narrow viewport + 3x text scaling — the old single-line
        // ellipsis Row clipped the provider name; it must now wrap.
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final storage = mockHiveStorageOverride();

        await pumpApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(3.0)),
              child: const DemoModeBanner(country: Countries.france),
            ),
          ),
          overrides: [
            storage.override,
            activeCountryOverride(Countries.france),
          ],
        );

        // The label is still present (not clipped away) and no longer
        // ellipsis-truncates — it wraps freely instead.
        final labelFinder = find.textContaining('Prix-Carburants');
        expect(labelFinder, findsOneWidget);
        final label = tester.widget<Text>(labelFinder);
        expect(label.overflow, isNot(TextOverflow.ellipsis));
        expect(label.maxLines, isNull);
      },
    );

    testWidgets(
      'shows nothing when country requires API key and key is configured',
      (tester) async {
        final storage = mockHiveStorageOverride();
        when(() => storage.mock.hasApiKey()).thenReturn(true);

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
        when(() => storage.mock.hasApiKey()).thenReturn(false);

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
        when(() => storage.mock.hasApiKey()).thenReturn(false);

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

    // #2622 — a cross-border route crosses more than one data source; the
    // header must credit EACH crossed country's provider, not just the
    // active country.
    group('multi-source attribution for cross-border routes (#2622)', () {
      testWidgets(
        'a {FR, ES} corridor renders BOTH providers in the header',
        (tester) async {
          final storage = mockHiveStorageOverride();

          await pumpApp(
            tester,
            const DemoModeBanner(
              country: Countries.france,
              corridorCountryCodes: {'FR', 'ES'},
            ),
            overrides: [
              storage.override,
              activeCountryOverride(Countries.france),
            ],
          );

          // Both crossed countries' registry attributions are present.
          final frAttr = CountryServiceRegistry.policyFor('FR')!.attribution;
          final esAttr = CountryServiceRegistry.policyFor('ES')!.attribution;
          expect(find.textContaining(frAttr), findsOneWidget);
          expect(find.textContaining(esAttr), findsOneWidget);
          // Both country names appear in the same joined header line.
          expect(find.textContaining('France'), findsOneWidget);
          expect(find.textContaining('España'), findsOneWidget);
          // It is NOT the single-country MaterialBanner / link header.
          expect(find.byType(MaterialBanner), findsNothing);
        },
      );

      testWidgets(
        'a single-country corridor still shows the single-country header',
        (tester) async {
          final storage = mockHiveStorageOverride();

          await pumpApp(
            tester,
            const DemoModeBanner(
              country: Countries.france,
              corridorCountryCodes: {'FR'},
            ),
            overrides: [
              storage.override,
              activeCountryOverride(Countries.france),
            ],
          );

          // One code → falls through to the historical single-country
          // header (the tappable Prix-Carburants link), Spain not credited.
          expect(find.textContaining('Prix-Carburants'), findsOneWidget);
          expect(
            find.textContaining(
                CountryServiceRegistry.policyFor('ES')!.attribution),
            findsNothing,
          );
        },
      );
    });

    // #2373 — the country-service header is now a tappable link to the
    // upstream data source, replacing the old bottom attribution footer.
    group('country-service source link (#2373)', () {
      late _FakeUrlLauncher launcher;

      setUp(() {
        launcher = _FakeUrlLauncher();
        UrlLauncherPlatform.instance = launcher;
      });

      testWidgets(
        'free-API header renders a link affordance (open_in_new + underline)',
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

          // The header is wrapped in a link (InkWell) and carries an
          // open-in-new affordance so the user knows it leaves the app.
          expect(find.byType(InkWell), findsOneWidget);
          expect(find.byIcon(Icons.open_in_new), findsOneWidget);

          // The provider label is underlined to signal it is a link.
          final label = tester.widget<Text>(
            find.textContaining('Prix-Carburants'),
          );
          expect(label.style?.decoration, TextDecoration.underline);
        },
      );

      testWidgets(
        'tapping the header opens the active country policy.sourceUrl',
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

          await tester.tap(find.byType(InkWell));
          await tester.pumpAndSettle();

          // The launched URL must be France's policy.sourceUrl — the link
          // is wired to the registry's single source of truth, not a
          // hard-coded URL.
          final expected = CountryServiceRegistry.policyFor('FR')!.sourceUrl;
          expect(expected, isNotEmpty);
          expect(launcher.launchedUrls, contains(expected));
        },
      );

      testWidgets(
        'link a11y label preserves the provider + licence attribution',
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

          // The relocated attribution must still credit the source +
          // licence — exposed via the link's Semantics label / Tooltip
          // (the open-data licences mandate a visible/accessible credit).
          final policy = CountryServiceRegistry.policyFor('FR')!;
          final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
          expect(tooltip.message, contains(policy.attribution));
          expect(tooltip.message, contains(policy.license));
        },
      );
    });
  });
}
