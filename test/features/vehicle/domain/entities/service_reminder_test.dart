import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';

void main() {
  group('ServiceReminder (#584)', () {
    test('nextDueOdometerKm = lastServiceOdometerKm + intervalKm', () {
      const r = ServiceReminder(
        id: '1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 42000,
      );
      expect(r.nextDueOdometerKm, 57000);
    });

    test('nextDueOdometerKm = intervalKm when lastService is null', () {
      const r = ServiceReminder(
        id: '1',
        label: 'Oil change',
        intervalKm: 15000,
      );
      expect(r.nextDueOdometerKm, 15000);
    });

    test('isDue fires at the exact threshold', () {
      const r = ServiceReminder(
        id: '1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 42000,
      );
      expect(r.isDue(57000), isTrue);
      expect(r.isDue(56999.99), isFalse);
    });

    test('isDue stays true past the threshold', () {
      const r = ServiceReminder(
        id: '1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 42000,
      );
      expect(r.isDue(60000), isTrue);
    });

    test('JSON round-trip preserves every field', () {
      const r = ServiceReminder(
        id: 'r-1',
        label: 'Tires',
        intervalKm: 40000,
        lastServiceOdometerKm: 18500,
      );
      final json = r.toJson();
      final restored = ServiceReminder.fromJson(json);
      expect(restored, r);
    });

    test('JSON round-trip with null lastService preserves null', () {
      const r = ServiceReminder(
        id: 'r-1',
        label: 'Inspection',
        intervalKm: 30000,
      );
      final json = r.toJson();
      final restored = ServiceReminder.fromJson(json);
      expect(restored.lastServiceOdometerKm, isNull);
      expect(restored, r);
    });
  });
}
