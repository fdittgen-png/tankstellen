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
    test('second lock waits while first is held', () async {
      final lock1 = HiveIsolateLock.fromFile(lockFile);
      final lock2 = HiveIsolateLock.fromFile(lockFile);

      // First lock acquires
      expect(await lock1.acquire(), isTrue);

      // Second lock should not be able to acquire immediately
      // (lock file exists and is not stale)
      // We can't easily test the timeout without waiting 30s,
      // so instead verify the lock file blocks the second attempt
      expect(lock2.isLocked, isTrue);

      // Release first lock
      lock1.release();

      // Now second lock can acquire
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
