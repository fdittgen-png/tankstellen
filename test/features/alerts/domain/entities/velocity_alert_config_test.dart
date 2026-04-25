import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/entities/velocity_alert_config.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('VelocityAlertConfig', () {
    test('defaults() returns E10 with the spec thresholds', () {
      final config = VelocityAlertConfig.defaults();

      expect(config.fuelType, FuelType.e10);
      expect(config.minDropCents, 3);
      expect(config.minStations, 2);
      expect(config.radiusKm, 15);
      expect(config.cooldownHours, 6);
    });

    test('constructor with custom values overrides defaults', () {
      const config = VelocityAlertConfig(
        fuelType: FuelType.diesel,
        minDropCents: 5,
        minStations: 4,
        radiusKm: 25,
        cooldownHours: 12,
      );

      expect(config.fuelType, FuelType.diesel);
      expect(config.minDropCents, 5);
      expect(config.minStations, 4);
      expect(config.radiusKm, 25);
      expect(config.cooldownHours, 12);
    });

    test('copyWith updates each field independently', () {
      final base = VelocityAlertConfig.defaults();

      final fuelChanged = base.copyWith(fuelType: FuelType.e5);
      expect(fuelChanged.fuelType, FuelType.e5);
      expect(fuelChanged.minDropCents, base.minDropCents);
      expect(fuelChanged.minStations, base.minStations);
      expect(fuelChanged.radiusKm, base.radiusKm);
      expect(fuelChanged.cooldownHours, base.cooldownHours);

      final dropChanged = base.copyWith(minDropCents: 7.5);
      expect(dropChanged.minDropCents, 7.5);
      expect(dropChanged.fuelType, base.fuelType);
      expect(dropChanged.minStations, base.minStations);

      final stationsChanged = base.copyWith(minStations: 5);
      expect(stationsChanged.minStations, 5);
      expect(stationsChanged.fuelType, base.fuelType);
      expect(stationsChanged.minDropCents, base.minDropCents);

      final radiusChanged = base.copyWith(radiusKm: 30);
      expect(radiusChanged.radiusKm, 30);
      expect(radiusChanged.fuelType, base.fuelType);
      expect(radiusChanged.cooldownHours, base.cooldownHours);

      final cooldownChanged = base.copyWith(cooldownHours: 1);
      expect(cooldownChanged.cooldownHours, 1);
      expect(cooldownChanged.fuelType, base.fuelType);
      expect(cooldownChanged.radiusKm, base.radiusKm);
    });

    test('equality compares by value, not identity', () {
      final a = VelocityAlertConfig.defaults();
      final b = VelocityAlertConfig.defaults();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = a.copyWith(minDropCents: 4);
      expect(a, isNot(equals(c)));
      expect(a.hashCode, isNot(equals(c.hashCode)));

      final d = a.copyWith(fuelType: FuelType.diesel);
      expect(a, isNot(equals(d)));
    });

    test('toJson / fromJson round-trips default config', () {
      final original = VelocityAlertConfig.defaults();
      final restored = VelocityAlertConfig.fromJson(original.toJson());

      expect(restored, equals(original));
      expect(restored.fuelType, FuelType.e10);
      expect(restored.minDropCents, 3);
      expect(restored.minStations, 2);
      expect(restored.radiusKm, 15);
      expect(restored.cooldownHours, 6);
    });

    test('toJson / fromJson round-trips a non-default config', () {
      const original = VelocityAlertConfig(
        fuelType: FuelType.diesel,
        minDropCents: 4.5,
        minStations: 3,
        radiusKm: 20,
        cooldownHours: 8,
      );

      final restored = VelocityAlertConfig.fromJson(original.toJson());

      expect(restored, equals(original));
      expect(restored.fuelType, FuelType.diesel);
      expect(restored.minDropCents, 4.5);
      expect(restored.minStations, 3);
      expect(restored.radiusKm, 20);
      expect(restored.cooldownHours, 8);
    });

    test('FuelTypeJsonConverter serialises fuelType as apiValue string', () {
      const config = VelocityAlertConfig(fuelType: FuelType.dieselPremium);
      final json = config.toJson();

      expect(json['fuelType'], isA<String>());
      expect(json['fuelType'], FuelType.dieselPremium.apiValue);
      expect(json['fuelType'], 'diesel_premium');

      final restored = VelocityAlertConfig.fromJson(json);
      expect(restored.fuelType, FuelType.dieselPremium);
    });

    test('fromJson applies field defaults when keys are omitted', () {
      final json = <String, dynamic>{'fuelType': 'e10'};

      final config = VelocityAlertConfig.fromJson(json);
      expect(config.fuelType, FuelType.e10);
      expect(config.minDropCents, 3);
      expect(config.minStations, 2);
      expect(config.radiusKm, 15);
      expect(config.cooldownHours, 6);
    });
  });
}
