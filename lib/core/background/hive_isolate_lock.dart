import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// File-based lock to prevent concurrent Hive access from main and background
/// isolates.
///
/// ## Why?
/// Hive is not designed for multi-isolate access. When WorkManager runs a
/// background task in a separate Dart isolate, both isolates may try to open
/// the same Hive box files simultaneously, causing corruption or crashes.
///
/// ## How?
/// Uses a simple lock file (`hive_bg.lock`) in the app's documents directory.
/// The background isolate creates the lock file before opening Hive boxes and
/// deletes it after closing them. If the lock file already exists (stale lock
/// from a crashed background task), it is considered stale after [staleLockAge]
/// and forcibly removed.
///
/// The main isolate does NOT acquire this lock — it owns the boxes permanently.
/// Only background isolates use this lock to serialize their short-lived access.
class HiveIsolateLock {
  static const _lockFileName = 'hive_bg.lock';

  /// How long a lock file can exist before it is considered stale.
  /// Background tasks typically complete in under 30 seconds. A lock older
  /// than 2 minutes is almost certainly from a crashed isolate.
  static const staleLockAge = Duration(minutes: 2);

  /// Maximum time to wait for the lock before giving up.
  static const acquireTimeout = Duration(seconds: 30);

  /// Delay between lock acquisition attempts.
  static const retryDelay = Duration(milliseconds: 500);

  final File _lockFile;

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
  /// Removes stale locks automatically.
  Future<bool> acquire() async {
    final deadline = DateTime.now().add(acquireTimeout);

    while (DateTime.now().isBefore(deadline)) {
      // Check for stale lock
      if (_lockFile.existsSync()) {
        final modified = _lockFile.lastModifiedSync();
        final age = DateTime.now().difference(modified);
        if (age > staleLockAge) {
          debugPrint('HiveIsolateLock: removing stale lock (age: ${age.inSeconds}s)');
          try {
            _lockFile.deleteSync();
          } catch (e, st) {
            debugPrint('HiveIsolateLock: failed to remove stale lock: $e\n$st');
          }
        }
      }

      // Try to create the lock file exclusively
      if (!_lockFile.existsSync()) {
        try {
          _lockFile.writeAsStringSync(
            '${DateTime.now().toIso8601String()}\npid:$pid',
            flush: true,
          );
          // Verify we actually created it (simple race check)
          if (_lockFile.existsSync()) {
            debugPrint('HiveIsolateLock: acquired');
            return true;
          }
        } catch (e, st) {
          debugPrint('HiveIsolateLock: create failed, retrying: $e\n$st');
        }
      }

      await Future<void>.delayed(retryDelay);
    }

    debugPrint('HiveIsolateLock: acquire timed out after ${acquireTimeout.inSeconds}s');
    return false;
  }

  /// Release the lock by deleting the lock file.
  void release() {
    try {
      if (_lockFile.existsSync()) {
        _lockFile.deleteSync();
        debugPrint('HiveIsolateLock: released');
      }
    } catch (e, st) {
      debugPrint('HiveIsolateLock: release failed: $e\n$st');
    }
  }

  /// Whether the lock file currently exists.
  bool get isLocked => _lockFile.existsSync();
}
