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
  });
}
