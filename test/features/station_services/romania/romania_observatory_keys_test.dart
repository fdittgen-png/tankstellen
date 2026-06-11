// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/romania/romania_observatory_keys.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// Unit tests for [RomaniaObservatoryKeys] (#3193).
///
/// The catalog ids are pinned against the live
/// `GET /pmonsvc/Gas/GetGasProductsFromCatalog` response recorded
/// 2026-06-10 (see the class docstring for the full payload).
void main() {
  group('RomaniaObservatoryKeys.lookup', () {
    test('maps the five live catalog product ids', () {
      expect(RomaniaObservatoryKeys.lookup('11'), FuelType.e5);
      expect(RomaniaObservatoryKeys.lookup('12'), FuelType.e98);
      expect(RomaniaObservatoryKeys.lookup('21'), FuelType.diesel);
      expect(RomaniaObservatoryKeys.lookup('22'), FuelType.dieselPremium);
      expect(RomaniaObservatoryKeys.lookup('31'), FuelType.lpg);
    });

    test('EV charging (41) is intentionally unmapped — OCM owns electric',
        () {
      expect(RomaniaObservatoryKeys.lookup('41'), isNull);
    });

    test('unknown ids return null', () {
      expect(RomaniaObservatoryKeys.lookup('99'), isNull);
      expect(RomaniaObservatoryKeys.lookup(''), isNull);
      expect(RomaniaObservatoryKeys.lookup('benzina_standard'), isNull);
    });

    test('tolerates surrounding whitespace', () {
      expect(RomaniaObservatoryKeys.lookup(' 11 '), FuelType.e5);
    });

    test('exactly five ids are mapped (catalog completeness pin)', () {
      expect(RomaniaObservatoryKeys.fuelForCatalogProductId, hasLength(5));
    });
  });

  group('RomaniaObservatoryKeys.parseLeiPerLitre', () {
    test('accepts positive numbers', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(7.259), 7.259);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(9), 9.0);
    });

    test('accepts numeric strings', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('7.45'), 7.45);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(' 8.88 '), 8.88);
    });

    test('rejects zero, negative, junk and null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(0), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(-1.5), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('N/A'), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(''), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(null), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(<String>[]), isNull);
    });
  });
}
