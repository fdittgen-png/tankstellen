import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/maintenance_snooze_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/maintenance_suggestion.dart';

/// Direct unit tests for [MaintenanceSnoozeRepository] (Refs #561).
///
/// Covers the snooze contract used by the predictive-maintenance card
/// (#1124): per-signal storage keys, snooze/isSnoozed timing, default
/// snooze duration, clear / clearAll, and the closed-box / corrupt-
/// timestamp resilience guarantees.
void main() {
  group('MaintenanceSnoozeRepository (#561)', () {
    late Directory tmpDir;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('snooze_repo_test_');
      Hive.init(tmpDir.path);
      await Hive.openBox(HiveBoxes.settings);
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).clear();
        await Hive.box(HiveBoxes.settings).close();
      }
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('keyPrefix constant equals "maintenance.snooze."', () {
      expect(MaintenanceSnoozeRepository.keyPrefix, 'maintenance.snooze.');
    });

    test('defaultSnoozeDuration equals Duration(days: 30)', () {
      expect(
        MaintenanceSnoozeRepository.defaultSnoozeDuration,
        const Duration(days: 30),
      );
    });

    test('keyFor(idleRpmCreep) returns "maintenance.snooze.idleRpmCreep"',
        () {
      final repo = MaintenanceSnoozeRepository();
      expect(
        repo.keyFor(MaintenanceSignal.idleRpmCreep),
        'maintenance.snooze.idleRpmCreep',
      );
    });

    test('keyFor(mafDeviation) returns "maintenance.snooze.mafDeviation"',
        () {
      final repo = MaintenanceSnoozeRepository();
      expect(
        repo.keyFor(MaintenanceSignal.mafDeviation),
        'maintenance.snooze.mafDeviation',
      );
    });

    test('snooze then isSnoozed returns true while now < until', () async {
      final repo = MaintenanceSnoozeRepository();
      final now = DateTime.utc(2026, 4, 27, 12);
      final until = now.add(const Duration(days: 7));

      await repo.snooze(
        signal: MaintenanceSignal.idleRpmCreep,
        until: until,
      );

      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: now,
        ),
        isTrue,
      );
    });

    test('snooze then isSnoozed returns false once now >= until', () async {
      final repo = MaintenanceSnoozeRepository();
      final until = DateTime.utc(2026, 4, 27, 12);

      await repo.snooze(
        signal: MaintenanceSignal.idleRpmCreep,
        until: until,
      );

      // Exactly at the boundary: isAfter is strict, so until is NOT after
      // itself and the signal is no longer snoozed.
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: until,
        ),
        isFalse,
      );
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: until.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('isSnoozed with no entry returns false', () {
      final repo = MaintenanceSnoozeRepository();

      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: DateTime.utc(2026, 4, 27, 12),
        ),
        isFalse,
      );
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.mafDeviation,
          now: DateTime.utc(2026, 4, 27, 12),
        ),
        isFalse,
      );
    });

    test(
        'snoozeForDefault snoozes the signal for exactly '
        'defaultSnoozeDuration starting at now', () async {
      final repo = MaintenanceSnoozeRepository();
      final now = DateTime.utc(2026, 4, 27, 12);

      await repo.snoozeForDefault(
        signal: MaintenanceSignal.mafDeviation,
        now: now,
      );

      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.mafDeviation,
          now: now,
        ),
        isTrue,
        reason: 'now < now + 30d, so the signal must be snoozed',
      );
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.mafDeviation,
          now: now.add(
            MaintenanceSnoozeRepository.defaultSnoozeDuration +
                const Duration(seconds: 1),
          ),
        ),
        isFalse,
        reason: 'past now + 30d the snooze must have lapsed',
      );
    });

    test('clear(signal) removes the entry so isSnoozed returns false',
        () async {
      final repo = MaintenanceSnoozeRepository();
      final now = DateTime.utc(2026, 4, 27, 12);
      await repo.snooze(
        signal: MaintenanceSignal.idleRpmCreep,
        until: now.add(const Duration(days: 5)),
      );
      // Sanity check: the snooze is currently active.
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: now,
        ),
        isTrue,
      );

      await repo.clear(MaintenanceSignal.idleRpmCreep);

      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: now,
        ),
        isFalse,
      );
      // The underlying key is gone from the box.
      expect(
        Hive.box(HiveBoxes.settings)
            .containsKey(repo.keyFor(MaintenanceSignal.idleRpmCreep)),
        isFalse,
      );
    });

    test('clearAll() removes every snooze key for both signals', () async {
      final repo = MaintenanceSnoozeRepository();
      final now = DateTime.utc(2026, 4, 27, 12);
      await repo.snooze(
        signal: MaintenanceSignal.idleRpmCreep,
        until: now.add(const Duration(days: 5)),
      );
      await repo.snooze(
        signal: MaintenanceSignal.mafDeviation,
        until: now.add(const Duration(days: 5)),
      );
      // Drop an unrelated key into the same box; clearAll must NOT touch
      // it — the repo only owns the maintenance.snooze.* prefix.
      final box = Hive.box(HiveBoxes.settings);
      await box.put('unrelated.key', 'keep me');

      await repo.clearAll();

      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: now,
        ),
        isFalse,
      );
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.mafDeviation,
          now: now,
        ),
        isFalse,
      );
      expect(
        box.containsKey(repo.keyFor(MaintenanceSignal.idleRpmCreep)),
        isFalse,
      );
      expect(
        box.containsKey(repo.keyFor(MaintenanceSignal.mafDeviation)),
        isFalse,
      );
      expect(
        box.get('unrelated.key'),
        'keep me',
        reason: 'clearAll must only drop keys with the snooze prefix',
      );
    });

    test('isSnoozed returns false (and does not throw) for a corrupt '
        'manually-written timestamp', () async {
      final repo = MaintenanceSnoozeRepository();
      // Manually poison the storage with a non-ISO-8601 string. The
      // repository must treat this as "not snoozed" rather than
      // permanently silencing the signal.
      await Hive.box(HiveBoxes.settings).put(
        repo.keyFor(MaintenanceSignal.idleRpmCreep),
        'not a date',
      );

      expect(
        () => repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: DateTime.utc(2026, 4, 27, 12),
        ),
        returnsNormally,
      );
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: DateTime.utc(2026, 4, 27, 12),
        ),
        isFalse,
      );
    });
  });

  // Separate group with NO settings-box openBox in setUp — exercises the
  // closed-box no-op path through `_boxOrNull()`.
  group('MaintenanceSnoozeRepository with no settings box open (#561)', () {
    late Directory tmpDir;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('snooze_repo_closed_');
      Hive.init(tmpDir.path);
      // Intentionally do NOT open HiveBoxes.settings.
    });

    tearDown(() async {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        await Hive.box(HiveBoxes.settings).clear();
        await Hive.box(HiveBoxes.settings).close();
      }
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('snooze silently no-ops when the settings box is closed; '
        'isSnoozed reports false on a freshly-opened box', () async {
      final repo = MaintenanceSnoozeRepository();
      final now = DateTime.utc(2026, 4, 27, 12);

      // Settings box is closed: snooze must not throw and must not
      // persist anything.
      await expectLater(
        repo.snooze(
          signal: MaintenanceSignal.idleRpmCreep,
          until: now.add(const Duration(days: 5)),
        ),
        completes,
      );

      // While closed, isSnoozed also returns false.
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: now,
        ),
        isFalse,
      );

      // clear must also be a no-op when the box is closed.
      await expectLater(
        repo.clear(MaintenanceSignal.idleRpmCreep),
        completes,
      );

      // Now open the settings box and confirm nothing leaked through.
      await Hive.openBox(HiveBoxes.settings);
      expect(
        Hive.box(HiveBoxes.settings)
            .containsKey(repo.keyFor(MaintenanceSignal.idleRpmCreep)),
        isFalse,
      );
      expect(
        repo.isSnoozed(
          signal: MaintenanceSignal.idleRpmCreep,
          now: now,
        ),
        isFalse,
      );
    });
  });
}
