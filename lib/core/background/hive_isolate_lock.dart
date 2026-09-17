// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/app_log.dart';
import '../logging/error_logger.dart';

/// File-based lock that keeps background scans from opening the Hive boxes
/// concurrently — across isolates of one process AND across processes.
///
/// ## Why?
/// Hive is not designed for multi-isolate access. WorkManager runs each
/// task in its own Dart isolate, a widget-refresh one-off can overlap the
/// periodic run (different unique names), and an iOS BGAppRefresh can
/// overlap an opportunistic or SLC wake. Two scans at once fetch twice,
/// both read the notification budget before either writes it, and write
/// the same boxes concurrently.
///
/// ## How (#4333)
///
/// **The claim is the file's existence.** [acquire] creates `hive_bg.lock`
/// with `O_EXCL` (`createSync(exclusive: true)`): the kernel lets exactly
/// one creator win, whichever isolate or process it runs in. The winner
/// writes who it is — a timestamp, its `pid` and a random token — and
/// [release] deletes the file only when that token is still its own.
///
/// **An OS lock says whether a foreign owner is alive.** The winner also
/// holds an exclusive `fcntl` lock on the file for as long as it holds the
/// claim. The OS drops that lock when the owning process dies, so an
/// acquirer that finds a claim written by ANOTHER pid probes it: a probe
/// that gets the lock proves the owner process is gone, and the claim is
/// reaped. A claim written by THIS pid belongs to another isolate of this
/// process — a probe cannot tell anything there (fcntl locks are
/// per-process), so it is reaped only past [sameProcessStaleAge], the
/// window after which WorkManager stops any worker.
///
/// ### What this replaced (B3)
/// A per-isolate static set of held paths plus the fcntl lock. Neither
/// excludes a second isolate of the same process — the set is per isolate
/// and fcntl locks are per process — and [release] deleted the file, so
/// the next acquirer locked a different inode than a holder that was still
/// running. `hive_isolate_lock_test.dart` proves exclusion with
/// `Isolate.spawn` and a real foreign process.
///
/// ### Residual windows, stated
/// * Reaping compares the claim's bytes just before deleting it; two
///   acquirers reaping the same stale claim within those microseconds can
///   still race. Only a crash leaves a stale claim, so this needs a crash
///   AND two simultaneous wakes.
/// * A foreign owner between creating its claim and taking the fcntl lock
///   (microseconds) probes as dead.
///
/// The main isolate does NOT acquire this lock — it owns the boxes
/// permanently. Background scans (and a foreground-isolate scan) use it to
/// serialize their short-lived access.
class HiveIsolateLock {
  static const _lockFileName = 'hive_bg.lock';

  /// Age past which a claim whose owner cannot even be read (empty, or the
  /// pre-#4333 format) is considered abandoned.
  static const staleLockAge = Duration(minutes: 2);

  /// Age past which a claim written by THIS process — another isolate — is
  /// considered abandoned. WorkManager stops a worker after ten minutes; an
  /// isolate whose engine was destroyed never ran its `finally`.
  static const sameProcessStaleAge = Duration(minutes: 10);

  /// Maximum time to wait for the lock before giving up.
  static const acquireTimeout = Duration(seconds: 30);

  /// Delay between lock acquisition attempts.
  static const retryDelay = Duration(milliseconds: 500);

  final File _lockFile;

  /// The clock every deadline, owner stamp and age is measured against
  /// (#4162). The wall clock in production; a test drives it so a
  /// contention case does not take the real [acquireTimeout].
  final DateTime Function() _clock;

  /// Open handle holding the fcntl lock while this instance holds the
  /// claim; `null` otherwise.
  RandomAccessFile? _handle;

  /// This instance's token in the claim, while held.
  String? _token;

  HiveIsolateLock._(this._lockFile, this._clock);

