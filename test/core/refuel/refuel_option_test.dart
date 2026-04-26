import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/refuel_availability.dart';
import 'package:tankstellen/core/refuel/refuel_option.dart';
import 'package:tankstellen/core/refuel/refuel_price.dart';
import 'package:tankstellen/core/refuel/refuel_provider.dart';

/// Concrete subtype of [RefuelOption], kept private to this test file.
///
/// Exists only to verify the abstract contract compiles and the field
/// combinations the documented adapter shapes (`fuel:42`, `ev:abc-123`)
/// can be expressed without further interface surface. **Not** an
/// adapter for any real entity — those are phase 2.
class _TestRefuelOption extends RefuelOption {
  @override
  final ({double lat, double lng}) coordinates;
  @override
  final RefuelPrice? price;
  @override
  final RefuelProvider provider;
  @override
  final RefuelAvailability availability;
  @override
  final String id;

  const _TestRefuelOption({
    required this.coordinates,
    required this.price,
    required this.provider,
    required this.availability,
    required this.id,
  });
}

void main() {
  group('RefuelOption contract', () {
    test('a concrete subtype can express a fuel pump shape', () {
      const o = _TestRefuelOption(
        id: 'fuel:42',
        coordinates: (lat: 48.8566, lng: 2.3522),
        price: RefuelPrice(
          value: 174.5,
          unit: RefuelPriceUnit.centsPerLiter,
        ),
        provider: RefuelProvider(
          name: 'Total',
          kind: RefuelProviderKind.fuel,
        ),
        availability: RefuelAvailability.open,
      );

      expect(o.id, 'fuel:42');
      expect(o.coordinates.lat, 48.8566);
      expect(o.coordinates.lng, 2.3522);
      expect(o.price?.unit, RefuelPriceUnit.centsPerLiter);
      expect(o.provider.kind, RefuelProviderKind.fuel);
      expect(o.availability.isOperational, isTrue);
    });

    test('a concrete subtype can express an EV charger shape', () {
      const o = _TestRefuelOption(
        id: 'ev:abc-123',
        coordinates: (lat: 50.1109, lng: 8.6821),
        price: RefuelPrice(
          value: 39.0,
          unit: RefuelPriceUnit.centsPerKwh,
        ),
        provider: RefuelProvider(
          name: 'Ionity',
          kind: RefuelProviderKind.ev,
        ),
        availability: RefuelAvailability.unknown,
      );

      expect(o.id, 'ev:abc-123');
      expect(o.provider.kind, RefuelProviderKind.ev);
      expect(o.price?.unit, RefuelPriceUnit.centsPerKwh);
      expect(o.availability.isOperational, isFalse);
    });

    test('price may be null when upstream did not report one', () {
      final o = _TestRefuelOption(
        id: 'fuel:no-price',
        coordinates: const (lat: 0.0, lng: 0.0),
        price: null,
        provider: RefuelProvider.unknown,
        availability: RefuelAvailability.closed(reason: 'no data'),
      );
      expect(o.price, isNull);
      expect(o.availability.isOperational, isFalse);
      expect(o.provider, RefuelProvider.unknown);
    });

    test('per-session pricing is expressible (some EV networks)', () {
      const o = _TestRefuelOption(
        id: 'ev:flat-rate',
        coordinates: (lat: 0.0, lng: 0.0),
        price: RefuelPrice(
          value: 1500.0, // 15.00 in main currency unit
          unit: RefuelPriceUnit.perSession,
        ),
        provider: RefuelProvider(
          name: 'Tesla Supercharger',
          kind: RefuelProviderKind.ev,
        ),
        availability: RefuelAvailability.open,
      );

      expect(o.price?.unit, RefuelPriceUnit.perSession);
    });

    test('id format documents the type-prefix convention', () {
      const fuel = _TestRefuelOption(
        id: 'fuel:42',
        coordinates: (lat: 0.0, lng: 0.0),
        price: null,
        provider: RefuelProvider.unknown,
        availability: RefuelAvailability.unknown,
      );
      const ev = _TestRefuelOption(
        id: 'ev:abc-123',
        coordinates: (lat: 0.0, lng: 0.0),
        price: null,
        provider: RefuelProvider.unknown,
        availability: RefuelAvailability.unknown,
      );

      // Mixed-result lists rely on this prefix to dedupe; the
      // prefixes themselves are convention, not enforced by the
      // abstract type — but the test records the documented shape.
      expect(fuel.id.startsWith('fuel:'), isTrue);
      expect(ev.id.startsWith('ev:'), isTrue);
      expect(fuel.id, isNot(equals(ev.id)));
    });
  });
}
