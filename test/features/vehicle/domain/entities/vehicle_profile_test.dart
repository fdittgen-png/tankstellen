import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/speed_consumption_histogram.dart';
import 'package:tankstellen/features/vehicle/domain/entities/trip_length_breakdown.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Unit tests for the pure freezed [VehicleProfile] entity (Refs #561).
///
/// Sister file `test/features/vehicle/domain/vehicle_profile_test.dart`
/// already covers a subset of behaviour (defaults, copyWith, engine
/// params, auto-record). This file targets the enum `fromKey` factories,
/// the [VehicleProfile.isEv] / [VehicleProfile.isCombustion] getters and
/// the all-fields round-trip path that `lcov` reported as zero-coverage.
void main() {
  group('VehicleType.fromKey', () {
    test('returns combustion when value is null', () {
      expect(VehicleType.fromKey(null), VehicleType.combustion);
    });

    test('returns matching enum for each known key', () {
      expect(VehicleType.fromKey('combustion'), VehicleType.combustion);
      expect(VehicleType.fromKey('hybrid'), VehicleType.hybrid);
      expect(VehicleType.fromKey('ev'), VehicleType.ev);
    });

    test('returns combustion for unknown or empty key', () {
      expect(VehicleType.fromKey(''), VehicleType.combustion);
      expect(VehicleType.fromKey('diesel'), VehicleType.combustion);
      expect(VehicleType.fromKey('PHEV'), VehicleType.combustion);
      // Case-sensitive — capitalised keys are unknown.
      expect(VehicleType.fromKey('EV'), VehicleType.combustion);
    });
  });

  group('VehicleCalibrationMode.fromKey', () {
    test('returns rule when value is null', () {
      expect(VehicleCalibrationMode.fromKey(null), VehicleCalibrationMode.rule);
    });

    test('returns matching enum for each known key', () {
      expect(
        VehicleCalibrationMode.fromKey('rule'),
        VehicleCalibrationMode.rule,
      );
      expect(
        VehicleCalibrationMode.fromKey('fuzzy'),
        VehicleCalibrationMode.fuzzy,
      );
    });

    test('returns rule for unknown or empty key', () {
      expect(VehicleCalibrationMode.fromKey(''), VehicleCalibrationMode.rule);
      expect(
        VehicleCalibrationMode.fromKey('FUZZY'),
        VehicleCalibrationMode.rule,
      );
      expect(
        VehicleCalibrationMode.fromKey('hybrid'),
        VehicleCalibrationMode.rule,
      );
    });
  });

  group('ConnectorType.fromKey', () {
    test('returns null when value is null', () {
      expect(ConnectorType.fromKey(null), isNull);
    });

    test('returns matching enum for each known key', () {
      expect(ConnectorType.fromKey('type2'), ConnectorType.type2);
      expect(ConnectorType.fromKey('ccs'), ConnectorType.ccs);
      expect(ConnectorType.fromKey('chademo'), ConnectorType.chademo);
      expect(ConnectorType.fromKey('tesla'), ConnectorType.tesla);
      expect(ConnectorType.fromKey('schuko'), ConnectorType.schuko);
      expect(ConnectorType.fromKey('type1'), ConnectorType.type1);
      expect(ConnectorType.fromKey('three_pin'), ConnectorType.threePin);
    });

    test('returns null for unknown or empty key', () {
      expect(ConnectorType.fromKey(''), isNull);
      expect(ConnectorType.fromKey('mennekes'), isNull);
      // Case-sensitive — display labels are NOT keys.
      expect(ConnectorType.fromKey('Type 2'), isNull);
      expect(ConnectorType.fromKey('CCS'), isNull);
    });
  });

  group('VehicleProfile.isEv / isCombustion getters', () {
    test('combustion: isCombustion true, isEv false', () {
      const v = VehicleProfile(
        id: 'c',
        name: 'Combustion',
      );
      expect(v.isCombustion, isTrue);
      expect(v.isEv, isFalse);
    });

    test('ev: isCombustion false, isEv true', () {
      const v = VehicleProfile(
        id: 'e',
        name: 'EV',
        type: VehicleType.ev,
      );
      expect(v.isCombustion, isFalse);
      expect(v.isEv, isTrue);
    });

    test('hybrid: both isCombustion and isEv are true', () {
      // Hybrids are intentionally inclusive in both lenses so they can
      // be filtered by EV connector and still surface combustion-fuel
      // savings (#896 product leitmotiv: pump + wheel).
      const v = VehicleProfile(
        id: 'h',
        name: 'Hybrid',
        type: VehicleType.hybrid,
      );
      expect(v.isCombustion, isTrue);
      expect(v.isEv, isTrue);
    });
  });

  group('VehicleProfile.fromJson / toJson round-trip', () {
    test('all fields populated round-trip preserves equality', () {
      const original = VehicleProfile(
        id: 'full-profile',
        name: 'Fully Populated',
        type: VehicleType.hybrid,
        // EV fields
        batteryKwh: 75.5,
        maxChargingKw: 250.0,
        supportedConnectors: {
          ConnectorType.ccs,
          ConnectorType.type2,
          ConnectorType.chademo,
        },
        chargingPreferences: ChargingPreferences(
          minSocPercent: 15,
          maxSocPercent: 85,
          preferredNetworks: ['Ionity', 'Fastned'],
        ),
        // Combustion fields
        tankCapacityL: 55.0,
        preferredFuelType: 'Super E10',
        // Engine parameters
        engineDisplacementCc: 1598,
        engineCylinders: 4,
        volumetricEfficiency: 0.87,
        volumetricEfficiencySamples: 12,
        curbWeightKg: 1450,
        // OBD2 pairing
        obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
        obd2AdapterName: 'vLinker FS',
        // VIN
        vin: 'WVWZZZ1JZXW000001',
        // Calibration
        calibrationMode: VehicleCalibrationMode.fuzzy,
        // Auto-record
        autoRecord: true,
        pairedAdapterMac: '11:22:33:44:55:66',
        movementStartThresholdKmh: 7.5,
        disconnectSaveDelaySec: 90,
        backgroundLocationConsent: true,
        // Reference catalog
        make: 'Volkswagen',
        model: 'Golf',
        year: 2019,
        referenceVehicleId: 'volkswagen-golf-vii-2019',
      );

      final json = original.toJson();
      final restored = VehicleProfile.fromJson(json);

      expect(restored, equals(original));
      // Spot-check a few values that go through custom converters so a
      // future refactor that breaks one converter still trips this test.
      expect(restored.type, VehicleType.hybrid);
      expect(restored.calibrationMode, VehicleCalibrationMode.fuzzy);
      expect(
        restored.supportedConnectors,
        {
          ConnectorType.ccs,
          ConnectorType.type2,
          ConnectorType.chademo,
        },
      );
      expect(restored.chargingPreferences.preferredNetworks,
          ['Ionity', 'Fastned']);
    });

    test('toJson stores type as string key (not enum index)', () {
      const v = VehicleProfile(
        id: 'k',
        name: 'KeyCheck',
        type: VehicleType.ev,
        calibrationMode: VehicleCalibrationMode.fuzzy,
      );
      final json = v.toJson();
      expect(json['type'], 'ev');
      expect(json['calibrationMode'], 'fuzzy');
    });

    test('toJson stores supportedConnectors as list of string keys', () {
      const v = VehicleProfile(
        id: 's',
        name: 'SetCheck',
        type: VehicleType.ev,
        supportedConnectors: {ConnectorType.ccs, ConnectorType.threePin},
      );
      final json = v.toJson();
      final connectors = json['supportedConnectors'] as List<dynamic>;
      expect(
        connectors.cast<String>(),
        containsAll(<String>['ccs', 'three_pin']),
      );
      expect(connectors.length, 2);
    });
  });

  group('VehicleProfile aggregate fields (#1193 phase 1)', () {
    test('round-trip with all four new fields populated preserves equality',
        () {
      final updatedAt = DateTime.utc(2026, 4, 27, 9, 30);
      final original = VehicleProfile(
        id: 'agg-profile',
        name: 'AggProfile',
        type: VehicleType.combustion,
        tripLengthAggregates: const TripLengthBreakdown(
          short: TripLengthBucket(
            tripCount: 8,
            meanLPer100km: 9.4,
            totalDistanceKm: 64,
            totalLitres: 6.02,
          ),
          medium: TripLengthBucket(
            tripCount: 4,
            meanLPer100km: 6.8,
            totalDistanceKm: 132,
            totalLitres: 8.98,
          ),
          long: TripLengthBucket(
            tripCount: 2,
            meanLPer100km: 5.4,
            totalDistanceKm: 240,
            totalLitres: 12.96,
          ),
        ),
        speedConsumptionAggregates: const SpeedConsumptionHistogram(
          bands: <SpeedBand>[
            SpeedBand(
              minKmh: 0,
              maxKmh: 30,
              sampleCount: 200,
              meanLPer100km: 12.1,
              timeShareFraction: 0.18,
            ),
            SpeedBand(
              minKmh: 110,
              maxKmh: null,
              sampleCount: 50,
              meanLPer100km: 7.6,
              timeShareFraction: 0.12,
            ),
          ],
        ),
        aggregatesUpdatedAt: updatedAt,
        aggregatesTripCount: 14,
      );

      final json = original.toJson();
      final restored = VehicleProfile.fromJson(json);

      expect(restored, equals(original));
      expect(restored.tripLengthAggregates, equals(original.tripLengthAggregates));
      expect(
        restored.speedConsumptionAggregates,
        equals(original.speedConsumptionAggregates),
      );
      expect(restored.aggregatesUpdatedAt, equals(updatedAt));
      expect(restored.aggregatesTripCount, 14);
    });

    test('round-trip with all four new fields null preserves equality '
        '(backwards compat)', () {
      const original = VehicleProfile(id: 'no-agg', name: 'NoAgg');
      // Explicit null for clarity even though they default to null.
      expect(original.tripLengthAggregates, isNull);
      expect(original.speedConsumptionAggregates, isNull);
      expect(original.aggregatesUpdatedAt, isNull);
      expect(original.aggregatesTripCount, isNull);

      final json = original.toJson();
      final restored = VehicleProfile.fromJson(json);

      expect(restored, equals(original));
      expect(restored.tripLengthAggregates, isNull);
      expect(restored.speedConsumptionAggregates, isNull);
      expect(restored.aggregatesUpdatedAt, isNull);
      expect(restored.aggregatesTripCount, isNull);
    });

    test('legacy JSON without aggregate keys deserializes with nulls', () {
      // Pre-#1193 Hive payloads simply omit the new keys. freezed's
      // nullable factory parameters must surface them as null rather
      // than throwing during fromJson.
      final json = <String, dynamic>{
        'id': 'legacy',
        'name': 'Legacy',
        'type': 'combustion',
      };
      final restored = VehicleProfile.fromJson(json);
      expect(restored.tripLengthAggregates, isNull);
      expect(restored.speedConsumptionAggregates, isNull);
      expect(restored.aggregatesUpdatedAt, isNull);
      expect(restored.aggregatesTripCount, isNull);
    });
  });

  group('VehicleProfile gear-inference fields (#1263 phase 2)', () {
    test('default profile carries tireCircumferenceMeters = 1.95 and '
        'gearCentroids null', () {
      const v = VehicleProfile(id: 'fresh', name: 'Fresh');
      expect(v.tireCircumferenceMeters, 1.95);
      expect(v.gearCentroids, isNull);
    });

    test('round-trip with custom tireCircumferenceMeters preserves value', () {
      const original = VehicleProfile(
        id: 'tyre',
        name: 'Custom Tyre',
        tireCircumferenceMeters: 2.05,
      );
      final json = original.toJson();
      final restored = VehicleProfile.fromJson(json);
      expect(restored.tireCircumferenceMeters, 2.05);
      expect(restored, equals(original));
    });

    test('round-trip with populated gearCentroids preserves the list', () {
      const original = VehicleProfile(
        id: 'centroids',
        name: 'WithCentroids',
        gearCentroids: <double>[12.5, 8.4, 6.1, 4.8, 3.7],
      );
      final json = original.toJson();
      final restored = VehicleProfile.fromJson(json);
      expect(restored.gearCentroids, [12.5, 8.4, 6.1, 4.8, 3.7]);
      expect(restored, equals(original));
    });

    test('round-trip with gearCentroids null preserves null', () {
      const original = VehicleProfile(id: 'nullc', name: 'NullCentroids');
      final json = original.toJson();
      final restored = VehicleProfile.fromJson(json);
      expect(restored.gearCentroids, isNull);
    });

    test('legacy JSON without tireCircumferenceMeters / gearCentroids '
        'deserializes with documented defaults', () {
      // Pre-#1263 Hive payloads simply omit the new keys. freezed's
      // `@Default` and nullable factory parameters must surface them
      // safely rather than throwing during fromJson.
      final json = <String, dynamic>{
        'id': 'legacy-1263',
        'name': 'LegacyProfile',
        'type': 'combustion',
      };
      final restored = VehicleProfile.fromJson(json);
      expect(restored.tireCircumferenceMeters, 1.95);
      expect(restored.gearCentroids, isNull);
    });
  });

  group('ChargingPreferences', () {
    test('defaults match documented values', () {
      const prefs = ChargingPreferences();
      expect(prefs.minSocPercent, 20);
      expect(prefs.maxSocPercent, 80);
      expect(prefs.preferredNetworks, isEmpty);
    });

    test('fromJson / toJson round-trip with all fields populated', () {
      const original = ChargingPreferences(
        minSocPercent: 25,
        maxSocPercent: 95,
        preferredNetworks: ['Ionity', 'Tesla Supercharger', 'Fastned'],
      );

      final json = original.toJson();
      final restored = ChargingPreferences.fromJson(json);

      expect(restored, equals(original));
      expect(restored.minSocPercent, 25);
      expect(restored.maxSocPercent, 95);
      expect(restored.preferredNetworks,
          ['Ionity', 'Tesla Supercharger', 'Fastned']);
    });

    test('fromJson with empty map fills documented defaults', () {
      // freezed's `@Default` is what makes legacy Hive payloads safe —
      // pinning the behaviour so a refactor that drops the defaults
      // breaks loudly.
      final restored = ChargingPreferences.fromJson(<String, dynamic>{});
      expect(restored.minSocPercent, 20);
      expect(restored.maxSocPercent, 80);
      expect(restored.preferredNetworks, isEmpty);
    });

    test('fromJson preserves preferred network order', () {
      // Order matters for the UI — first network in the list is the
      // user's primary preference. List equality is order-sensitive in
      // Dart, which is what we want here.
      final json = <String, dynamic>{
        'minSocPercent': 10,
        'maxSocPercent': 90,
        'preferredNetworks': <String>['B', 'A', 'C'],
      };
      final restored = ChargingPreferences.fromJson(json);
      expect(restored.preferredNetworks, ['B', 'A', 'C']);
    });
  });
}
