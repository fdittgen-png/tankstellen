// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';

void main() {
  late Directory tempDir;
  late File lockFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_lock_test_');
    lockFile = File('${tempDir.path}${Platform.pathSeparator}test.lock');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveIsolateLock', () {
    test('acquire creates lock file and returns true', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);

      final acquired = await lock.acquire();

      expect(acquired, isTrue);
      expect(lockFile.existsSync(), isTrue);
    });

    test('release deletes lock file', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);
      await lock.acquire();

      lock.release();

      expect(lockFile.existsSync(), isFalse);
    });

    test('release is safe when lock file does not exist', () {
      final lock = HiveIsolateLock.fromFile(lockFile);

      // Should not throw
      lock.release();

      expect(lockFile.existsSync(), isFalse);
    });

    test('isLocked returns true when lock file exists', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);
      await lock.acquire();

      expect(lock.isLocked, isTrue);
    });

    test('isLocked returns false when no lock file', () {
      final lock = HiveIsolateLock.fromFile(lockFile);

      expect(lock.isLocked, isFalse);
    });

    test('isLocked returns false after release', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);
      await lock.acquire();
      lock.release();

      expect(lock.isLocked, isFalse);
    });

    test('lock file contains timestamp and pid', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);
      await lock.acquire();

      final content = lockFile.readAsStringSync();
      expect(content, contains('pid:'));
      // Should contain an ISO 8601 date
      expect(content, contains('T'));
    });

    test('removes stale lock and acquires', () async {
      // Create a "stale" lock file with an old modification time
      lockFile.writeAsStringSync('stale lock');
      // Set the modification time to 3 minutes ago (beyond staleLockAge)
      final staleTime = DateTime.now().subtract(const Duration(minutes: 3));
      lockFile.setLastModifiedSync(staleTime);

      final lock = HiveIsolateLock.fromFile(lockFile);
      final acquired = await lock.acquire();

      expect(acquired, isTrue);
      // Lock file should now have fresh content
      final content = lockFile.readAsStringSync();
      expect(content, contains('pid:'));
    });

    test('acquire-release-acquire cycle works', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);

      expect(await lock.acquire(), isTrue);
      lock.release();
      expect(lock.isLocked, isFalse);
      expect(await lock.acquire(), isTrue);
      expect(lock.isLocked, isTrue);

      lock.release();
    });

    test('constants are reasonable', () {
      expect(
        HiveIsolateLock.staleLockAge.inMinutes,
        greaterThanOrEqualTo(1),
      );
      expect(
        HiveIsolateLock.acquireTimeout.inSeconds,
        greaterThanOrEqualTo(10),
      );
      expect(
        HiveIsolateLock.retryDelay.inMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('fromFile creates instance with custom path', () {
      final customFile = File('${tempDir.path}/custom.lock');
      final lock = HiveIsolateLock.fromFile(customFile);

      expect(lock.isLocked, isFalse);
    });
  });

  group('HiveIsolateLock concurrent access', () {
    test('second lock is blocked while first holds, succeeds after release',
        () async {
      final lock1 = HiveIsolateLock.fromFile(lockFile);
      final lock2 = HiveIsolateLock.fromFile(lockFile);

      // First lock acquires and holds it.
      expect(await lock1.acquire(), isTrue);
      expect(lock1.isLocked, isTrue);
      // The second instance does NOT hold the lock — isLocked is now
      // per-instance ownership, not "the file exists".
      expect(lock2.isLocked, isFalse);

      // Release first lock; now the second can acquire.
      lock1.release();
      expect(await lock2.acquire(), isTrue);
      expect(lock2.isLocked, isTrue);

      lock2.release();
    });

    // #2300 — the core acceptance test: two near-simultaneous acquisitions on
    // the same lock file must never both win, even though POSIX advisory locks
    // are per-process. The in-process gate guarantees mutual exclusion.
    test('concurrent acquire attempts yield at most one true', () async {
      final lockA = HiveIsolateLock.fromFile(lockFile);
      final lockB = HiveIsolateLock.fromFile(lockFile);

      // Fire both acquire() in the same microtask burst — no awaits between
      // them, so they race exactly like two isolates firing at once.
      final futureA = lockA.acquire();
      final futureB = lockB.acquire();

      // Let the synchronous first attempt of each acquire() run.
      await Future<void>.delayed(Duration.zero);

      // Exactly one instance holds the lock after the first pass — never both.
      final holders = [lockA, lockB].where((l) => l.isLocked).toList();
      expect(holders.length, 1,
          reason: 'Exactly one concurrent acquire may hold the lock; the other '
              'must lose the race on the first pass.');

      // Release the winner so the spinning loser can win on its next retry
      // tick — proving the lock is reusable, not permanently wedged.
      holders.single.release();

      final results = await Future.wait([futureA, futureB]);
      // Winner returned true immediately; the loser wins after the release.
      // The invariant the bug violated — two simultaneous holders — is the
      // assertion above; here we confirm both calls ultimately resolve true
      // (serialized, never concurrent).
      expect(results.where((r) => r).length, 2);

      lockA.release();
      lockB.release();
      expect(lockFile.existsSync(), isFalse);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a fresh acquire succeeds after the prior holder releases', () async {
      final lock1 = HiveIsolateLock.fromFile(lockFile);
      final lock2 = HiveIsolateLock.fromFile(lockFile);

      expect(await lock1.acquire(), isTrue);
      lock1.release();

      // Pending second acquire (started after release) wins cleanly.
      expect(await lock2.acquire(), isTrue);
      lock2.release();
    });

    test('lock survives multiple rapid acquire attempts', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);

      // Rapid acquire-release cycles should not corrupt
      for (var i = 0; i < 10; i++) {
        expect(await lock.acquire(), isTrue);
        lock.release();
      }

      expect(lock.isLocked, isFalse);
    });
  });
}
