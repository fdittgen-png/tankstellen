import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/opening_hours.dart';

void main() {
  group('RegularHours', () {
    test('fromJson decodes weekday + period strings', () {
      final rh = RegularHours.fromJson({
        'weekday': 1,
        'periodBegin': '08:00',
        'periodEnd': '18:00',
      });
      expect(rh.weekday, 1);
      expect(rh.periodBegin, '08:00');
      expect(rh.periodEnd, '18:00');
    });

    test('toJson round-trips every field', () {
      const rh = RegularHours(
        weekday: 3,
        periodBegin: '09:30',
        periodEnd: '17:45',
      );
      final json = rh.toJson();
      expect(json, {
        'weekday': 3,
        'periodBegin': '09:30',
        'periodEnd': '17:45',
      });
      final round = RegularHours.fromJson(json);
      expect(round, rh);
    });
  });

  group('OpeningHours', () {
    test('default: 24/7 is false, regularHours is empty', () {
      const oh = OpeningHours();
      expect(oh.twentyFourSeven, isFalse);
      expect(oh.regularHours, isEmpty);
    });

    test('24/7 flag survives round-trip', () {
      const oh = OpeningHours(twentyFourSeven: true);
      final round = OpeningHours.fromJson(oh.toJson());
      expect(round.twentyFourSeven, isTrue);
    });

    test('regularHours round-trip preserves list contents and order', () {
      const oh = OpeningHours(
        regularHours: [
          RegularHours(weekday: 1, periodBegin: '08:00', periodEnd: '18:00'),
          RegularHours(weekday: 2, periodBegin: '08:00', periodEnd: '18:00'),
          RegularHours(weekday: 6, periodBegin: '10:00', periodEnd: '14:00'),
        ],
      );
      final round = OpeningHours.fromJson(oh.toJson());
      expect(round.regularHours, hasLength(3));
      expect(round.regularHours.first.weekday, 1);
      expect(round.regularHours.last.weekday, 6);
      expect(round.regularHours.last.periodEnd, '14:00');
    });
  });

  group('RegularHoursListConverter', () {
    test('fromJson skips entries that are not maps', () {
      const converter = RegularHoursListConverter();
      final parsed = converter.fromJson([
        {'weekday': 1, 'periodBegin': '08:00', 'periodEnd': '18:00'},
        'garbage-string',
        42,
        null,
        {'weekday': 2, 'periodBegin': '09:00', 'periodEnd': '17:00'},
      ]);
      expect(parsed, hasLength(2));
      expect(parsed.map((h) => h.weekday).toList(), [1, 2]);
    });

    test('fromJson on an empty list returns an empty list', () {
      const converter = RegularHoursListConverter();
      expect(converter.fromJson([]), isEmpty);
    });

    test('toJson emits plain maps (no Freezed noise)', () {
      const converter = RegularHoursListConverter();
      final emitted = converter.toJson(const [
        RegularHours(weekday: 5, periodBegin: '08:00', periodEnd: '20:00'),
      ]);
      expect(emitted, [
        {'weekday': 5, 'periodBegin': '08:00', 'periodEnd': '20:00'},
      ]);
    });
  });
}
