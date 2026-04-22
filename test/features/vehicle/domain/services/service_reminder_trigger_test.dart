import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';
import 'package:tankstellen/features/vehicle/domain/services/service_reminder_trigger.dart';

void main() {
  const trigger = ServiceReminderTrigger();

  group('ServiceReminderTrigger (#584)', () {
    // Baseline scenario straight out of the issue:
    //   lastServiceOdometerKm = 0, intervalKm = 15000
    const active = ServiceReminder(
      id: 'r-oil',
      vehicleId: 'v-1',
      label: 'Oil change',
      intervalKm: 15000,
      lastServiceOdometerKm: 0,
    );

    test('odometer 14999 does not trigger', () {
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 14999,
        reminders: const [active],
      );
      expect(result, isEmpty);
    });

    test('odometer 15000 triggers exactly at the threshold', () {
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 15000,
        reminders: const [active],
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'r-oil');
    });

    test('odometer 15001 triggers one km past the threshold', () {
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 15001,
        reminders: const [active],
      );
      expect(result, hasLength(1));
    });

    test('odometer 30500 still triggers — the reminder has not been reset',
        () {
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 30500,
        reminders: const [active],
      );
      expect(result, hasLength(1));
    });

    test('after markDone at 15000, odometer 20000 does not trigger', () {
      final afterDone = active.markDone(15000);
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 20000,
        reminders: [afterDone],
      );
      expect(result, isEmpty);
    });

    test('after markDone at 15000, odometer 30000 triggers again', () {
      final afterDone = active.markDone(15000);
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 30000,
        reminders: [afterDone],
      );
      expect(result, hasLength(1));
    });

    test('isActive=false reminders are skipped even when past threshold', () {
      final paused = active.copyWith(isActive: false);
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 20000,
        reminders: [paused],
      );
      expect(result, isEmpty);
    });

    test('reminders already pending are not re-triggered', () {
      final pending = active.copyWith(pendingAcknowledgment: true);
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 30000,
        reminders: [pending],
      );
      expect(result, isEmpty);
    });

    test('only reminders for the fill-up vehicle are considered', () {
      const otherVehicleReminder = ServiceReminder(
        id: 'r-oil-v2',
        vehicleId: 'v-2',
        label: 'Oil change',
        intervalKm: 15000,
      );
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 30000,
        reminders: const [otherVehicleReminder, active],
      );
      expect(result.map((r) => r.id), ['r-oil']);
    });

    test('returns every matching reminder when several are due', () {
      const tires = ServiceReminder(
        id: 'r-tires',
        vehicleId: 'v-1',
        label: 'Tires',
        intervalKm: 20000,
      );
      const inspection = ServiceReminder(
        id: 'r-inspection',
        vehicleId: 'v-1',
        label: 'Inspection',
        intervalKm: 30000,
      );
      final result = trigger.findTriggered(
        vehicleId: 'v-1',
        currentOdometerKm: 40000,
        reminders: const [active, tires, inspection],
      );
      expect(result.map((r) => r.id).toSet(),
          {'r-oil', 'r-tires', 'r-inspection'});
    });
  });
}
