// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_detail_parser.dart';

void main() {
  group('stationFromDetail', () {
    test('builds a coord-less station from the detail Morada (no cached row)',
        () {
      final station = PortugalDetailParser.stationFromDetail(
        stationId: 'pt-1',
        numericId: '1',
        resultado: const {
          'Nome': 'RECHEIO Portimão',
          'Marca': 'RECHEIO',
          'Morada': {
            'Morada': 'Sítio do Poço Fojo',
            'Localidade': 'Portimão',
            'CodPostal': '8500-998',
          },
        },
        cachedSearchRow: null,
      );
      expect(station.id, 'pt-1');
      expect(station.name, 'RECHEIO Portimão');
      expect(station.street, 'Sítio do Poço Fojo');
      expect(station.postCode, '8500-998');
      expect(station.place, 'Portimão');
      expect(station.lat, 0);
    });

    test('overlays detail name/brand/address onto the cached search row', () {
      const cached = Station(
        id: 'pt-1',
        name: 'old',
        brand: 'old',
        street: 'old',
        postCode: '0000-000',
        place: 'old',
        lat: 38.7,
        lng: -9.1,
        e5: 1.7,
        isOpen: true,
      );
      final station = PortugalDetailParser.stationFromDetail(
        stationId: 'pt-1',
        numericId: '1',
        resultado: const {
          'Nome': 'GALP Lisboa',
          'Marca': 'GALP',
          'Morada': {'Morada': 'Rua X', 'Localidade': 'Lisboa'},
        },
        cachedSearchRow: cached,
      );
      expect(station.name, 'GALP Lisboa');
      expect(station.street, 'Rua X');
      expect(station.lat, 38.7); // coords preserved from cache
      expect(station.e5, 1.7); // price preserved from cache
    });

    // Fault-injection (#2349): a malformed `Morada` (a String, not the nested
    // object the live feed sends, or a missing key) must return normally —
    // never propagate a cast error to the detail screen.
    test('a String Morada returns normally (no nested-map cast crash)', () {
      expect(
        () => PortugalDetailParser.stationFromDetail(
          stationId: 'pt-1',
          numericId: '1',
          resultado: const {'Nome': 'X', 'Morada': 'a plain string address'},
          cachedSearchRow: null,
        ),
        returnsNormally,
      );
    });

    test('an entirely empty resultado returns normally', () {
      expect(
        () => PortugalDetailParser.stationFromDetail(
          stationId: 'pt-1',
          numericId: '1',
          resultado: const {},
          cachedSearchRow: null,
        ),
        returnsNormally,
      );
    });
  });

  group('cachedSearchRow', () {
    List<Station> fakeParse(
      List<dynamic> resultado, {
      required double lat,
      required double lng,
      required double radiusKm,
    }) =>
        [
          const Station(
            id: 'pt-7',
            name: 'GALP',
            brand: 'GALP',
            street: '',
            postCode: '',
            place: '',
            lat: 38.7,
            lng: -9.1,
            isOpen: true,
          ),
        ];

    test('returns the matching rebuilt station from the cached dataset', () {
      final station = PortugalDetailParser.cachedSearchRow(
        '7',
        const [
          {'Id': 7, 'Latitude': 38.7, 'Longitude': -9.1},
        ],
        fakeParse,
      );
      expect(station?.id, 'pt-7');
    });

    test('null when the dataset is not cached', () {
      expect(
        PortugalDetailParser.cachedSearchRow('7', null, fakeParse),
        isNull,
      );
    });

    test('null when the id is not in the dataset', () {
      expect(
        PortugalDetailParser.cachedSearchRow(
          '999',
          const [
            {'Id': 7, 'Latitude': 38.7, 'Longitude': -9.1},
          ],
          fakeParse,
        ),
        isNull,
      );
    });
  });
}
