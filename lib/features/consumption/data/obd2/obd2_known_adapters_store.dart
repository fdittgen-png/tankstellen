// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/data/storage_repository.dart';
import '../../../../core/logging/error_logger.dart';

/// Local, NON-synced set of adapter deviceIds that have completed at
/// least one SUCCESSFUL connect on THIS phone (#3181).
///
/// This is the "first connect" discriminator for pairing mode: an id
/// absent from this set has never bonded/connected here, so its first
/// `setNotifyValue` may block on the OS pairing dialog and deserves the
/// generous [Obd2PairingMode.firstConnectSetNotifySecs] budget. The
/// [LastGoodAdapterStore] (#3019) pins only the SINGLE freshest adapter
/// — a user who switches between two adapters would wrongly re-enter
/// "first connect" on every switch — hence this small set.
///
/// Backed by [SettingsStorage] (the Hive `settings` box), one JSON list
/// under a private key — the `LastGoodAdapterStore` pattern. Local-only
/// by design: a Bluetooth bond is per-phone, so this must NOT reach the
/// TankSync schema (CLAUDE.md hard-rule #5; no `.from('<table>')` here).
/// Best-effort: a read/write failure degrades to "never connected"
/// (worst case: a harmless 30 s budget on a known adapter).
class KnownObd2AdaptersStore {
  final SettingsStorage _storage;

  const KnownObd2AdaptersStore(this._storage);

  /// Settings-box key for the known-good deviceId list. Namespaced
  /// alongside `obdLastGoodAdapter` / `obdAdapterWake:`.
  static const String _key = 'obdKnownGoodAdapterIds';

  /// Cap on retained ids — a household realistically owns a handful of
  /// adapters; oldest ids fall off the front (re-pairing one extra time
  /// after eviction is harmless).
  static const int maxIds = 12;

  static String _norm(String deviceId) => deviceId.trim().toUpperCase();

  /// Whether [deviceId] has ever completed a successful connect here.
  /// Best-effort: a read failure degrades to `false`.
  bool isKnownGood(String deviceId) {
    final id = _norm(deviceId);
    if (id.isEmpty) return false;
    try {
      final raw = _storage.getSetting(_key);
      if (raw is! List) return false;
      return raw.any((e) => e is String && _norm(e) == id);
    } catch (e, st) {
      _log('isKnownGood', e, st);
      return false;
    }
  }

  /// Record [deviceId] as known-good (idempotent; moves a re-seen id to
  /// the freshest slot). No-op for an empty id. Best-effort: a write
  /// failure is logged and swallowed.
  Future<void> markKnownGood(String deviceId) async {
    final id = _norm(deviceId);
    if (id.isEmpty) return;
    try {
      final raw = _storage.getSetting(_key);
      final ids = <String>[
        if (raw is List)
          for (final e in raw)
            if (e is String && _norm(e).isNotEmpty) _norm(e),
      ];
      ids.remove(id);
      ids.add(id);
      while (ids.length > maxIds) {
        ids.removeAt(0);
      }
      await _storage.putSetting(_key, ids);
    } catch (e, st) {
      _log('markKnownGood', e, st);
    }
  }

  void _log(String op, Object e, StackTrace st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
      'where': 'KnownObd2AdaptersStore $op failed',
    }));
  }
}
