import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

void main() {
  group('VehicleProfile', () {
    test('defaults are sensible', () {
      const v = VehicleProfile(id: 'abc', name: 'Car');
      expect(v.type, VehicleType.combustion);
      expect(v.supportedConnectors, isEmpty);
      expect(v.chargingPreferences.minSocPercent, 20);
      expect(v.chargingPreferences.maxSocPercent, 80);
      expect(v.isCombustion, isTrue);
      expect(v.isEv, isFalse);
    });

    test('hybrid counts as both EV and combustion', () {
      const v = VehicleProfile(id: 'h', name: 'Hybrid', type: VehicleType.hybrid);
      expect(v.isEv, isTrue);
      expect(v.isCombustion, isTrue);
    });

    test('ev profile round-trips through JSON with connector set', () {
      const v = VehicleProfile(
        id: 'tesla',
        name: 'Model 3',
        type: VehicleType.ev,
        batteryKwh: 60.0,
        maxChargingKw: 150.0,
        supportedConnectors: {ConnectorType.ccs, ConnectorType.type2},
        chargingPreferences: ChargingPreferences(
          minSocPercent: 10,
          maxSocPercent: 90,
          preferredNetworks: ['Tesla Supercharger'],
        ),
      );

      final json = v.toJson();
      final restored = VehicleProfile.fromJson(json);

      expect(restored.id, 'tesla');
      expect(restored.name, 'Model 3');
      expect(restored.type, VehicleType.ev);
      expect(restored.batteryKwh, 60.0);
      expect(restored.maxChargingKw, 150.0);
      expect(restored.supportedConnectors,
          {ConnectorType.ccs, ConnectorType.type2});
      expect(restored.chargingPreferences.minSocPercent, 10);
      expect(restored.chargingPreferences.maxSocPercent, 90);
      expect(restored.chargingPreferences.preferredNetworks,
          ['Tesla Supercharger']);
    });

    test('combustion profile round-trips through JSON', () {
      const v = VehicleProfile(
        id: 'golf',
        name: 'Golf',
        type: VehicleType.combustion,
        tankCapacityL: 50.0,
        preferredFuelType: 'Diesel',
      );

      final restored = VehicleProfile.fromJson(v.toJson());
      expect(restored.type, VehicleType.combustion);
      expect(restored.tankCapacityL, 50.0);
      expect(restored.preferredFuelType, 'Diesel');
      expect(restored.supportedConnectors, isEmpty);
    });

    test('unknown connector keys are silently dropped on decode', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'type': 'ev',
        'supportedConnectors': ['ccs', 'unknown_plug', 'type2'],
        'chargingPreferences': const ChargingPreferences().toJson(),
      };
      final restored = VehicleProfile.fromJson(json);
      expect(restored.supportedConnectors,
          {ConnectorType.ccs, ConnectorType.type2});
    });

    group('engine parameters for speed-density fallback (#812)', () {
      test('defaults: no displacement/cylinders, η_v 0.85', () {
        const v = VehicleProfile(id: 'abc', name: 'Car');
        expect(v.engineDisplacementCc, isNull);
        expect(v.engineCylinders, isNull);
        expect(v.volumetricEfficiency, 0.85);
      });

      test('round-trips engine params through JSON — Peugeot 107 case', () {
        const v = VehicleProfile(
          id: 'peugeot-107',
          name: 'Peugeot 107',
          type: VehicleType.combustion,
          engineDisplacementCc: 998,
          engineCylinders: 3,
          volumetricEfficiency: 0.80,
        );
        final restored = VehicleProfile.fromJson(v.toJson());
        expect(restored.engineDisplacementCc, 998);
        expect(restored.engineCylinders, 3);
        expect(restored.volumetricEfficiency, closeTo(0.80, 0.001));
      });

      test('legacy JSON without engine fields still decodes — '
          'backward compat on existing Hive profiles', () {
        // Payload older than #812 — no engine keys at all. Must
        // round-trip cleanly with the defaults filled in.
        final json = {'id': 'old', 'name': 'Old'};
        final v = VehicleProfile.fromJson(json);
        expect(v.engineDisplacementCc, isNull);
        expect(v.engineCylinders, isNull);
        expect(v.volumetricEfficiency, 0.85);
      });

      test('copyWith lets callers update engine params without touching '
          'unrelated fields', () {
        const v = VehicleProfile(
          id: 'x',
          name: 'Corolla',
          type: VehicleType.combustion,
          tankCapacityL: 45,
        );
        final updated = v.copyWith(
          engineDisplacementCc: 1600,
          engineCylinders: 4,
          volumetricEfficiency: 0.88,
        );
        expect(updated.tankCapacityL, 45);
        expect(updated.engineDisplacementCc, 1600);
        expect(updated.engineCylinders, 4);
        expect(updated.volumetricEfficiency, 0.88);
      });
    });

    test('copyWith preserves unspecified fields', () {
      const v = VehicleProfile(
        id: 'a',
        name: 'Old',
        type: VehicleType.ev,
        batteryKwh: 60,
        supportedConnectors: {ConnectorType.ccs},
      );
      final copy = v.copyWith(name: 'New');
      expect(copy.name, 'New');
      expect(copy.batteryKwh, 60);
      expect(copy.supportedConnectors, {ConnectorType.ccs});
    });
  });

  group('VehicleType.fromKey', () {
    test('returns matching value', () {
      expect(VehicleType.fromKey('ev'), VehicleType.ev);
      expect(VehicleType.fromKey('hybrid'), VehicleType.hybrid);
      expect(VehicleType.fromKey('combustion'), VehicleType.combustion);
    });

    test('falls back to combustion for unknown or null', () {
      expect(VehicleType.fromKey(null), VehicleType.combustion);
      expect(VehicleType.fromKey('diesel'), VehicleType.combustion);
    });
  });
}
