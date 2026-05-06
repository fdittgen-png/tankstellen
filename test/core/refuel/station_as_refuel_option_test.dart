import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/refuel_availability.dart';
import 'package:tankstellen/core/refuel/refuel_price.dart';
import 'package:tankstellen/core/refuel/refuel_provider.dart';
import 'package:tankstellen/core/refuel/station_as_refuel_option.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Build a [Station] with all required fields stubbed and only the
/// fields each test cares about overridden. Keeps the test cases small
/// and intent-focused.
Station _station({
  String id = '42',
  String brand = 'Total',
  String street = 'rue de Test',
  String postCode = '75001',
  String place = 'Paris',
  double lat = 48.8566,
  double lng = 2.3522,
  double dist = 0,
  double? e5,
  double? e10,
  double? e98,
  double? diesel,
  double? dieselPremium,
  double? e85,
  double? lpg,
  double? cng,
  bool isOpen = true,
  bool is24h = false,
  String? updatedAt,
}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: brand,
      street: street,
      postCode: postCode,
      place: place,
      lat: lat,
      lng: lng,
      dist: dist,
      e5: e5,
      e10: e10,
      e98: e98,
      diesel: diesel,
      dieselPremium: dieselPremium,
      e85: e85,
      lpg: lpg,
      cng: cng,
      isOpen: isOpen,
      is24h: is24h,
      updatedAt: updatedAt,
    );

