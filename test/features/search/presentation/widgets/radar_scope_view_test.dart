// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_scope_view.dart';

import '../../../../helpers/pump_app.dart';

/// Smoke-tests the PPI radar-scope widget (#3342): it paints without throwing
/// and a tap near a blip routes to that station. The sweep animation runs
/// forever, so pumps use `settle: false`.
void main() {
  Station station(String id, double lat, double lng) => Station(
        id: id,
        name: 'Station $id',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '00000',
        place: 'Test',
        lat: lat,
        lng: lng,
        dist: 1,
        isOpen: true,
      );

  testWidgets('paints a scope for nearby stations without throwing',
      (tester) async {
    await pumpApp(
      tester,
      RadarScopeView(
        stations: [station('a', 52.1, 13.0), station('b', 52.0, 13.1)],
        centerLat: 52.0,
        centerLng: 13.0,
        rangeKm: 20,
      ),
      settle: false,
    );

    expect(find.byType(RadarScopeView), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping near a blip invokes onStationTap', (tester) async {
    Station? tapped;
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: RadarScopeView(
            stations: [station('north', 52.1, 13.0)],
            centerLat: 52.0,
            centerLng: 13.0,
            rangeKm: 20,
            onStationTap: (s) => tapped = s,
          ),
        ),
      ),
      settle: false,
    );

    // The single station is due north, so its blip sits above centre. Tapping
    // the upper-middle of the scope should hit it.
    final box = tester.getRect(find.byType(RadarScopeView));
    await tester.tapAt(Offset(box.center.dx, box.top + box.height * 0.30));
    await tester.pump();

    expect(tapped?.id, 'north');
  });

  testWidgets('empty station list still paints', (tester) async {
    await pumpApp(
      tester,
      const RadarScopeView(
        stations: [],
        centerLat: 52.0,
        centerLng: 13.0,
        rangeKm: 20,
      ),
      settle: false,
    );
    expect(tester.takeException(), isNull);
  });
}
