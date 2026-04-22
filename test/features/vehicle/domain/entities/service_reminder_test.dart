import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';

void main() {
  group('ServiceReminder (#584)', () {
    test('nextDueOdometerKm = lastServiceOdometerKm + intervalKm', () {
      const r = ServiceReminder(
        id: '1',
        vehicleId: 'v1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 42000,
      );
      expect(r.nextDueOdometerKm, 57000);
    });

    test('nextDueOdometerKm = intervalKm when lastService is null', () {
      const r = ServiceReminder(
        id: '1',
        vehicleId: 'v1',
        label: 'Oil change',
        intervalKm: 15000,
      );
      expect(r.nextDueOdometerKm, 15000);
    });

    test('isDue fires at the exact threshold', () {
      const r = ServiceReminder(
        id: '1',
        vehicleId: 'v1',
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
        vehicleId: 'v1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 42000,
      );
      expect(r.isDue(60000), isTrue);
    });

    test('kmOverdue returns positive overrun past the threshold', () {
      const r = ServiceReminder(
        id: '1',
        vehicleId: 'v1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 0,
      );
      expect(r.kmOverdue(15000), 0);
      expect(r.kmOverdue(15500), 500);
      expect(r.kmOverdue(30500), 15500);
    });

    test('kmOverdue clamps to 0 before the threshold', () {
      const r = ServiceReminder(
        id: '1',
        vehicleId: 'v1',
        label: 'Oil change',
        intervalKm: 15000,
      );
      expect(r.kmOverdue(14000), 0);
    });

    test('markDone resets lastService to the current odometer', () {
      const r = ServiceReminder(
        id: '1',
        vehicleId: 'v1',
        label: 'Oil change',
        intervalKm: 15000,
        lastServiceOdometerKm: 0,
        pendingAcknowledgment: true,
      );
      final done = r.markDone(15200);
      expect(done.lastServiceOdometerKm, 15200);
      expect(done.pendingAcknowledgment, isFalse);
      // After mark-done the threshold shifts 15000 km further out.
      expect(done.isDue(20000), isFalse);
      expect(done.isDue(30200), isTrue);
    });

    test('JSON round-trip preserves every field', () {
      const r = ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-7',
        label: 'Tires',
        intervalKm: 40000,
        lastServiceOdometerKm: 18500,
        isActive: false,
        pendingAcknowledgment: true,
      );
      final json = r.toJson();
      final restored = ServiceReminder.fromJson(json);
      expect(restored, r);
    });

    test('JSON round-trip with null lastService preserves null', () {
      const r = ServiceReminder(
        id: 'r-1',
        vehicleId: 'v-2',
        label: 'Inspection',
        intervalKm: 30000,
      );
      final json = r.toJson();
      final restored = ServiceReminder.fromJson(json);
      expect(restored.lastServiceOdometerKm, isNull);
      // Defaults survive the round-trip.
      expect(restored.isActive, isTrue);
      expect(restored.pendingAcknowledgment, isFalse);
      expect(restored, r);
    });
  });
}
