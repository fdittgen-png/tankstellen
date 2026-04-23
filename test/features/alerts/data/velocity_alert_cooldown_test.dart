import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/velocity_alert_cooldown.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_velocity_cd_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).close();
    }
    await Hive.openBox(HiveBoxes.settings);
    await Hive.box(HiveBoxes.settings).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('VelocityAlertCooldown', () {
    test('canFire returns true when no alert has ever fired', () async {
      final cd = VelocityAlertCooldown();
      expect(
        await cd.canFire(
          fuelType: FuelType.e10,
          now: DateTime.utc(2026, 4, 22, 12),
          cooldown: const Duration(hours: 6),
        ),
        isTrue,
      );
    });

    test('cooldown is honored per fuel type independently', () async {
      final cd = VelocityAlertCooldown();
      final now = DateTime.utc(2026, 4, 22, 12);

      // Fire for E10 → E10 blocked, diesel still eligible.
      await cd.recordFired(fuelType: FuelType.e10, now: now);

      expect(
        await cd.canFire(
          fuelType: FuelType.e10,
          now: now.add(const Duration(hours: 1)),
          cooldown: const Duration(hours: 6),
        ),
        isFalse,
        reason: 'E10 within cooldown window should be blocked',
      );

      expect(
        await cd.canFire(
          fuelType: FuelType.diesel,
          now: now.add(const Duration(hours: 1)),
          cooldown: const Duration(hours: 6),
        ),
        isTrue,
        reason: 'Diesel is a separate fuel and must not be blocked by E10',
      );
    });

    test('canFire returns true once the cooldown has elapsed', () async {
      final cd = VelocityAlertCooldown();
      final now = DateTime.utc(2026, 4, 22, 12);
      await cd.recordFired(fuelType: FuelType.e10, now: now);

      expect(
        await cd.canFire(
          fuelType: FuelType.e10,
          now: now.add(const Duration(hours: 5, minutes: 59)),
          cooldown: const Duration(hours: 6),
        ),
        isFalse,
      );

      expect(
        await cd.canFire(
          fuelType: FuelType.e10,
          now: now.add(const Duration(hours: 6)),
          cooldown: const Duration(hours: 6),
        ),
        isTrue,
      );
    });
  });
}