void main() {
  group('StationAsRefuelOption — identity & provider', () {
    test('coordinates pass through from station.lat/lng', () {
      final adapter = StationAsRefuelOption(
        _station(lat: 50.1109, lng: 8.6821),
      );
      expect(adapter.coordinates.lat, 50.1109);
      expect(adapter.coordinates.lng, 8.6821);
    });

    test('id uses the "fuel:" type prefix', () {
      final adapter = StationAsRefuelOption(_station(id: 'abc-123'));
      expect(adapter.id, 'fuel:abc-123');
    });

    test('provider wraps the brand with kind=fuel', () {
      final adapter = StationAsRefuelOption(_station(brand: 'Esso'));
      expect(
        adapter.provider,
        const RefuelProvider(name: 'Esso', kind: RefuelProviderKind.fuel),
      );
    });

    test('empty brand collapses to RefuelProvider.unknown', () {
      final adapter = StationAsRefuelOption(_station(brand: ''));
      expect(adapter.provider, RefuelProvider.unknown);
    });
  });

  group('StationAsRefuelOption — price by fuel type', () {
    test('FuelType.e5 reads station.e5, multiplies by 100, cents/L', () {
      final adapter = StationAsRefuelOption(
        _station(e5: 1.749),
        FuelType.e5,
      );
      final price = adapter.price!;
      expect(price.value, 174.9);
      expect(price.unit, RefuelPriceUnit.centsPerLiter);
    });

    test('FuelType.e10 (default) reads station.e10', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699),
      );
      expect(adapter.price?.value, 169.9);
    });

    test('FuelType.e98 reads station.e98', () {
      final adapter = StationAsRefuelOption(
        _station(e98: 1.899),
        FuelType.e98,
      );
      expect(adapter.price?.value, 189.9);
    });

    test('FuelType.diesel reads station.diesel', () {
      final adapter = StationAsRefuelOption(
        _station(diesel: 1.659),
        FuelType.diesel,
      );
      expect(adapter.price?.value, 165.9);
    });

    test('FuelType.dieselPremium reads station.dieselPremium', () {
      final adapter = StationAsRefuelOption(
        _station(dieselPremium: 1.799),
        FuelType.dieselPremium,
      );
      expect(adapter.price?.value, 179.9);
    });

    test('FuelType.e85 reads station.e85', () {
      final adapter = StationAsRefuelOption(
        _station(e85: 0.899),
        FuelType.e85,
      );
      expect(adapter.price?.value, 89.9);
    });

    test('FuelType.lpg reads station.lpg', () {
      final adapter = StationAsRefuelOption(
        _station(lpg: 0.999),
        FuelType.lpg,
      );
      expect(adapter.price?.value, 99.9);
    });

    test('FuelType.cng reads station.cng (tagged centsPerLiter — see doc)',
        () {
      final adapter = StationAsRefuelOption(
        _station(cng: 1.299),
        FuelType.cng,
      );
      final price = adapter.price!;
      expect(price.value, 129.9);
      // The CNG `Station` field is EUR-per-pump-unit — see adapter doc.
      expect(price.unit, RefuelPriceUnit.centsPerLiter);
    });

    test('null fuel field on station → null price', () {
      final adapter = StationAsRefuelOption(
        _station(), // all fuel fields null
        FuelType.e10,
      );
      expect(adapter.price, isNull);
    });

    test('FuelType.electric → null price (Station has no kWh field)', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699), // even when other fields are populated
        FuelType.electric,
      );
      expect(adapter.price, isNull);
    });

    test('FuelType.hydrogen → null price (Station has no H2 field)', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699),
        FuelType.hydrogen,
      );
      expect(adapter.price, isNull);
    });

    test('FuelType.all (meta wildcard) → falls back to e10 price '
        '(#1116 phase 5)', () {
      // Phase 5: a station with at least one fuel field set must
      // surface in the unified all-fuels view. The fallback chain
      // prefers e10 (most common in EU); see the dedicated phase-5
      // group below for the full ordering matrix.
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699),
        FuelType.all,
      );
      expect(adapter.price?.value, 169.9);
    });

    test('IEEE-754 float drift is stripped (0.1-cent precision)', () {
      // 1.749 EUR/L * 100 == 174.90000000000003 in raw float math.
      // The adapter strips that drift and exposes the displayed cents
      // value (174.9) the user actually sees on the totem.
      final adapter = StationAsRefuelOption(
        _station(e10: 1.749),
      );
      expect(adapter.price?.value, 174.9);
    });
  });

  group('StationAsRefuelOption — availability', () {
    test('isOpen=true → open', () {
      final adapter = StationAsRefuelOption(_station(isOpen: true));
      expect(adapter.availability, RefuelAvailability.open);
      expect(adapter.availability.isOperational, isTrue);
    });

    test('is24h=true → open even when isOpen=false', () {
      final adapter = StationAsRefuelOption(
        _station(isOpen: false, is24h: true),
      );
      expect(adapter.availability, RefuelAvailability.open);
    });

    test('isOpen=false and is24h=false → closed', () {
      final adapter = StationAsRefuelOption(
        _station(isOpen: false, is24h: false),
      );
      expect(adapter.availability, isA<RefuelAvailability>());
      expect(adapter.availability.isOperational, isFalse);
      expect(adapter.availability, RefuelAvailability.closed());
    });
  });

  group('StationAsRefuelOption — lastUpdated parsing', () {
    test('valid ISO-8601 updatedAt is parsed into DateTime', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699, updatedAt: '2026-04-26T10:15:30Z'),
      );
      expect(
        adapter.price?.lastUpdated,
        DateTime.parse('2026-04-26T10:15:30Z'),
      );
    });

    test('null updatedAt → null lastUpdated', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699, updatedAt: null),
      );
      expect(adapter.price?.lastUpdated, isNull);
    });

    test('empty updatedAt → null lastUpdated', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699, updatedAt: ''),
      );
      expect(adapter.price?.lastUpdated, isNull);
    });

    test('garbage updatedAt → null lastUpdated (no throw)', () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.699, updatedAt: 'not-a-date'),
      );
      expect(adapter.price?.lastUpdated, isNull);
    });
  });

  group('StationAsRefuelOption — phase 4 enrichment (#1116)', () {
    test('address composes "<street>, <postCode> <place>"', () {
      final adapter = StationAsRefuelOption(
        _station(
          street: '12 Rue de la Paix',
          postCode: '75002',
          place: 'Paris',
        ),
      );
      expect(adapter.address, '12 Rue de la Paix, 75002 Paris');
    });

    test('address falls back to street alone when city parts are empty',
        () {
      final adapter = StationAsRefuelOption(
        _station(street: 'Hauptstraße 5', postCode: '', place: ''),
      );
      expect(adapter.address, 'Hauptstraße 5');
    });

    test('address falls back to "<postCode> <place>" when no street', () {
      final adapter = StationAsRefuelOption(
        _station(street: '', postCode: '34540', place: 'Castelnau'),
      );
      expect(adapter.address, '34540 Castelnau');
    });

    test('distanceMeters converts station.dist (km) to metres', () {
      final adapter = StationAsRefuelOption(_station(dist: 1.25));
      expect(adapter.distanceMeters, 1250.0);
    });

    test('distanceMeters is null when station.dist is the freezed '
        'default 0', () {
      final adapter = StationAsRefuelOption(_station(dist: 0));
      expect(adapter.distanceMeters, isNull);
    });

    test('is24h passes through from the underlying station', () {
      expect(StationAsRefuelOption(_station(is24h: true)).is24h, isTrue);
      expect(StationAsRefuelOption(_station(is24h: false)).is24h, isFalse);
    });

    test('lastUpdated parses station.updatedAt into a DateTime', () {
      final adapter = StationAsRefuelOption(
        _station(updatedAt: '2026-05-04T08:30:00Z'),
      );
      expect(adapter.lastUpdated, DateTime.parse('2026-05-04T08:30:00Z'));
    });

    test('lastUpdated is null when updatedAt is missing or unparseable',
        () {
      expect(
        StationAsRefuelOption(_station(updatedAt: null)).lastUpdated,
        isNull,
      );
      expect(
        StationAsRefuelOption(_station(updatedAt: '')).lastUpdated,
        isNull,
      );
      expect(
        StationAsRefuelOption(_station(updatedAt: 'garbage')).lastUpdated,
        isNull,
      );
    });

    test('source returns the wrapped Station', () {
      final s = _station(id: 'abc');
      final adapter = StationAsRefuelOption(s);
      expect(adapter.source, same(s));
    });
  });

  group('StationAsRefuelOption — phase 5 all-fuels fallback (#1116)', () {
    test('FuelType.all + e10 set returns the e10 price (preferred fallback)',
        () {
      final adapter = StationAsRefuelOption(
        _station(e10: 1.749, e5: 1.799, diesel: 1.659),
        FuelType.all,
      );
      expect(adapter.price?.value, 174.9);
    });

    test('FuelType.all + only diesel set returns the diesel price', () {
      final adapter = StationAsRefuelOption(
        _station(e10: null, e5: null, diesel: 1.659),
        FuelType.all,
      );
      expect(adapter.price?.value, 165.9);
    });

    test('FuelType.all + only e85 set returns the e85 price (rare path)',
        () {
      final adapter = StationAsRefuelOption(
        _station(e10: null, e5: null, diesel: null, e85: 0.799),
        FuelType.all,
      );
      expect(adapter.price?.value, 79.9);
    });

    test('FuelType.all + every fuel null returns null price', () {
      final adapter = StationAsRefuelOption(
        _station(e5: null, e10: null, diesel: null),
        FuelType.all,
      );
      expect(adapter.price, isNull);
    });

    test('FuelType.e10 fallback does NOT trigger when fuelType is specific',
        () {
      // With e10 explicitly null and FuelType.e10 selected, we must
      // return null (the user asked for e10 specifically). The
      // all-fuels fallback only kicks in for FuelType.all.
      final adapter = StationAsRefuelOption(
        _station(e10: null, e5: 1.799, diesel: 1.659),
        FuelType.e10,
      );
      expect(adapter.price, isNull);
    });
  });
}
