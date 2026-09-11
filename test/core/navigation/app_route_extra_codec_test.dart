// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/core/navigation/app_route_extra_codec.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';

/// #4061 — every typed `extra` must survive the JSON round-trip go_router
/// performs on state restoration. The device behind the 2026-09-11
/// export was killed 34 times in three days: without this codec the EV
/// payload came back as a Map (#4052) and the fill-up pre-fill as null.
void main() {
  const codec = AppRouteExtraCodec();

  /// The exact path go_router takes: encode → JSON string → decode.
  Object? roundTrip(Object? extra) =>
      codec.decode(jsonDecode(jsonEncode(codec.encode(extra))));

  const station = ChargingStation(
    id: 'ocm-987654',
    name: 'IONITY Pézenas',
    operator: 'IONITY',
    latitude: 43.4672,
    longitude: 3.4242,
    dist: 1.1,
    address: 'A75 Aire de Pézenas',
    postCode: '34120',
    place: 'Pézenas',
    totalPoints: 6,
    isOperational: true,
  );

  test('a ChargingStation comes back as a ChargingStation', () {
    final back = roundTrip(station);
    expect(back, isA<ChargingStation>());
    final s = back! as ChargingStation;
    expect(s.id, station.id);
    expect(s.name, station.name);
    expect(s.latitude, station.latitude);
    expect(s.longitude, station.longitude);
  });

  test('an AddFillUpRoute keeps its pre-fill — the fields the user was '
      'mid-way through', () {
    final back = roundTrip(const AddFillUpRoute(
      stationId: 'de-1',
      stationName: 'Aral Nord',
      pricePerLiter: 1.729,
    ));
    expect(back, isA<AddFillUpRoute>());
    final r = back! as AddFillUpRoute;
    expect(r.stationId, 'de-1');
    expect(r.stationName, 'Aral Nord');
    expect(r.pricePerLiter, 1.729);
    expect(r.fuelType, isNull);
  });

  test('primitives pass through untouched', () {
    expect(roundTrip('vehicle-42'), 'vehicle-42'); // EditVehicleRoute
    expect(roundTrip(1.659), 1.659); // CalculatorRoute
    expect(roundTrip(null), isNull);
  });

  test('an unknown payload encodes to null — what go_router did before, '
      'made explicit rather than thrown', () {
    expect(codec.encode(Object()), isNull);
    expect(() => jsonEncode(codec.encode(Object())), returnsNormally);
  });

  test('a tagged map that no longer decodes yields null, never throws', () {
    expect(
      () => codec.decode({'@extra': 'ChargingStation', 'v': 'garbage'}),
      returnsNormally,
    );
    expect(codec.decode({'@extra': 'ChargingStation', 'v': 'garbage'}), isNull);
  });

  test('an untagged map is passed through (not ours to interpret)', () {
    expect(roundTrip({'k': 1}), {'k': 1});
  });
}
