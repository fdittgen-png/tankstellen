import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/trip_length_breakdown.dart';

/// Pure value-object tests for [TripLengthBucket] and
/// [TripLengthBreakdown] (#1193 phase 1).
///
/// No mocks, no fakes — these are freezed data holders and the only
/// behaviour to pin is JSON round-trip + value-equality.
void main() {
  group('TripLengthBucket', () {
    test('construct: holds the supplied values verbatim', () {
      const bucket = TripLengthBucket(
        tripCount: 4,
        meanLPer100km: 6.7,
        totalDistanceKm: 120.5,
        totalLitres: 8.07,
      );
      expect(bucket.tripCount, 4);
      expect(bucket.meanLPer100km, 6.7);
      expect(bucket.totalDistanceKm, 120.5);
      expect(bucket.totalLitres, 8.07);
    });

    test('value equality: same fields => equal, hashCode matches', () {
      const a = TripLengthBucket(
        tripCount: 2,
        meanLPer100km: 5.5,
        totalDistanceKm: 30,
        totalLitres: 1.65,
      );
      const b = TripLengthBucket(
        tripCount: 2,
        meanLPer100km: 5.5,
        totalDistanceKm: 30,
        totalLitres: 1.65,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('frozen: copyWith produces a new instance, original untouched', () {
      const original = TripLengthBucket(
        tripCount: 1,
        meanLPer100km: 7.2,
        totalDistanceKm: 12,
        totalLitres: 0.864,
      );
      final updated = original.copyWith(tripCount: 5);
      expect(updated.tripCount, 5);
      expect(original.tripCount, 1);
      expect(updated, isNot(equals(original)));
    });

    test('JSON round-trip preserves equality', () {
      const original = TripLengthBucket(
        tripCount: 17,
        meanLPer100km: 6.83,
        totalDistanceKm: 982.4,
        totalLitres: 67.07,
      );
      final json = original.toJson();
      final restored = TripLengthBucket.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('TripLengthBreakdown', () {
    test('all buckets null is a valid construction', () {
      const empty = TripLengthBreakdown();
      expect(empty.short, isNull);
      expect(empty.medium, isNull);
      expect(empty.long, isNull);
    });

    test('value equality across buckets', () {
      const bucket = TripLengthBucket(
        tripCount: 3,
        meanLPer100km: 6.0,
        totalDistanceKm: 90,
        totalLitres: 5.4,
      );
      const a = TripLengthBreakdown(short: bucket);
      const b = TripLengthBreakdown(short: bucket);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('JSON round-trip with all three buckets populated', () {
      const original = TripLengthBreakdown(
        short: TripLengthBucket(
          tripCount: 12,
          meanLPer100km: 8.4,
          totalDistanceKm: 90.2,
          totalLitres: 7.58,
        ),
        medium: TripLengthBucket(
          tripCount: 7,
          meanLPer100km: 6.1,
          totalDistanceKm: 220.0,
          totalLitres: 13.42,
        ),
        long: TripLengthBucket(
          tripCount: 3,
          meanLPer100km: 5.3,
          totalDistanceKm: 380.5,
          totalLitres: 20.17,
        ),
      );
      final json = original.toJson();
      final restored = TripLengthBreakdown.fromJson(json);
      expect(restored, equals(original));
      expect(restored.short, equals(original.short));
      expect(restored.medium, equals(original.medium));
      expect(restored.long, equals(original.long));
    });

    test('JSON round-trip with sparse buckets (medium null) preserves nulls',
        () {
      const original = TripLengthBreakdown(
        short: TripLengthBucket(
          tripCount: 2,
          meanLPer100km: 9.0,
          totalDistanceKm: 18,
          totalLitres: 1.62,
        ),
        long: TripLengthBucket(
          tripCount: 1,
          meanLPer100km: 5.0,
          totalDistanceKm: 110,
          totalLitres: 5.5,
        ),
      );
      final json = original.toJson();
      final restored = TripLengthBreakdown.fromJson(json);
      expect(restored, equals(original));
      expect(restored.medium, isNull);
    });

    test('JSON round-trip with all buckets null', () {
      const original = TripLengthBreakdown();
      final json = original.toJson();
      final restored = TripLengthBreakdown.fromJson(json);
      expect(restored, equals(original));
    });

    test('cutoff constants match documented values', () {
      // Phase 2 reads these to classify trips. Pin them so an
      // accidental edit (e.g. typo to 0.15 km) trips the tests.
      expect(TripLengthBreakdown.shortMaxKm, 15);
      expect(TripLengthBreakdown.mediumMaxKm, 50);
    });
  });
}
