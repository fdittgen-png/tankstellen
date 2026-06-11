// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/fuel_price_fields.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// #2864 — the background alert evaluator used a DE-only e5/e10/diesel switch
/// (`tankerkoenigKeyFor`). It is now the per-country [priceFieldKeyForCountry],
/// gated by each country's published fuel set, so an alert on a fuel a country
/// actually exposes (FR LPG/E85, IT CNG, AR diesel-premium) resolves to its
/// price field and can fire — while DE's three grades resolve byte-identically.
void main() {
  group('priceFieldKeyFor — raw FuelType → price-map key', () {
    test('DE-historical grades keep their exact keys', () {
      expect(priceFieldKeyFor(FuelType.e5), 'e5');
      expect(priceFieldKeyFor(FuelType.e10), 'e10');
      expect(priceFieldKeyFor(FuelType.diesel), 'diesel');
    });

    test('widened grades map to the shape adapter keys', () {
      expect(priceFieldKeyFor(FuelType.e98), 'e98');
      // The map carries diesel-premium as camelCase, not its snake_case
      // apiValue — reading by apiValue would silently miss it.
      expect(priceFieldKeyFor(FuelType.dieselPremium), 'dieselPremium');
      expect(priceFieldKeyFor(FuelType.e85), 'e85');
      expect(priceFieldKeyFor(FuelType.lpg), 'lpg');
      expect(priceFieldKeyFor(FuelType.cng), 'cng');
    });

    test('fuels with no feed price field map to null', () {
      expect(priceFieldKeyFor(FuelType.electric), isNull);
      expect(priceFieldKeyFor(FuelType.hydrogen), isNull);
      expect(priceFieldKeyFor(FuelType.all), isNull);
    });
  });

  group('priceFieldKeyForCountry — gated by the country fuel set', () {
    test('DE e5/e10/diesel resolve unchanged', () {
      expect(priceFieldKeyForCountry(FuelType.e5, 'DE'), 'e5');
      expect(priceFieldKeyForCountry(FuelType.e10, 'DE'), 'e10');
      expect(priceFieldKeyForCountry(FuelType.diesel, 'DE'), 'diesel');
    });

    test('DE does NOT resolve LPG / CNG (not in its feed)', () {
      // The DE Tankerkönig feed has no LPG/CNG, so a DE-derived LPG alert must
      // not spuriously match the (absent) lpg field.
      expect(priceFieldKeyForCountry(FuelType.lpg, 'DE'), isNull);
      expect(priceFieldKeyForCountry(FuelType.cng, 'DE'), isNull);
    });

    test('France resolves a non-DE fuel (LPG + E85)', () {
      // FR's published set includes LPG (GPLc) and E85 — the original gap the
      // DE-only switch could never fire on.
      expect(priceFieldKeyForCountry(FuelType.lpg, 'FR'), 'lpg');
      expect(priceFieldKeyForCountry(FuelType.e85, 'FR'), 'e85');
      expect(priceFieldKeyForCountry(FuelType.e98, 'FR'), 'e98');
    });

    test('Italy resolves CNG (Metano)', () {
      expect(priceFieldKeyForCountry(FuelType.cng, 'IT'), 'cng');
      // IT's feed has no E85, so an IT E85 alert finds no field.
      expect(priceFieldKeyForCountry(FuelType.e85, 'IT'), isNull);
    });

    test('Argentina resolves diesel-premium (Gas Oil premium)', () {
      expect(
          priceFieldKeyForCountry(FuelType.dieselPremium, 'AR'),
          'dieselPremium');
      expect(priceFieldKeyForCountry(FuelType.cng, 'AR'), 'cng');
    });

    test('Electric never resolves to a price field, even where supported', () {
      // FR supports EV in its fuel set, but EV has no price-feed field.
      expect(priceFieldKeyForCountry(FuelType.electric, 'FR'), isNull);
    });
  });
}
