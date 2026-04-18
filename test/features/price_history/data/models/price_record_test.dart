import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';

void main() {
  group('PriceRecord — construction', () {
    test('stores all eight fuel-type prices plus identity fields', () {
      final recordedAt = DateTime.utc(2026, 4, 18, 10, 30);
      final record = PriceRecord(
        stationId: 'de-tk-abc-123',
        recordedAt: recordedAt,
        e5: 1.739,
        e10: 1.679,
        e98: 1.899,
        diesel: 1.619,
        dieselPremium: 1.699,
        e85: 1.199,
        lpg: 0.899,
        cng: 1.189,
      );
      expect(record.stationId, 'de-tk-abc-123');
      expect(record.recordedAt, recordedAt);
      expect(record.e5, 1.739);
      expect(record.e10, 1.679);
      expect(record.e98, 1.899);
      expect(record.diesel, 1.619);
      expect(record.dieselPremium, 1.699);
      expect(record.e85, 1.199);
      expect(record.lpg, 0.899);
      expect(record.cng, 1.189);
    });

    test('optional fuel prices default to null when omitted', () {
      // Realistic: most stations only publish a subset of fuel types.
      final record = PriceRecord(
        stationId: 's1',
        recordedAt: DateTime.utc(2026, 1, 1),
        e5: 1.80,
      );
      expect(record.e5, 1.80);
      expect(record.e10, isNull);
      expect(record.e98, isNull);
      expect(record.diesel, isNull);
      expect(record.dieselPremium, isNull);
      expect(record.e85, isNull);
      expect(record.lpg, isNull);
      expect(record.cng, isNull);
    });
  });

  group('PriceRecord — value equality', () {
    test('two records with identical fields are equal', () {
      final t = DateTime.utc(2026, 2, 14, 12);
      final a = PriceRecord(stationId: 'x', recordedAt: t, e5: 1.5);
      final b = PriceRecord(stationId: 'x', recordedAt: t, e5: 1.5);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('records differing in one price are not equal', () {
      final t = DateTime.utc(2026, 2, 14, 12);
      final a = PriceRecord(stationId: 'x', recordedAt: t, e5: 1.50);
      final b = PriceRecord(stationId: 'x', recordedAt: t, e5: 1.51);
      expect(a, isNot(equals(b)));
    });
  });

  group('PriceRecord — copyWith', () {
    test('copyWith(diesel:) only changes the diesel field', () {
      final t = DateTime.utc(2026, 3, 1);
      final original = PriceRecord(
        stationId: 's',
        recordedAt: t,
        e5: 1.70,
        diesel: 1.60,
      );
      final updated = original.copyWith(diesel: 1.55);
      expect(updated.stationId, 's');
      expect(updated.recordedAt, t);
      expect(updated.e5, 1.70);
      expect(updated.diesel, 1.55);
    });
  });

  group('PriceRecord — JSON round-trip', () {
    test('fromJson(toJson(x)) == x for a fully-populated record', () {
      // PriceRecord is cached to Hive as JSON, so the round-trip must be
      // lossless — otherwise historical charts would drift after reload.
      final original = PriceRecord(
        stationId: 'fr-px-42',
        recordedAt: DateTime.utc(2026, 4, 1, 8, 30),
        e5: 1.789,
        e10: 1.729,
        diesel: 1.659,
        lpg: 0.949,
      );
      final decoded = PriceRecord.fromJson(original.toJson());
      expect(decoded, equals(original));
    });

    test('fromJson handles records with only stationId + recordedAt', () {
      final json = {
        'stationId': 's',
        'recordedAt': DateTime.utc(2026, 4, 18).toIso8601String(),
      };
      final decoded = PriceRecord.fromJson(json);
      expect(decoded.stationId, 's');
      expect(decoded.e5, isNull);
      expect(decoded.diesel, isNull);
    });
  });
}
