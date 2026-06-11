// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/core/domain/station.dart';

Station _station(String id, double lat, double lng, {double? e10}) => Station(
      id: id,
      name: 'Station $id',
      brand: 'X',
      street: '',
      postCode: '',
      place: '',
      lat: lat,
      lng: lng,
      e10: e10,
      isOpen: true,
    );

FuelStationRadar _radar({
  required CorridorFetch fetchCorridor,
  required PriceFetch fetchPrice,
  required bool isBulk,
}) {
  return FuelStationRadar(
    isBulkSource: isBulk,
    corridorCache: CorridorLocationCache(
      isBulk: isBulk,
      corridorRadiusKm: 60,
      tileStepDegrees: 0.5,
      fetchCorridor: fetchCorridor,
    ),
    priceCache: JitPriceCache(fetchPrice: fetchPrice),
  );
}

void main() {
  group('FuelStationRadar — geofence trigger off the cached corridor', () {
    test('imminent station (inside radius) is JIT-priced; far ones are not',
        () async {
      var priceCalls = 0;
      final radar = _radar(
        isBulk: false,
        fetchCorridor: (lat, lng, r) async => [
          // ~0 m away — inside a 1 km approach radius (imminent).
          _station('NEAR', lat, lng),
          // ~3.3 km north — outside a 1 km radius (corridor-only).
          _station('FAR', lat + 0.03, lng),
        ],
        fetchPrice: (s) async {
          priceCalls++;
          return s.copyWith(e10: 1.789);
        },
      );

      final out = await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      expect(out, hasLength(2));
      final near = out.firstWhere((s) => s.id == 'NEAR');
      final far = out.firstWhere((s) => s.id == 'FAR');
      expect(near.e10, 1.789, reason: 'imminent station gets a JIT price');
      expect(far.e10, isNull, reason: 'far corridor station stays unpriced');
      expect(priceCalls, 1, reason: 'only the imminent station is priced');
    });

    test('a second poll at the same spot reuses the cached corridor + price',
        () async {
      var corridorCalls = 0;
      var priceCalls = 0;
      final radar = _radar(
        isBulk: false,
        fetchCorridor: (lat, lng, r) async {
          corridorCalls++;
          return [_station('NEAR', lat, lng)];
        },
        fetchPrice: (s) async {
          priceCalls++;
          return s.copyWith(e10: 1.5);
        },
      );

      await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      expect(corridorCalls, 1, reason: 'corridor cached across polls');
      expect(priceCalls, 1, reason: 'price deduped within TTL');
    });

    test('no station within the approach radius → no JIT price fetch',
        () async {
      var priceCalls = 0;
      final radar = _radar(
        isBulk: false,
        fetchCorridor: (lat, lng, r) async => [
          _station('FAR', lat + 0.05, lng), // ~5.5 km — outside radius
        ],
        fetchPrice: (s) async {
          priceCalls++;
          return s.copyWith(e10: 1.5);
        },
      );

      final out = await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      expect(out, hasLength(1));
      expect(priceCalls, 0);
    });
  });

  group('FuelStationRadar — bulk-local-filter vs polled-corridor-query', () {
    test('bulk source: prices already in the corridor slice, no JIT fetch',
        () async {
      var corridorCalls = 0;
      var priceCalls = 0;
      final radar = _radar(
        isBulk: true,
        fetchCorridor: (lat, lng, r) async {
          corridorCalls++;
          // Bulk slice already carries the price.
          return [_station('NEAR', lat, lng, e10: 1.659)];
        },
        fetchPrice: (s) async {
          priceCalls++;
          return s.copyWith(e10: 1.0);
        },
      );

      final out = await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      expect(corridorCalls, 1, reason: 'one local-filter over the corridor');
      expect(priceCalls, 0,
          reason: 'bulk price comes from the slice — no JIT round-trip');
      expect(out.single.e10, 1.659);
    });

    test('polled source: one corridor query then JIT price for the imminent',
        () async {
      var corridorCalls = 0;
      var priceCalls = 0;
      final radar = _radar(
        isBulk: false,
        fetchCorridor: (lat, lng, r) async {
          corridorCalls++;
          return [_station('NEAR', lat, lng)]; // location-only from corridor
        },
        fetchPrice: (s) async {
          priceCalls++;
          return s.copyWith(e10: 1.899);
        },
      );

      final out = await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      expect(corridorCalls, 1);
      expect(priceCalls, 1);
      expect(out.single.e10, 1.899);
    });

    test('empty corridor returns empty (detector stays in Polling)', () async {
      final radar = _radar(
        isBulk: false,
        fetchCorridor: (lat, lng, r) async => const [],
        fetchPrice: (s) async => s,
      );
      final out = await radar.fetchStations(48.0, 2.0, 1.0, 'e10');
      expect(out, isEmpty);
    });
  });
}
