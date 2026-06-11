// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2922 — the OSM brand enricher could stamp a neighbouring supermarket's fuel
// POI ("Super U") onto a different station because its nearest-POI attribution
// used a loose 0.2 km radius and never guarded ambiguity. That phantom brand
// was then serialized into the cached Station and served on every hit until a
// manual app-data clear. These tests pin the hardened attribution:
//   * a real upstream brand is NEVER overwritten by a POI;
//   * a far POI does not attribute a brand;
//   * an ambiguous (two-equally-close POIs) match does not attribute a brand;
//   * a single, close, unambiguous POI still attributes correctly.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/osm_brand_enricher.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../fakes/fake_hive_storage.dart';

void main() {
  // ~111 km per degree of latitude near the equator/mid-latitudes; small
  // offsets here translate cleanly to the metre scale the radius works in.
  // 0.0005° lat ≈ 55 m (inside the 80 m radius); 0.0020° lat ≈ 222 m (outside).
  const stationLat = 48.8000;
  const stationLng = 2.3000;

  group('OsmBrandEnricher.attributeBrandPoi (#2922 hardening)', () {
    test('attributes a single close, unambiguous POI', () {
      final pois = [OsmPoi('TotalEnergies', stationLat + 0.0005, stationLng)];
      final hit =
          OsmBrandEnricher.attributeBrandPoi(stationLat, stationLng, pois);
      expect(hit, isNotNull);
      expect(hit!.name, 'TotalEnergies');
    });

    test('does NOT attribute a POI that is too far (the loose-radius bug)', () {
      // ~133 m away (0.0012° lat): INSIDE the old 0.2 km radius — which is
      // exactly how the adjacent "Super U" supermarket fuel point got stamped
      // onto a different station — but OUTSIDE the tightened 80 m radius.
      // This boundary case is RED with the old 0.2 km radius, green with 0.08.
      final pois = [OsmPoi('Super U', stationLat + 0.0012, stationLng)];
      final hit =
          OsmBrandEnricher.attributeBrandPoi(stationLat, stationLng, pois);
      expect(hit, isNull,
          reason: 'a 133 m POI must not be stamped onto this station — '
              'the old 0.2 km radius wrongly accepted it');
    });

    test('does NOT attribute when two POIs are similarly close (ambiguous)', () {
      // Two fuel POIs, both close, within the ambiguity margin of each other:
      // no confident winner → leave the station for a clearer later signal.
      final pois = [
        OsmPoi('Super U', stationLat + 0.0003, stationLng),
        OsmPoi('Carrefour', stationLat + 0.00035, stationLng),
      ];
      final hit =
          OsmBrandEnricher.attributeBrandPoi(stationLat, stationLng, pois);
      expect(hit, isNull,
          reason: 'two equally-close fuel POIs are ambiguous — do not guess');
    });

    test('attributes the clear winner when a second POI is comfortably '
        'farther', () {
      final pois = [
        OsmPoi('Esso', stationLat + 0.0002, stationLng), // ~22 m
        OsmPoi('Super U', stationLat + 0.0007, stationLng), // ~78 m
      ];
      final hit =
          OsmBrandEnricher.attributeBrandPoi(stationLat, stationLng, pois);
      expect(hit, isNotNull);
      expect(hit!.name, 'Esso',
          reason: 'the nearest is well clear of the runner-up — unambiguous');
    });

    test('returns null for no POIs', () {
      expect(OsmBrandEnricher.attributeBrandPoi(stationLat, stationLng, const []),
          isNull);
    });
  });

  group('OsmBrandEnricher.enrich — never overwrites a real upstream brand '
      '(#2922)', () {
    late FakeHiveStorage fakeStorage;
    late OsmBrandEnricher enricher;

    setUp(() {
      fakeStorage = FakeHiveStorage();
      enricher = OsmBrandEnricher(fakeStorage);
    });

    Station station(String id, String brand) => Station(
          id: id,
          name: 'Station $id',
          brand: brand,
          street: 'Test St',
          postCode: '75001',
          place: 'Paris',
          lat: stationLat,
          lng: stationLng,
          isOpen: true,
        );

    test('a station with a real upstream brand is returned unchanged even '
        'when a phantom brand is persisted for its id', () async {
      // Simulate a poisoned persisted entry that, before #2922, the apply path
      // would have layered on. A station carrying a REAL upstream brand must
      // never be overwritten by it.
      await fakeStorage.putSetting('brand_1', 'Super U');

      final result = await enricher.enrich([station('1', 'TotalEnergies')]);

      expect(result.single.brand, 'TotalEnergies',
          reason: 'a real upstream brand is authoritative — never overwritten');
    });
  });
}
