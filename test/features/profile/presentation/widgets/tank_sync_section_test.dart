import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/tank_sync_section.dart';

void main() {
  group('TankSyncSection', () {
    test('widget exists and can be instantiated', () {
      const widget = TankSyncSection();
      expect(widget, isNotNull);
      expect(widget, isA<TankSyncSection>());
    });

    test('has const constructor with optional key', () {
      const a = TankSyncSection();
      const b = TankSyncSection();
      // Both are valid instances.
      expect(a, isNotNull);
      expect(b, isNotNull);
    });
  });
}
