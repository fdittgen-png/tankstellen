// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../logging/app_log.dart';
import '../../logging/error_logger.dart';
import '../../storage/hive_boxes.dart';
import '../../time/app_clock.dart';
import '../sync_context_key.dart';
import 'fleet_directory.dart';

/// How old a cached directory is, in the three states ADR 0025 D4
/// makes explicit. Never a boolean: "stale" is shown, "expired"
/// disables selection, and neither is silently treated as fresh.
enum FleetDirectoryFreshness {
  /// Younger than [FleetDirectoryCache.staleAfter].
  fresh,

  /// Older than [FleetDirectoryCache.staleAfter], younger than
  /// [FleetDirectoryCache.expireAfter]: usable, badged.
  stale,

  /// Older than [FleetDirectoryCache.expireAfter]: vehicle selection is
  /// disabled until a pull succeeds.
  expired,
}

/// A directory read back from the cache, with its age judged against
/// the clock the caller injected.
class CachedFleetDirectory {
  const CachedFleetDirectory({
    required this.directory,
    required this.age,
    required this.freshness,
  });

  final FleetDirectory directory;
  final Duration age;
  final FleetDirectoryFreshness freshness;

  /// D4: an expired cache never offers a vehicle to pick.
  bool get selectionEnabled => freshness != FleetDirectoryFreshness.expired;
}

/// The on-device copy of one org's directory (#4212, ADR 0025 D4).
///
/// Keyed by `SyncContextKey | orgId` — backend host, account AND org —
/// so a directory can never be served to another account, from another
/// backend, or for another org. Persistence is injected ([load] /
/// [persist] / [remove]) like `ScopedIdSets` (#4047), so the logic runs
/// in memory under test; [FleetDirectoryCache.hive] wires the encrypted
/// `fleet_directory` box.
///
/// No method throws on a storage fault: a cache that cannot be read
/// reads as empty, a cache that cannot be written is logged. The pull
/// that owns the cache decides what to show; the cache never does.
class FleetDirectoryCache {
  FleetDirectoryCache({
    required this.load,
    required this.persist,
    required this.remove,
  });

  /// D4 thresholds (deployment-independent — they are about the device
  /// copy, not about the org's data).
  static const Duration staleAfter = Duration(hours: 24);
  static const Duration expireAfter = Duration(days: 7);

  final String? Function(String key) load;
  final Future<void> Function(String key, String json) persist;
  final Future<void> Function(String key) remove;

  /// The cache over the encrypted `fleet_directory` box. A box that is
  /// not open (before `HiveBoxes.initDeferred`, in a widget test) reads
  /// as empty and writes nowhere.
  factory FleetDirectoryCache.hive() {
    Box<String>? box() => Hive.isBoxOpen(HiveBoxes.fleetDirectory)
        ? Hive.box<String>(HiveBoxes.fleetDirectory)
        : null;
    return FleetDirectoryCache(
      load: (key) => box()?.get(key),
      persist: (key, json) async => box()?.put(key, json),
      remove: (key) async => box()?.delete(key),
    );
  }

  /// `<backend host>|<user id>|<org id>`.
  static String keyFor({
    required String? backendUrl,
    required String userId,
    required String orgId,
  }) =>
      '${SyncContextKey.of(backendUrl: backendUrl, userId: userId).value}'
      '|$orgId';

  /// The cached directory under [key] judged against [clock], or null
  /// when nothing (readable) is cached.
  CachedFleetDirectory? read(String key, {required AppClock clock}) {
    final String? raw;
    try {
      raw = load(key);
    } catch (e, st) {
      _warn('read', key, e, st);
      return null;
    }
    if (raw == null || raw.isEmpty) return null;
    final FleetDirectory directory;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final parsed = FleetDirectory.fromJson(decoded);
      if (parsed == null) return null;
      directory = parsed;
    } catch (e, st) {
      // A blob this build cannot read is not a directory; say so once.
      _warn('decode', key, e, st);
      return null;
    }
    var age = clock.now().toUtc().difference(directory.fetchedAt);
    if (age.isNegative) age = Duration.zero; // a clock set back: fresh
    return CachedFleetDirectory(
      directory: directory,
      age: age,
      freshness: age >= expireAfter
          ? FleetDirectoryFreshness.expired
          : age >= staleAfter
              ? FleetDirectoryFreshness.stale
              : FleetDirectoryFreshness.fresh,
    );
  }

  /// Persist [directory] under [key]. Logged, not thrown, on failure.
  Future<void> write(String key, FleetDirectory directory) async {
    try {
      await persist(key, jsonEncode(directory.toJson()));
    } catch (e, st) {
      _warn('write', key, e, st);
    }
  }

  /// Forget [key] — after the server said the caller is not a member.
  Future<void> forget(String key) async {
    try {
      await remove(key);
    } catch (e, st) {
      _warn('forget', key, e, st);
    }
  }

  void _warn(String op, String key, Object e, StackTrace st) =>
      log.warn('FleetDirectoryCache.$op failed',
          tag: 'sync',
          error: e,
          stack: st,
          layer: ErrorLayer.sync,
          context: {'key': key});
}
