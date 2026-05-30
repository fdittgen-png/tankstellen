// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/widgets/osm_attribution.dart';

import '../../helpers/pump_app.dart';

/// #2402 — the OpenStreetMap tile attribution wrapper now comes from the
/// `mapAttributionOsm` ARB key. The "OpenStreetMap" brand stays a literal
/// (i18n-ignore), so it must survive verbatim in every locale's rendered
/// credit while the surrounding wording localizes.
void main() {
  Future<void> pumpInMap(WidgetTester tester, {required Locale locale}) async {
    await pumpApp(
      tester,
      const FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(48.0, 2.0),
          initialZoom: 10,
        ),
        children: [OsmAttribution()],
      ),
      locale: locale,
    );
  }

  TextSourceAttribution readSource(WidgetTester tester) {
    final widget = tester.widget<RichAttributionWidget>(
      find.byType(RichAttributionWidget),
    );
    expect(widget.attributions, hasLength(1));
    return widget.attributions.single as TextSourceAttribution;
  }

  group('OsmAttribution', () {
    testWidgets('renders the English wrapper with the brand intact',
        (tester) async {
      await pumpInMap(tester, locale: const Locale('en'));

      expect(find.byType(RichAttributionWidget), findsOneWidget);
      final source = readSource(tester);
      expect(source.text, '© OpenStreetMap contributors');
    });

    testWidgets('renders the German wrapper with the brand intact',
        (tester) async {
      await pumpInMap(tester, locale: const Locale('de'));

      final source = readSource(tester);
      // German localizes the wrapper but keeps the OpenStreetMap brand.
      expect(source.text, '© OpenStreetMap-Mitwirkende');
      expect(source.text, contains('OpenStreetMap'));
    });

    testWidgets('renders the French wrapper with the brand intact',
        (tester) async {
      await pumpInMap(tester, locale: const Locale('fr'));

      final source = readSource(tester);
      expect(source.text, '© les contributeurs OpenStreetMap');
      expect(source.text, contains('OpenStreetMap'));
    });
  });

  group('osmAttributionText', () {
    testWidgets('composes the localized wrapper around the literal brand',
        (tester) async {
      late String resolved;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            resolved = osmAttributionText(context);
            return const SizedBox();
          },
        ),
        locale: const Locale('de'),
      );

      expect(resolved, '© OpenStreetMap-Mitwirkende');
      expect(resolved, contains('OpenStreetMap'));
    });
  });
}
