import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/station_service.dart';

void main() {
  group('StationPrices', () {
    test('constructor keeps every field including nulls', () {
      const p = StationPrices(
        e5: 1.859,
        e10: null,
        diesel: 1.659,
        status: 'open',
      );
      expect(p.e5, closeTo(1.859, 0.0001));
      expect(p.e10, isNull);
      expect(p.diesel, closeTo(1.659, 0.0001));
      expect(p.status, 'open');
    });

    test('isOpen is true only for status == "open"', () {
      expect(
        const StationPrices(status: 'open').isOpen,
        isTrue,
      );
      expect(
        const StationPrices(status: 'closed').isOpen,
        isFalse,
      );
      // Defensive: any other string is treated as not-open.
      expect(
        const StationPrices(status: 'maintenance').isOpen,
        isFalse,
      );
    });
  });

  group('StationPrices.toJson', () {
    test('serialises every field', () {
      const p = StationPrices(
        e5: 1.859,
        e10: 1.799,
        diesel: 1.659,
        status: 'open',
      );
      expect(p.toJson(), {
        'e5': 1.859,
        'e10': 1.799,
        'diesel': 1.659,
        'status': 'open',
      });
    });

    test('preserves nulls in the output map (explicit absence)', () {
      const p = StationPrices(e5: 1.8, status: 'closed');
      final json = p.toJson();
      expect(json['e5'], 1.8);
      expect(json['e10'], isNull);
      expect(json['diesel'], isNull);
      expect(json['status'], 'closed');
    });
  });

  group('StationPrices.fromJson', () {
    test('round-trips with every field set', () {
      final json = {
        'e5': 1.859,
        'e10': 1.799,
        'diesel': 1.659,
        'status': 'open',
      };
      final p = StationPrices.fromJson(json);
      expect(p.e5, closeTo(1.859, 0.0001));
      expect(p.e10, closeTo(1.799, 0.0001));
      expect(p.diesel, closeTo(1.659, 0.0001));
      expect(p.status, 'open');
    });

    test('null price values map to null on the model', () {
      final p = StationPrices.fromJson({
        'e5': null,
        'e10': null,
        'diesel': null,
        'status': 'closed',
      });
      expect(p.e5, isNull);
      expect(p.e10, isNull);
      expect(p.diesel, isNull);
    });

    test('integer prices from APIs are coerced to doubles', () {
      // Some APIs emit `1.6` as the integer `2` after rounding, or
      // bare ints for round prices. Defend against both cases.
      final p = StationPrices.fromJson({
        'e5': 2,
        'status': 'open',
      });
      expect(p.e5, 2.0);
    });

    test('non-numeric price fields become null rather than throwing', () {
      // The defensive `json[x] is num ? ... : null` path — matters
      // because historical Hive caches occasionally held `false`
      // sentinels for closed stations in the e5 slot.
      final p = StationPrices.fromJson({
        'e5': false,
        'e10': 'not-a-number',
        'diesel': null,
        'status': 'open',
      });
      expect(p.e5, isNull);
      expect(p.e10, isNull);
      expect(p.diesel, isNull);
    });

    test('missing status falls back to "closed"', () {
      // So the UI never shows an incorrect "open" bubble for a
      // malformed / truncated response.
      final p = StationPrices.fromJson(const {});
      expect(p.status, 'closed');
      expect(p.isOpen, isFalse);
    });
  });
}
