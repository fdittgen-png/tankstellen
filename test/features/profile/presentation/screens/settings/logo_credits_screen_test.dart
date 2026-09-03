// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/brand_logo_manifest.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/logo_credits_screen.dart';

import '../../../../../helpers/pump_app.dart';

/// The credits screen is a licence obligation, not decoration (#3940):
/// CC-BY and CC-BY-SA both require attribution, and the trademark notice
/// answers the separate question a public-domain file does not. Each of
/// those must survive a refactor, so each is pinned.
void main() {
  group('LogoCreditsScreen', () {
    testWidgets('lists every bundled logo with its licence and author',
        (tester) async {
      await pumpApp(tester, const LogoCreditsScreen());

      // Scroll the whole list so lazily-built rows are laid out, then
      // assert on the widget tree rather than on what fits one screen.
      final rows = tester
          .widgetList<ListTile>(find.byType(ListTile, skipOffstage: false))
          .toList();
      expect(rows.length, BrandLogoManifest.all.length);

      final first = BrandLogoManifest.all.first;
      expect(
        find.text(first.brand, skipOffstage: false),
        findsOneWidget,
        reason: 'the brand a logo depicts names the attribution',
      );
      expect(
        find.textContaining(first.licence, skipOffstage: false),
        findsWidgets,
      );
      expect(
        find.textContaining(first.author, skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('renders each credited logo as its own artwork',
        (tester) async {
      await pumpApp(tester, const LogoCreditsScreen());

      final images = tester
          .widgetList<Image>(find.byType(Image, skipOffstage: false))
          .map((i) => (i.image as AssetImage).assetName)
          .toSet();
      expect(
        images,
        containsAll(BrandLogoManifest.all.map((l) => l.assetPath)),
      );
    });

    testWidgets('states that trademarks belong to their owners',
        (tester) async {
      await pumpApp(tester, const LogoCreditsScreen());

      // The notice is the last card under sixty logo rows, so the lazy
      // ListView has not built it yet — scroll to it rather than assert
      // on the first viewport.
      final notice = find.textContaining(
        'trademarks are the property of their respective owners',
      );
      await tester.scrollUntilVisible(notice, 600);
      expect(notice, findsOneWidget);
    });

    testWidgets('names Wikimedia Commons as the source and says the files '
        'ship with the app', (tester) async {
      await pumpApp(tester, const LogoCreditsScreen());

      expect(
        find.textContaining('Wikimedia Commons', skipOffstage: false),
        findsWidgets,
      );
      expect(
        find.textContaining('nothing is downloaded', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('every source link is an icon-only control with a tooltip',
        (tester) async {
      await pumpApp(tester, const LogoCreditsScreen());

      final buttons = tester
          .widgetList<IconButton>(find.byType(IconButton, skipOffstage: false))
          .toList();
      expect(buttons.length, BrandLogoManifest.all.length);
      for (final button in buttons) {
        expect(button.tooltip, isNotNull);
        expect(button.tooltip, isNotEmpty);
      }
    });
  });
}