  /// Create a lock instance pointing to the standard lock file location.
  static Future<HiveIsolateLock> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final lockFile = File('${dir.path}${Platform.pathSeparator}$_lockFileName');
    return HiveIsolateLock._(lockFile, DateTime.now);
  }

  /// Create a lock instance with a custom file path (for testing), measured
  /// against [clock] when given.
  @visibleForTesting
  static HiveIsolateLock fromFile(
    File lockFile, {
    DateTime Function() clock = DateTime.now,
  }) {
    return HiveIsolateLock._(lockFile, clock);
  }

  static final Random _random = Random();

  /// Attempt to acquire the lock, retrying every [retryDelay] until
  /// [acquireTimeout]. Returns `true` if acquired, `false` if it timed out.
  /// Re-entrant for the instance that already holds it.
  Future<bool> acquire() async {
    if (_handle != null) return true;

    final deadline = _clock().add(acquireTimeout);
    while (true) {
      if (_tryClaim() || (_reapIfStale() && _tryClaim())) {
        log.debug('acquired', tag: 'HiveIsolateLock');
        return true;
      }
      if (!_clock().isBefore(deadline)) break;
      await Future<void>.delayed(retryDelay);
    }

    log.debug('acquire timed out after ${acquireTimeout.inSeconds}s',
        tag: 'HiveIsolateLock');
    return false;
  }

  /// Create the claim atomically, take the fcntl lock, write the owner.
  bool _tryClaim() {
    try {
      _lockFile.createSync(exclusive: true);
    } on FileSystemException {
      return false; // Claimed by someone — or its directory is missing.
    }
    RandomAccessFile? handle;
    try {
      handle = _lockFile.openSync(mode: FileMode.write);
      handle.lockSync(FileLock.exclusive);
      final token = '$pid-${_random.nextInt(1 << 32)}-'
          '${_clock().microsecondsSinceEpoch}';
      handle.writeStringSync(
          '${_clock().toUtc().toIso8601String()}\npid:$pid\ntoken:$token');
      handle.flushSync();
      _handle = handle;
      _token = token;
      return true;
    } catch (e, st) {
      // A prober of another process held the fcntl lock for an instant, or
      // the write failed: give the claim back and retry.
      log.warn('HiveIsolateLock: claim created but not taken, retrying',
          error: e, stack: st, layer: ErrorLayer.background);
      _closeQuietly(handle);
      _deleteQuietly();
      return false;
    }
  }

  /// Delete the existing claim when its owner is provably gone. Returns
  /// whether the path is free to claim again.
  bool _reapIfStale() {
    try {
      final owner = _readOwner();
      if (owner == null) return true; // Released meanwhile.
      final bool stale;
      if (owner.pid == null) {
        stale = _clock().difference(_lockFile.lastModifiedSync()) >
            staleLockAge;
      } else if (owner.pid != pid) {
        stale = _foreignOwnerGone();
      } else {
        final since = owner.stamp ?? _lockFile.lastModifiedSync();
        stale = _clock().difference(since) > sameProcessStaleAge;
      }
      if (!stale) return false;
      // Delete only the claim that was judged — not one created since.
      if (_readOwner()?.raw != owner.raw) return false;
      _lockFile.deleteSync();
      log.debug('reaped an abandoned claim (pid ${owner.pid})',
          tag: 'HiveIsolateLock');
      return true;
    } on FileSystemException {
      return !_lockFile.existsSync();
    } catch (e, st) {
      log.warn('HiveIsolateLock: stale-claim check failed',
          error: e, stack: st, layer: ErrorLayer.background);
      return false;
    }
  }

  /// Whether the process that owns the claim has exited: its fcntl lock
  /// would still be held otherwise.
  bool _foreignOwnerGone() {
    RandomAccessFile? probe;
    try {
      probe = _lockFile.openSync(mode: FileMode.append);
      probe.lockSync(FileLock.exclusive);
      probe.unlockSync();
      return true;
    } on FileSystemException {
      return false;
    } finally {
      _closeQuietly(probe);
    }
  }

  ({int? pid, String? token, DateTime? stamp, String raw})? _readOwner() {
    if (!_lockFile.existsSync()) return null;
    final raw = _lockFile.readAsStringSync();
    final lines = raw.split('\n');
    String? field(String name) {
      for (final line in lines) {
        if (line.startsWith('$name:')) return line.substring(name.length + 1);
      }
      return null;
    }

    return (
      pid: int.tryParse(field('pid') ?? ''),
      token: field('token'),
      stamp: DateTime.tryParse(lines.first),
      raw: raw,
    );
  }

  /// Release the lock: delete the claim if it is still this instance's,
  /// then drop the fcntl lock. Safe to call when the lock is not held —
  /// it then touches nothing, least of all a claim someone else holds.
  void release() {
    final handle = _handle;
    final token = _token;
    _handle = null;
    _token = null;
    if (handle == null) return;
    try {
      // Deleted BEFORE the fcntl lock drops: a foreign prober can only see
      // the lock free once the claim is already gone.
      if (_readOwner()?.token == token) _lockFile.deleteSync();
      log.debug('released', tag: 'HiveIsolateLock');
    } catch (e, st) {
      log.warn('HiveIsolateLock: release failed',
          error: e, stack: st, layer: ErrorLayer.background);
    }
    try {
      handle.unlockSync();
    } catch (e, st) {
      // Closing the handle below releases the lock anyway.
      log.warn('HiveIsolateLock: unlock failed',
          error: e, stack: st, layer: ErrorLayer.background);
    }
    _closeQuietly(handle);
  }

  void _closeQuietly(RandomAccessFile? handle) {
    try {
      handle?.closeSync();
    } catch (e, st) {
      log.warn('HiveIsolateLock: failed to close handle',
          error: e, stack: st, layer: ErrorLayer.background);
    }
  }

  void _deleteQuietly() {
    try {
      if (_lockFile.existsSync()) _lockFile.deleteSync();
    } catch (e, st) {
      log.warn('HiveIsolateLock: failed to give a claim back',
          error: e, stack: st, layer: ErrorLayer.background);
    }
  }

  /// Whether this instance currently holds the lock.
  bool get isLocked => _handle != null;
}
