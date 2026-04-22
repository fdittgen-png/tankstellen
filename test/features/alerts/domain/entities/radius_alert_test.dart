import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';

void main() {
  RadiusAlert makeAlert({
    String id = 'r1',
    String fuelType = 'diesel',
    double threshold = 1.55,
    double centerLat = 48.1,
    double centerLng = 2.2,
    double radiusKm = 10,
    String label = 'Home',
    DateTime? createdAt,
    bool enabled = true,
  }) {
    return RadiusAlert(
      id: id,
      fuelType: fuelType,
      threshold: threshold,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
      label: label,
      createdAt: createdAt ?? DateTime(2026, 1, 1, 10, 0),
      enabled: enabled,
    );
  }

  group('RadiusAlert', () {
    test('toJson / fromJson round-trip preserves every field', () {
      final original = makeAlert(
        id: 'round-trip',
        fuelType: 'e10',
        threshold: 1.639,
        centerLat: 43.4527,
        centerLng: 3.4892,
        radiusKm: 12.5,
        label: 'Castelnau',
        createdAt: DateTime(2026, 4, 22, 8, 30),
        enabled: false,
      );

      final restored = RadiusAlert.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.fuelType, original.fuelType);
      expect(restored.threshold, original.threshold);
      expect(restored.centerLat, original.centerLat);
      expect(restored.centerLng, original.centerLng);
      expect(restored.radiusKm, original.radiusKm);
      expect(restored.label, original.label);
      expect(restored.createdAt, original.createdAt);
      expect(restored.enabled, original.enabled);
    });

    test('enabled defaults to true when omitted from JSON', () {
      final json = <String, dynamic>{
        'id': 'default-enabled',
        'fuelType': 'diesel',
        'threshold': 1.60,
        'centerLat': 48.0,
        'centerLng': 2.0,
        'radiusKm': 5.0,
        'label': 'Work',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final alert = RadiusAlert.fromJson(json);
      expect(alert.enabled, isTrue);
    });

    test('copyWith updates only the targeted field', () {
      final base = makeAlert();

      final toggled = base.copyWith(enabled: false);
      expect(toggled.enabled, isFalse);
      expect(toggled.id, base.id);
      expect(toggled.threshold, base.threshold);

      final raised = base.copyWith(threshold: 1.80);
      expect(raised.threshold, 1.80);
      expect(raised.enabled, isTrue);
      expect(raised.fuelType, base.fuelType);
    });

    test('equality compares by value, not identity', () {
      final a = makeAlert();
      final b = makeAlert();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = a.copyWith(threshold: 1.99);
      expect(a, isNot(equals(c)));
    });
  });
}
