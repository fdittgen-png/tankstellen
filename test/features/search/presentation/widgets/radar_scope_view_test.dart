// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_scope_view.dart';

import '../../../../helpers/pump_app.dart';

/// Smoke-tests the PPI radar-scope widget (#3342/#3354): it paints price chips
/// without throwing, a tap near a chip routes to that station, and the heading
/// rotates placement. The sweep animation runs forever, so pumps use
/// `settle: false`.
void main() {
  Station station(String id, double lat, double lng, {double? e10}) => Station(
        id: id,
        name: 'Station $id',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '00000',
        place: 'Test',
        lat: lat,
        lng: lng,
        dist: 1,
        e10: e10,
        isOpen: true,
      );

  testWidgets('paints a scope for nearby priced stations without throwing',
      (tester) async {
    await pumpApp(
      tester,
      RadarScopeView(
        stations: [
          station('a', 52.1, 13.0, e10: 1.799),
          station('b', 52.0, 13.1, e10: 1.659),
        ],
        centerLat: 52.0,
        centerLng: 13.0,
        rangeKm: 20,
        fuelType: FuelType.e10,
      ),
      settle: false,
    );

    expect(find.byType(RadarScopeView), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping near a chip invokes onStationTap (North-up)',
      (tester) async {
    Station? tapped;
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: RadarScopeView(
            stations: [station('north', 52.1, 13.0, e10: 1.799)],
            centerLat: 52.0,
            centerLng: 13.0,
            rangeKm: 20,
            fuelType: FuelType.e10,
            onStationTap: (s) => tapped = s,
          ),
        ),
      ),
      settle: false,
    );

    // Due north + no heading → North-up → chip sits above centre.
    final box = tester.getRect(find.byType(RadarScopeView));
    await tester.tapAt(Offset(box.center.dx, box.top + box.height * 0.32));
    await tester.pump();

    expect(tapped?.id, 'north');
  });

  testWidgets('heading-up: driving east puts a due-north station on the LEFT',
      (tester) async {
    Station? tapped;
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: RadarScopeView(
            stations: [station('north', 52.1, 13.0, e10: 1.799)],
            centerLat: 52.0,
            centerLng: 13.0,
            rangeKm: 20,
            fuelType: FuelType.e10,
            // No compass override in tests → falls back to this GPS course.
            gpsCourseDeg: 90, // driving east → North rotates to the left
            onStationTap: (s) => tapped = s,
          ),
        ),
      ),
      settle: false,
    );

    final box = tester.getRect(find.byType(RadarScopeView));
    // The due-north station should now be on the left half, vertically centred.
    await tester.tapAt(Offset(box.left + box.width * 0.18, box.center.dy));
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
        fuelType: FuelType.e10,
      ),
      settle: false,
    );
    expect(tester.takeException(), isNull);
  });
}
