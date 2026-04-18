import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('PriceAlert — construction', () {
    test('stores identity, target, and metadata fields', () {
      final created = DateTime.utc(2026, 3, 1, 8, 0);
      final alert = PriceAlert(
        id: 'alert-1',
        stationId: 'de-tk-99',
        stationName: 'Shell Berlin-Mitte',
        fuelType: FuelType.e10,
        targetPrice: 1.599,
        createdAt: created,
      );
      expect(alert.id, 'alert-1');
      expect(alert.stationId, 'de-tk-99');
      expect(alert.stationName, 'Shell Berlin-Mitte');
      expect(alert.fuelType, FuelType.e10);
      expect(alert.targetPrice, 1.599);
      expect(alert.createdAt, created);
    });

    test('isActive defaults to true (new alert should fire)', () {
      // A freshly-created alert that starts disabled would silently never
      // notify — pin the default so that misconfiguration is loud.
      final alert = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.diesel,
        targetPrice: 1.5,
        createdAt: DateTime.utc(2026),
      );
      expect(alert.isActive, isTrue);
    });

    test('lastTriggeredAt defaults to null (never fired)', () {
      final alert = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.diesel,
        targetPrice: 1.5,
        createdAt: DateTime.utc(2026),
      );
      expect(alert.lastTriggeredAt, isNull);
    });
  });

  group('PriceAlert — copyWith', () {
    test('copyWith(isActive: false) disables without touching other fields',
        () {
      final created = DateTime.utc(2026, 1, 1);
      final original = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.e5,
        targetPrice: 1.6,
        createdAt: created,
      );
      final disabled = original.copyWith(isActive: false);
      expect(disabled.isActive, isFalse);
      expect(disabled.id, 'x');
      expect(disabled.targetPrice, 1.6);
      expect(disabled.createdAt, created);
    });

    test('copyWith(lastTriggeredAt:) records the fire timestamp', () {
      final original = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.e5,
        targetPrice: 1.6,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final triggered = DateTime.utc(2026, 1, 2, 14, 30);
      final updated = original.copyWith(lastTriggeredAt: triggered);
      expect(updated.lastTriggeredAt, triggered);
    });
  });

  group('PriceAlert — JSON round-trip', () {
    test('fromJson(toJson(x)) == x for a fully-populated alert', () {
      // Alerts are Hive-cached and pushed to Supabase; any silent drift
      // on reload would resurrect stale alerts with wrong thresholds.
      final original = PriceAlert(
        id: 'alert-42',
        stationId: 'de-tk-1',
        stationName: 'Aral Alexanderplatz',
        fuelType: FuelType.diesel,
        targetPrice: 1.499,
        isActive: false,
        lastTriggeredAt: DateTime.utc(2026, 3, 15, 6, 45),
        createdAt: DateTime.utc(2026, 3, 1),
      );
      final decoded = PriceAlert.fromJson(original.toJson());
      expect(decoded, equals(original));
    });

    test('fromJson handles minimal payload (no lastTriggeredAt)', () {
      final json = {
        'id': 'x',
        'stationId': 's',
        'stationName': 'n',
        'fuelType': 'e10',
        'targetPrice': 1.65,
        'createdAt': DateTime.utc(2026).toIso8601String(),
      };
      final alert = PriceAlert.fromJson(json);
      expect(alert.lastTriggeredAt, isNull);
      expect(alert.isActive, isTrue);
      expect(alert.fuelType, FuelType.e10);
    });
  });

  group('PriceAlert — value equality', () {
    test('equal alerts compare equal and hash identically', () {
      final t = DateTime.utc(2026, 4, 1);
      final a = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.e10,
        targetPrice: 1.6,
        createdAt: t,
      );
      final b = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.e10,
        targetPrice: 1.6,
        createdAt: t,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different targetPrice breaks equality', () {
      final t = DateTime.utc(2026, 4, 1);
      final a = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.e10,
        targetPrice: 1.60,
        createdAt: t,
      );
      final b = PriceAlert(
        id: 'x',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.e10,
        targetPrice: 1.61,
        createdAt: t,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
