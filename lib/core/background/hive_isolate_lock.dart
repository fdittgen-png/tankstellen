// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/logging/error_logger.dart';

/// File-based lock to prevent concurrent Hive access from main and background
/// isolates.
///
/// ## Why?
/// Hive is not designed for multi-isolate access. When WorkManager runs a
/// background task in a separate Dart isolate, both isolates may try to open
/// the same Hive box files simultaneously, causing corruption or crashes.
///
/// ## How? (two complementary layers — #2300)
/// 1. **In-process gate** — a static set of currently-held lock-file paths.
///    POSIX `fcntl` advisory locks are *per process*, so a plain file lock
///    cannot separate two acquirers inside the same OS process (the main and
///    WorkManager isolates share one process). The in-memory gate makes
///    `acquire()` mutually exclusive within an isolate: at most one caller can
///    hold a given path at a time, the rest spin until the deadline.
/// 2. **OS-level advisory file lock** — `RandomAccessFile.lockSync(
///    FileLock.exclusive)` on `hive_bg.lock`. This is atomic across *separate
///    processes* (e.g. a detached headless task) and survives crashes: the OS
///    drops the lock when the owning process exits, so no stale lock can wedge
///    a fresh acquirer.
///
/// ### Why not check-then-create? (the bug this fixes)
/// The previous implementation did a non-atomic
/// `!existsSync()` → `writeAsStringSync()` → `existsSync()` dance. Two isolates
/// firing near-simultaneously (e.g. the `priceRefresh` periodic scan and an
/// opportunistic widget refresh) could *both* observe the file missing, *both* write it, and
/// *both* return `true` — then open the same Hive boxes concurrently and
/// corrupt them. The in-process gate closes that race; the file lock covers
/// the cross-process case. (Belt-and-braces: WorkManager registration also
/// serializes the periodic scan + an opportunistic widget refresh under one
/// unique name — see `AndroidBackgroundPriceFetcher`.)
///
/// The main isolate does NOT acquire this lock — it owns the boxes permanently.
/// Only background isolates use this lock to serialize their short-lived access.
class HiveIsolateLock {
  static const _lockFileName = 'hive_bg.lock';

  /// Lock-file paths currently held by *this isolate*. Guards against the
  /// per-process blindness of POSIX advisory locks (see class doc, layer 1).
  static final Set<String> _heldPaths = <String>{};

  /// How long a lock file can exist before it is considered stale.
  /// Background tasks typically complete in under 30 seconds. A lock older
  /// than 2 minutes is almost certainly from a crashed isolate.
  static const staleLockAge = Duration(minutes: 2);

  /// Maximum time to wait for the lock before giving up.
  static const acquireTimeout = Duration(seconds: 30);

  /// Delay between lock acquisition attempts.
  static const retryDelay = Duration(milliseconds: 500);

  final File _lockFile;

  /// Open handle holding the exclusive OS lock while acquired. `null` when the
  /// lock is not held by this instance.
  RandomAccessFile? _handle;

  HiveIsolateLock._(this._lockFile);

