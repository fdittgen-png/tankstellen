import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';
import 'package:tankstellen/features/vehicle/domain/service_reminder_checker.dart';

void main() {
  const checker = ServiceReminderChecker();

  ServiceReminder makeReminder({
    String id = 'r1',
    String vehicleId = 'v1',
    String label = 'Oil change',
    int intervalKm = 15000,
    int lastServiceOdometerKm = 42000,
    DateTime? createdAt,
    bool enabled = true,
  }) {
    return ServiceReminder(
      id: id,
      vehicleId: vehicleId,
      label: label,
      intervalKm: intervalKm,
      lastServiceOdometerKm: lastServiceOdometerKm,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      enabled: enabled,
    );
  }

  group('ServiceReminderChecker.isDue', () {
    test('returns false before the interval has elapsed', () {
      final r = makeReminder();
      expect(checker.isDue(r, 56999), isFalse);
    });

    test('returns true at the exact boundary (current - last == interval)',
        () {
      final r = makeReminder();
      expect(checker.isDue(r, 57000), isTrue);
    });

    test('returns true once the interval is exceeded', () {
      final r = makeReminder();
      expect(checker.isDue(r, 60000), isTrue);
    });

    test('returns false when reminder is disabled, even if overdue', () {
      final r = makeReminder(enabled: false);
      // 20 000 km past the interval
      expect(checker.isDue(r, 77000), isFalse);
    });

    test('returns false when current odometer is below last service reading',
        () {
      // Sanity: the user typed in an odometer that's LOWER than the
      // last-service reading (maybe they corrected a typo). isDue
      // should never say "due" in that case.
      final r = makeReminder(lastServiceOdometerKm: 42000);
      expect(checker.isDue(r, 30000), isFalse);
    });

    test('fires on a fresh reminder (last=0) once interval is crossed', () {
      final r = makeReminder(lastServiceOdometerKm: 0, intervalKm: 15000);
      expect(checker.isDue(r, 14999), isFalse);
      expect(checker.isDue(r, 15000), isTrue);
    });
  });

  group('ServiceReminderChecker.kmUntilDue', () {
    test('returns the remaining km when not yet due', () {
      final r = makeReminder();
      expect(checker.kmUntilDue(r, 50000), 7000);
    });

    test('returns zero at the exact threshold', () {
      final r = makeReminder();
      expect(checker.kmUntilDue(r, 57000), 0);
    });

    test('returns a negative value when overdue', () {
      final r = makeReminder();
      expect(checker.kmUntilDue(r, 60000), -3000);
    });

    test('ignores enabled flag — UI still wants the countdown while paused',
        () {
      final r = makeReminder(enabled: false);
      expect(checker.kmUntilDue(r, 50000), 7000);
    });
  });

  group('ServiceReminderChecker.markServiced', () {
    test('snaps lastServiceOdometerKm to the provided value', () {
      final r = makeReminder(lastServiceOdometerKm: 42000);
      final updated = checker.markServiced(r, 58000);
      expect(updated.lastServiceOdometerKm, 58000);
    });

    test('leaves every other field untouched', () {
      final r = makeReminder();
      final updated = checker.markServiced(r, 58000);
      expect(updated.id, r.id);
      expect(updated.vehicleId, r.vehicleId);
      expect(updated.label, r.label);
      expect(updated.intervalKm, r.intervalKm);
      expect(updated.enabled, r.enabled);
      expect(updated.createdAt, r.createdAt);
    });

    test('is idempotent — calling twice with the same odometer is a no-op',
        () {
      final r = makeReminder();
      final once = checker.markServiced(r, 60000);
      final twice = checker.markServiced(once, 60000);
      expect(twice, once);
    });

    test('rearms an overdue reminder — next isDue check returns false', () {
      final r = makeReminder(lastServiceOdometerKm: 42000, intervalKm: 15000);
      // Currently overdue at 60 000.
      expect(checker.isDue(r, 60000), isTrue);

      final serviced = checker.markServiced(r, 60000);
      // After marking done, the very same odometer should no longer trigger.
      expect(checker.isDue(serviced, 60000), isFalse);
      // And it takes another full interval to come due again.
      expect(checker.isDue(serviced, 75000), isTrue);
    });
  });
}
