// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';

import '../../helpers/hive_temp_dir.dart';
import '../../helpers/silence_error_logger.dart';

/// A fixed instant every owner stamp in the #4333 cases is written at.
final DateTime _t0 = DateTime.utc(2026, 9, 16, 9);

/// A lock clock starting at [start] that runs 20 s per reading, so a
/// contended acquire gives up after two attempts instead of 30 s.
DateTime Function() _fastClock([DateTime? start]) {
  var t = start ?? _t0;
  return () => t = t.add(const Duration(seconds: 20));
}

/// Runs in a spawned isolate of THIS process: try the lock file, report,
/// and — when told to — hold it until asked to release.
Future<void> _contendInIsolate((SendPort, String) message) async {
  final (reply, path) = message;
  final lock = HiveIsolateLock.fromFile(File(path), clock: _fastClock());
  final acquired = await lock.acquire();
  if (acquired) lock.release();
  reply.send(acquired);
}

Future<bool> _acquiredByAnotherIsolate(File lockFile) async {
  final port = ReceivePort();
  await Isolate.spawn(_contendInIsolate, (port.sendPort, lockFile.path));
  final acquired = await port.first as bool;
  port.close();
  return acquired;
}

void main() {
  silenceErrorLoggerSpool();

  late Directory tempDir;
  late File lockFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_lock_test_');
    lockFile = File('${tempDir.path}${Platform.pathSeparator}test.lock');
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(tempDir);
  });

  group('HiveIsolateLock', () {
    test('acquire creates lock file and returns true', () async {
      final lock = HiveIsolateLock.fromFile(lockFile);

      final acquired = await lock.acquire();

      expect(acquired, isTrue);
      expect(lockFile.existsSync(), isTrue);
    });

    test('release is safe when the lock was never held — and leaves a '
        'claim someone else holds alone (#4333)', () async {
      final holder = HiveIsolateLock.fromFile(lockFile, clock: () => _t0);
      expect(await holder.acquire(), isTrue);

      HiveIsolateLock.fromFile(lockFile).release();

      expect(lockFile.existsSync(), isTrue,
          reason: 'releasing a lock you do not hold must never unlink the '
              'holder\'s claim');
      holder.release();
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

  // #4333 B3 — exclusion must hold across ISOLATES of one process (the
  // WorkManager periodic run and a widget one-off, or an iOS refresh and an
  // SLC wake) and across a process that died holding the claim.
  group('cross-isolate and cross-process exclusion (#4333)', () {
    test('a second isolate of this process cannot acquire while this one '
        'holds the lock', () async {
      final holder = HiveIsolateLock.fromFile(lockFile, clock: () => _t0);
      expect(await holder.acquire(), isTrue);

      expect(await _acquiredByAnotherIsolate(lockFile), isFalse,
          reason: 'B3: a per-isolate claim is invisible to another isolate, '
              'and fcntl locks are per process');

      holder.release();
      expect(await _acquiredByAnotherIsolate(lockFile), isTrue,
          reason: 'released, the other isolate gets it');
    });

    test('the other isolate does not delete the holder\'s file', () async {
      final holder = HiveIsolateLock.fromFile(lockFile, clock: () => _t0);
      expect(await holder.acquire(), isTrue);
      final before = lockFile.readAsStringSync();

      await _acquiredByAnotherIsolate(lockFile);

      expect(lockFile.existsSync(), isTrue);
      expect(lockFile.readAsStringSync(), before,
          reason: 'the holder\'s claim is untouched');
      holder.release();
    });

    test("a holder's release never deletes a claim that is no longer its "
        'own', () async {
      final holder = HiveIsolateLock.fromFile(lockFile, clock: () => _t0);
      expect(await holder.acquire(), isTrue);
      // Its claim was reaped and re-created by another owner meanwhile.
      lockFile.writeAsStringSync(
          '${_t0.toIso8601String()}\npid:$pid\ntoken:someone-else');

      holder.release();

      expect(lockFile.readAsStringSync(), contains('token:someone-else'),
          reason: "unlinking another owner's claim is exactly B3");
    });

    test('a claim whose process died is reaped at once', () async {
      // What a killed process leaves: its owner line, and no fcntl holder.
      lockFile.writeAsStringSync(
          '${_t0.toIso8601String()}\npid:${pid + 100000}\ntoken:dead');

      final lock = HiveIsolateLock.fromFile(lockFile, clock: _fastClock());
      expect(await lock.acquire(), isTrue);
      expect(lockFile.readAsStringSync(), contains('pid:$pid'));
      lock.release();
    });

    test('a claim held by a LIVE foreign process is respected until that '
        'process dies', () async {
      final python = await Process.start('python3', [
        '-c',
        ('import fcntl, os, sys, time\n'
            'p = sys.argv[1]\n'
            'fd = os.open(p, os.O_CREAT | os.O_EXCL | os.O_WRONLY)\n'
            'os.write(fd, ("2026-09-16T09:00:00.000Z\\npid:%d\\ntoken:py" '
            '% os.getpid()).encode())\n'
            'fcntl.lockf(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)\n'
            'print("held", flush=True)\n'
            'time.sleep(60)\n'),
        lockFile.path,
      ]);
      addTearDown(python.kill);
      await python.stdout.transform(utf8.decoder).firstWhere(
          (line) => line.contains('held'));

      final contender =
          HiveIsolateLock.fromFile(lockFile, clock: _fastClock());
      expect(await contender.acquire(), isFalse,
          reason: 'the owner is alive: its fcntl lock is held');

      python.kill();
      await python.exitCode;
      expect(await contender.acquire(), isTrue,
          reason: 'the OS dropped the dead owner\'s lock');
      contender.release();
    },
        skip: Process.runSync('which', ['python3']).exitCode == 0
            ? false
            : 'python3 is needed to hold a lock from another process');

    test('a claim this process\'s dead isolate left is reaped only past the '
        'WorkManager stop window', () async {
      lockFile.writeAsStringSync(
          '${_t0.toIso8601String()}\npid:$pid\ntoken:dead-isolate');

      final early = HiveIsolateLock.fromFile(lockFile,
          clock: _fastClock(_t0.add(const Duration(minutes: 5))));
      expect(await early.acquire(), isFalse,
          reason: 'five minutes in, it may be a live, slow scan');

      final late = HiveIsolateLock.fromFile(lockFile,
          clock: _fastClock(_t0.add(const Duration(minutes: 11))));
      expect(await late.acquire(), isTrue);
      late.release();
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