  /// Create a lock instance pointing to the standard lock file location.
  static Future<HiveIsolateLock> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final lockFile = File('${dir.path}${Platform.pathSeparator}$_lockFileName');
    return HiveIsolateLock._(lockFile);
  }

  /// Create a lock instance with a custom file path (for testing).
  @visibleForTesting
  static HiveIsolateLock fromFile(File lockFile) {
    return HiveIsolateLock._(lockFile);
  }

  /// Attempt to acquire the lock.
  ///
  /// Returns `true` if the lock was acquired, `false` if it timed out.
  ///
  /// Atomicity (#2300): opens the lock file and takes an exclusive OS-level
  /// [FileLock]. The OS guarantees only one holder at a time, so two isolates
  /// racing through `acquire()` can never both return `true`. A crashed holder
  /// releases its lock when its process/isolate exits, so there is no stale
  /// lock to time out — but we still sweep a stale *file* (one left behind by
  /// the legacy implementation or an abnormal exit that orphaned the handle)
  /// before opening, to keep the directory tidy.
  Future<bool> acquire() async {
    if (_handle != null) {
      // Already held by this instance — re-entrant acquire is a no-op success.
      return true;
    }

    final deadline = DateTime.now().add(acquireTimeout);

    while (true) {
      _sweepStaleFile();

      final handle = _tryLock();
      if (handle != null) {
        _handle = handle;
        _writeOwnerMetadata(handle);
        debugPrint('HiveIsolateLock: acquired');
        return true;
      }

      if (!DateTime.now().isBefore(deadline)) break;
      await Future<void>.delayed(retryDelay);
    }

    debugPrint('HiveIsolateLock: acquire timed out after ${acquireTimeout.inSeconds}s');
    return false;
  }

  /// Claim the in-process gate then open the lock file and attempt a
  /// non-blocking exclusive OS lock.
  ///
  /// Returns the locked handle on success, or `null` when another holder owns
  /// the path (in-process) or the exclusive lock (cross-process), so the caller
  /// retries until the deadline. On any failure the in-process claim is
  /// released so a retry can re-attempt cleanly.
  RandomAccessFile? _tryLock() {
    final path = _lockFile.path;
    // Synchronous claim — Dart isolates are single-threaded, so the
    // check-and-insert pair cannot interleave with another acquire.
    if (_heldPaths.contains(path)) return null;
    _heldPaths.add(path);

    RandomAccessFile? handle;
    try {
      handle = _lockFile.openSync(mode: FileMode.write);
      handle.lockSync(FileLock.exclusive);
      return handle;
    } on FileSystemException {
      // Lock contended by another *process* — release the in-process claim and
      // signal retry.
      _heldPaths.remove(path);
      try {
        handle?.closeSync();
      } catch (_) {
        // Best-effort close; nothing actionable if it fails.
      }
      return null;
    } catch (e, st) {
      _heldPaths.remove(path);
      try {
        handle?.closeSync();
      } catch (_) {
        // Best-effort close.
      }
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'HiveIsolateLock: lock attempt failed, retrying'}));
      return null;
    }
  }

  /// Best-effort write of owner metadata (timestamp + pid) into the locked
  /// file. Diagnostic only — the lock itself is the [FileLock], not the bytes.
  void _writeOwnerMetadata(RandomAccessFile handle) {
    try {
      handle.setPositionSync(0);
      handle.truncateSync(0);
      handle.writeStringSync('${DateTime.now().toIso8601String()}\npid:$pid');
      handle.flushSync();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'HiveIsolateLock: failed to write owner metadata'}));
    }
  }

  /// Delete a lock *file* that is older than [staleLockAge] and not currently
  /// locked by anyone. Skips deletion when an exclusive lock attempt fails
  /// (a live holder), so we never yank the file out from under an active task.
  void _sweepStaleFile() {
    if (!_lockFile.existsSync()) return;
    try {
      final age = DateTime.now().difference(_lockFile.lastModifiedSync());
      if (age <= staleLockAge) return;
      // Only delete if no one holds the lock — probe with a transient lock.
      final probe = _tryLock();
      if (probe == null) return; // Live holder; leave it alone.
      try {
        probe.unlockSync();
        probe.closeSync();
        _lockFile.deleteSync();
        debugPrint('HiveIsolateLock: removed stale lock file (age: ${age.inSeconds}s)');
      } finally {
        // Drop the transient in-process claim the probe took.
        _heldPaths.remove(_lockFile.path);
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'HiveIsolateLock: failed to remove stale lock'}));
    }
  }

  /// Release the lock: unlock the OS lock, close the handle, and delete the
  /// lock file. Safe to call when the lock is not held.
  void release() {
    final handle = _handle;
    _handle = null;
    if (handle != null) {
      try {
        handle.unlockSync();
      } catch (_) {
        // Best-effort unlock; closing the handle releases it anyway.
      }
      try {
        handle.closeSync();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'HiveIsolateLock: failed to close handle'}));
      }
      // Release the in-process gate so another acquirer in this isolate can win.
      _heldPaths.remove(_lockFile.path);
    }
    try {
      if (_lockFile.existsSync()) {
        _lockFile.deleteSync();
      }
      debugPrint('HiveIsolateLock: released');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'HiveIsolateLock: release failed'}));
    }
  }

  /// Whether this instance currently holds the lock.
  bool get isLocked => _handle != null;
}
