// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/brand_appearance.dart';
import 'package:tankstellen/core/providers/privacy_controls_provider.dart';
import 'package:tankstellen/core/widgets/brand_logo.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('BrandLogo', () {
    testWidgets('shows fallback icon for unknown brand', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: 'UnknownBrand'));

      // Should show generic fuel pump icon
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      // Should not attempt to load a network image
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows fallback icon for empty brand', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: ''));

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('#3930 — an EV caller gets the charging glyph, not a pump, '
        'for an unrecognised network', (tester) async {
      await pumpApp(
        tester,
        const BrandLogo(brand: 'UnknownNetwork123', kind: BrandKind.ev),
      );

      expect(find.byIcon(Icons.ev_station), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsNothing);
    });

    testWidgets('#3870 — internet logos are OFF by default: a known brand '
        'renders the bundled mark and touches no network', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: 'Shell'));

      expect(find.byType(CachedNetworkImage), findsNothing,
          reason: 'logo.clearbit.com must not see the user\'s IP unless '
              'the Settings → Privacy switch is on');
      // #3930 — and it is no longer the grey pump box every brand shared:
      // Shell's own yellow with its monogram.
      expect(find.byIcon(Icons.local_gas_station), findsNothing);
      expect(find.text('SH'), findsOneWidget);
    });

    testWidgets('#3930 — the mark paints the brand colour with a computed '
        'contrasting monogram', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: 'Aral'));

      final appearance = BrandAppearance.of('Aral')!;
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BrandLogo),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (container.decoration as BoxDecoration).color,
        appearance.background,
      );

      final text = tester.widget<Text>(find.text('AR'));
      expect(text.style?.color, appearance.foreground);
      expect(appearance.contrastRatio, greaterThanOrEqualTo(4.5));
    });

    testWidgets('#3931 — an EV network resolved through the registry gets '
        'its own mark', (tester) async {
      await pumpApp(
        tester,
        const BrandLogo(brand: 'IONITY', kind: BrandKind.ev),
      );

      expect(find.text('IO'), findsOneWidget);
      expect(find.byIcon(Icons.ev_station), findsNothing);
    });

    testWidgets('uses a disk-cached network image for a known brand once '
        'the user switched internet logos on', (tester) async {
      await pumpApp(
        tester,
        const BrandLogo(brand: 'Shell'),
        overrides: [
          remoteBrandLogosProvider.overrideWith(() => _RemoteLogosOn()),
        ],
      );

      // #1761 — the logo loads through CachedNetworkImage (disk cache +
      // decode-at-size), not a bare Image.network.
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: '', size: 64));

      // The fallback container should be 64x64
      final renderBox =
          tester.renderObject<RenderBox>(find.byType(Container).first);
      expect(renderBox.size.width, 64);
      expect(renderBox.size.height, 64);
    });

    testWidgets('uses ClipRRect for known brand', (tester) async {
      await pumpApp(
        tester,
        const BrandLogo(brand: 'ARAL'),
        overrides: [
          remoteBrandLogosProvider.overrideWith(() => _RemoteLogosOn()),
        ],
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('default size is 48', (tester) async {
      await pumpApp(tester, const BrandLogo(brand: ''));

      final renderBox =
          tester.renderObject<RenderBox>(find.byType(Container).first);
      expect(renderBox.size.width, 48);
      expect(renderBox.size.height, 48);
    });

    // #1687 — the logo previously carried no Semantics; a screen reader
    // announced nothing for the brand graphic on every station card.
    testWidgets('exposes an image semantic label naming the brand',
        (tester) async {
      await pumpApp(
        tester,
        const BrandLogo(brand: 'Shell'),
        overrides: [
          remoteBrandLogosProvider.overrideWith(() => _RemoteLogosOn()),
        ],
      );

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(BrandLogo),
              matching: find.byType(Semantics),
            ),
          )
          .first;
      expect(semantics.properties.label, contains('Shell'));
      expect(semantics.properties.image, isTrue);
    });

    testWidgets('fallback-icon path is still labelled', (tester) async {
      // Unknown brand → fallback icon, but the label must remain.
      await pumpApp(tester, const BrandLogo(brand: 'UnknownBrand'));

      final semantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(BrandLogo),
              matching: find.byType(Semantics),
            ),
          )
          .first;
      expect(semantics.properties.label, contains('UnknownBrand'));
      expect(semantics.properties.image, isTrue);
    });

    // #3930 — a brandless station used to announce "  logo". The neutral
    // tile now says what it actually depicts, per caller kind.
    testWidgets('a blank brand announces what the neutral tile depicts',
        (tester) async {
      await pumpApp(tester, const BrandLogo(brand: ''));
      expect(_labelOf(tester), 'Fuel station');
    });

    testWidgets('a blank charging network announces the charging label',
        (tester) async {
      await pumpApp(tester, const BrandLogo(brand: '', kind: BrandKind.ev));
      expect(_labelOf(tester), 'Charging point');
    });
  });
}

String? _labelOf(WidgetTester tester) => tester
    .widgetList<Semantics>(
      find.descendant(
        of: find.byType(BrandLogo),
        matching: find.byType(Semantics),
      ),
    )
    .first
    .properties
    .label;

/// #3870 — the switch flipped on, without touching storage.
class _RemoteLogosOn extends RemoteBrandLogos {
  @override
  bool build() => true;
}
