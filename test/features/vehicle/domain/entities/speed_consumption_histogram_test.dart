import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/speed_consumption_histogram.dart';

/// Pure value-object tests for [SpeedBand] and
/// [SpeedConsumptionHistogram] (#1193 phase 1).
void main() {
  group('SpeedBand', () {
    test('construct: holds the supplied values, including null maxKmh', () {
      const band = SpeedBand(
        minKmh: 110,
        maxKmh: null,
        sampleCount: 84,
        meanLPer100km: 7.8,
        timeShareFraction: 0.22,
      );
      expect(band.minKmh, 110);
      expect(band.maxKmh, isNull);
      expect(band.sampleCount, 84);
      expect(band.meanLPer100km, 7.8);
      expect(band.timeShareFraction, 0.22);
    });

    test('value equality: same fields => equal', () {
      const a = SpeedBand(
        minKmh: 50,
        maxKmh: 80,
        sampleCount: 12,
        meanLPer100km: 5.4,
        timeShareFraction: 0.35,
      );
      const b = SpeedBand(
        minKmh: 50,
        maxKmh: 80,
        sampleCount: 12,
        meanLPer100km: 5.4,
        timeShareFraction: 0.35,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('frozen: copyWith produces a new instance, original untouched', () {
      const original = SpeedBand(
        minKmh: 30,
        maxKmh: 50,
        sampleCount: 3,
        meanLPer100km: 6.1,
        timeShareFraction: 0.1,
      );
      final updated = original.copyWith(sampleCount: 4);
      expect(updated.sampleCount, 4);
      expect(original.sampleCount, 3);
      expect(updated, isNot(equals(original)));
    });

    test('JSON round-trip with finite max preserves equality', () {
      const original = SpeedBand(
        minKmh: 0,
        maxKmh: 30,
        sampleCount: 250,
        meanLPer100km: 11.4,
        timeShareFraction: 0.18,
      );
      final json = original.toJson();
      final restored = SpeedBand.fromJson(json);
      expect(restored, equals(original));
    });

    test('JSON round-trip with null maxKmh (open-ended top band)', () {
      const original = SpeedBand(
        minKmh: 110,
        maxKmh: null,
        sampleCount: 31,
        meanLPer100km: 8.9,
        timeShareFraction: 0.07,
      );
      final json = original.toJson();
      expect(json['maxKmh'], isNull);
      final restored = SpeedBand.fromJson(json);
      expect(restored, equals(original));
      expect(restored.maxKmh, isNull);
    });
  });

  group('SpeedConsumptionHistogram', () {
    test('default empty histogram has empty bands list', () {
      const empty = SpeedConsumptionHistogram();
      expect(empty.bands, isEmpty);
    });

    test('value equality across populated bands', () {
      const a = SpeedConsumptionHistogram(
        bands: <SpeedBand>[
          SpeedBand(
            minKmh: 0,
            maxKmh: 30,
            sampleCount: 10,
            meanLPer100km: 12,
            timeShareFraction: 0.5,
          ),
          SpeedBand(
            minKmh: 30,
            maxKmh: 50,
            sampleCount: 8,
            meanLPer100km: 7,
            timeShareFraction: 0.5,
          ),
        ],
      );
      const b = SpeedConsumptionHistogram(
        bands: <SpeedBand>[
          SpeedBand(
            minKmh: 0,
            maxKmh: 30,
            sampleCount: 10,
            meanLPer100km: 12,
            timeShareFraction: 0.5,
          ),
          SpeedBand(
            minKmh: 30,
            maxKmh: 50,
            sampleCount: 8,
            meanLPer100km: 7,
            timeShareFraction: 0.5,
          ),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('JSON round-trip with full standard band layout', () {
      const original = SpeedConsumptionHistogram(
        bands: <SpeedBand>[
          SpeedBand(
            minKmh: 0,
            maxKmh: 30,
            sampleCount: 200,
            meanLPer100km: 13.2,
            timeShareFraction: 0.14,
          ),
          SpeedBand(
            minKmh: 30,
            maxKmh: 50,
            sampleCount: 410,
            meanLPer100km: 8.7,
            timeShareFraction: 0.28,
          ),
          SpeedBand(
            minKmh: 50,
            maxKmh: 80,
            sampleCount: 530,
            meanLPer100km: 6.4,
            timeShareFraction: 0.36,
          ),
          SpeedBand(
            minKmh: 80,
            maxKmh: 110,
            sampleCount: 220,
            meanLPer100km: 5.9,
            timeShareFraction: 0.15,
          ),
          SpeedBand(
            minKmh: 110,
            maxKmh: null,
            sampleCount: 95,
            meanLPer100km: 7.3,
            timeShareFraction: 0.07,
          ),
        ],
      );
      final json = original.toJson();
      final restored = SpeedConsumptionHistogram.fromJson(json);
      expect(restored, equals(original));
      expect(restored.bands.length, 5);
      expect(restored.bands.last.maxKmh, isNull);

      // Time shares roll up to ~1.0 (modulo float rounding) — pin so a
      // future test-data tweak that breaks this invariant trips.
      final total = restored.bands
          .map((b) => b.timeShareFraction)
          .fold<double>(0, (a, b) => a + b);
      expect(total, closeTo(1.0, 0.0001));
    });

    test('JSON round-trip with empty bands (cold-start state)', () {
      const original = SpeedConsumptionHistogram();
      final json = original.toJson();
      final restored = SpeedConsumptionHistogram.fromJson(json);
      expect(restored, equals(original));
      expect(restored.bands, isEmpty);
    });

    test('standardBandTemplate matches documented layout', () {
      // Pin the canonical layout that the phase-2 aggregator instantiates
      // from. Order matters because the consumer iterates left-to-right.
      expect(
        SpeedConsumptionHistogram.standardBandTemplate,
        const <(int, int?)>[
          (0, 30),
          (30, 50),
          (50, 80),
          (80, 110),
          (110, null),
        ],
      );
    });
  });
}
