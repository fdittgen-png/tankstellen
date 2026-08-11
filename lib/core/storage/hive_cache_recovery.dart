// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/error_logger.dart';
import 'hive_boxes.dart';
import 'hive_cipher_loader.dart';
import 'hive_isolate_ownership.dart';

/// #3689 — self-heal for a foreground `cache` box whose file handle died
/// mid-flight.
///
/// Field failure mode: a background isolate's compaction (or any concurrent
/// file-level interference) invalidates the foreground's open handle; the
/// box still reads as open (`Hive.isBoxOpen` is registry state, and regular
/// box READS are memory-only), but every WRITE throws
/// `FileSystemException: File closed` until app restart — the cache went
/// silently read-only for 46+ minutes in the 2026-08-09 log.
///
/// [recover] closes the broken handle and reopens the box with the same
/// cipher — the data-preserving path. Only when the file is damaged beyond
/// reopen (at which point Hive's own crash recovery would truncate it
/// anyway) is the box deleted from disk and reopened empty: the box is
/// TTL'd API responses plus itineraries — the latter re-sync from TankSync
/// where enabled, and staying write-dead until restart loses strictly more.
/// #1686's never-delete rule still stands for the real user-data boxes
/// (favorites, profiles, trips …), which this recovery must never be
/// pointed at. Concurrent failing writers share one recovery via the
/// single-flight future.
class HiveCacheRecovery {
  HiveCacheRecovery._();

  static Future<bool>? _inFlight;

  /// Recover the `cache` box after a write-path [FileSystemException].
  /// Returns true when the box is open and writable again.
  static Future<bool> recover() => _inFlight ??= _recover().whenComplete(() {
        _inFlight = null;
      });

  static Future<bool> _recover() async {
    try {
      // Drop the broken handle. close() on a dead file may itself throw —
      // that still unregisters the box from Hive's registry.
      if (Hive.isBoxOpen(HiveBoxes.cache)) {
        try {
          await Hive.box<dynamic>(HiveBoxes.cache).close();
        } catch (_) {
          // ignore: silent_catch — the handle is already broken; closing is best-effort cleanup
        }
      }
      final cipher = await HiveCipherLoader.loadGuarded();
      try {
        await Hive.openBox<dynamic>(HiveBoxes.cache, encryptionCipher: cipher);
      } catch (e, st) {
        // The on-disk file is damaged beyond reopen (e.g. a half-finished
        // foreign compaction). The cache is disposable: start fresh rather
        // than staying write-dead until restart.
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
          'where': 'HiveCacheRecovery: reopen failed — resetting cache box',
        }));
        await Hive.deleteBoxFromDisk(HiveBoxes.cache);
        await Hive.openBox<dynamic>(HiveBoxes.cache, encryptionCipher: cipher);
      }
      // The recovered handle belongs to the main isolate again (#2670).
      HiveIsolateOwnership.markOwned(const [HiveBoxes.cache]);
      debugPrint('HiveCacheRecovery: cache box recovered');
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'HiveCacheRecovery: recovery failed',
      }));
      return false;
    }
  }
}
