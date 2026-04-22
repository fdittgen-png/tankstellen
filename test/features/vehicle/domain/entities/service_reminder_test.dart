import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/service_reminder.dart';

void main() {
  ServiceReminder makeReminder({
    String id = 'r-1',
    String vehicleId = 'v-1',
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
      createdAt: createdAt ?? DateTime(2026, 1, 1, 9, 0),
      enabled: enabled,
    );
  }

  group('ServiceReminder (#584 phase 1)', () {
    test('JSON round-trip preserves every field', () {
      final r = makeReminder();
      final restored = ServiceReminder.fromJson(r.toJson());
      expect(restored, r);
    });

    test('JSON round-trip preserves disabled state', () {
      final r = makeReminder(enabled: false);
      final restored = ServiceReminder.fromJson(r.toJson());
      expect(restored.enabled, isFalse);
      expect(restored, r);
    });

    test('copyWith updates lastServiceOdometerKm without touching other fields',
        () {
      final r = makeReminder();
      final updated = r.copyWith(lastServiceOdometerKm: 57000);

      expect(updated.lastServiceOdometerKm, 57000);
      // All other fields should be unchanged.
      expect(updated.id, r.id);
      expect(updated.vehicleId, r.vehicleId);
      expect(updated.label, r.label);
      expect(updated.intervalKm, r.intervalKm);
      expect(updated.enabled, r.enabled);
      expect(updated.createdAt, r.createdAt);
    });

    test('copyWith flips enabled without touching other fields', () {
      final r = makeReminder(enabled: true);
      final toggled = r.copyWith(enabled: false);

      expect(toggled.enabled, isFalse);
      expect(toggled.id, r.id);
      expect(toggled.intervalKm, r.intervalKm);
      expect(toggled.lastServiceOdometerKm, r.lastServiceOdometerKm);
    });

    test('defaults enabled to true when omitted', () {
      final r = ServiceReminder(
        id: 'r',
        vehicleId: 'v',
        label: 'Inspection',
        intervalKm: 30000,
        lastServiceOdometerKm: 0,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(r.enabled, isTrue);
    });

    test('equality: two reminders with identical fields are equal', () {
      final a = makeReminder();
      final b = makeReminder();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
