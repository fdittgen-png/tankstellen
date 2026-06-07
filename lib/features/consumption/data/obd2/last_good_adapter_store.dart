// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/data/storage_repository.dart';
import '../../../../core/logging/error_logger.dart';

/// The auto-pinned last-good adapter (#3019 / Epic #3013 phase 3).
///
/// A small immutable record of the adapter the app most recently
/// connected to SUCCESSFULLY: its MAC, transport kind (`'ble'` /
/// `'classic'`) and friendly name. The reconnect controller reads it
/// to try the FAST pinned path first (a transport-correct direct
/// connect, leveraging #3016 scan-before-connect) before any re-scan.
class LastGoodAdapter {
  /// Stable per-device address — BLE remote-id / Classic MAC.
  final String mac;

  /// `'ble'` or `'classic'`. Drives WHICH direct path the reconnect
  /// controller takes on the fast path (a Classic adapter must NOT take
  /// the BLE direct path — it can only ever 4 s-timeout). Falls back to
  /// the re-scan path when the stored kind is missing / unknown.
  final String transportKind;

  /// Friendly device name, surfaced in the reconnect UI ("Reconnecting
  /// to vLinker FS…"). Empty when the advertisement carried none.
  final String name;

  const LastGoodAdapter({
    required this.mac,
    required this.transportKind,
    this.name = '',
  });

  /// `true` when [transportKind] is the Classic SPP flavour.
  bool get isClassic => transportKind == 'classic';

  Map<String, dynamic> toJson() => {
        'mac': mac,
        'transportKind': transportKind,
        'name': name,
      };

  /// Rebuild from the stored map, defensively against Hive type drift —
  /// returns null when the MAC is absent / not a non-empty string (a
  /// pin with no usable key is worthless to the reconnect controller).
  static LastGoodAdapter? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final mac = raw['mac'];
    if (mac is! String || mac.trim().isEmpty) return null;
    final kind = raw['transportKind'];
    final name = raw['name'];
    return LastGoodAdapter(
      mac: mac.trim(),
      transportKind: kind is String && kind.isNotEmpty ? kind : 'ble',
      name: name is String ? name : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LastGoodAdapter &&
          other.mac == mac &&
          other.transportKind == transportKind &&
          other.name == name);

  @override
  int get hashCode => Object.hash(mac, transportKind, name);

  @override
  String toString() =>
      'LastGoodAdapter(mac: $mac, transportKind: $transportKind, name: $name)';
}

/// Local, NON-synced auto-pin store for the last successfully-connected
/// OBD2 adapter (#3019 / Epic #3013 phase 3).
///
/// Backed by [SettingsStorage] (the Hive `settings` box), reusing the
/// `Obd2AdapterWakeCache` (#2268) pattern: ONE entry under a private
/// key. Local-only by design — the auto-pin is a device-specific
/// hardware-pairing convenience and must NOT reach the TankSync schema
/// (CLAUDE.md hard-rule #5). A field-add to this JSON map is transparent
/// regardless; it never persists through a `.from('<table>')` call.
///
/// Stateless + idempotent: each [record] overwrites the prior pin (the
/// user can switch adapters between trips, and the FRESHEST successful
/// connect is always the best reconnect candidate). Best-effort: a read
/// / write failure degrades to "no pin" rather than throwing into the
/// reconnect hot path.
class LastGoodAdapterStore {
  final SettingsStorage _storage;

  const LastGoodAdapterStore(this._storage);

  /// Settings-box key for the single last-good-adapter pin. Namespaced to
  /// avoid colliding with the `obdAdapterWake:` / `obdAdapterBroken:`
  /// keys in the shared `settings` box.
  static const String _key = 'obdLastGoodAdapter';

  /// Persist [adapter] as the auto-pinned last-good adapter. No-op when
  /// the MAC is empty — an unstamped service has no stable key to recall
  /// by next session, so storing it would just leak a useless entry.
  /// Best-effort: a write failure is logged and swallowed.
  Future<void> record(LastGoodAdapter adapter) async {
    if (adapter.mac.trim().isEmpty) return;
    try {
      await _storage.putSetting(_key, adapter.toJson());
    } catch (e, st) {
      _log('record', e, st);
    }
  }

  /// Convenience: pin straight from the three identity fields a freshly
  /// connected `Obd2Service` carries (`adapterMac` / `linkKind` /
  /// `adapterName`). A null / empty MAC is ignored.
  Future<void> recordFrom({
    String? mac,
    String? transportKind,
    String? name,
  }) async {
    if (mac == null || mac.trim().isEmpty) return;
    await record(LastGoodAdapter(
      mac: mac.trim(),
      transportKind: (transportKind != null && transportKind.isNotEmpty)
          ? transportKind
          : 'ble',
      name: name ?? '',
    ));
  }

  /// Recall the auto-pinned adapter, or null when nothing was pinned yet
  /// / the stored value drifted to an unusable shape. Best-effort: a read
  /// failure degrades to null.
  LastGoodAdapter? recall() {
    try {
      return LastGoodAdapter.fromJson(_storage.getSetting(_key));
    } catch (e, st) {
      _log('recall', e, st);
      return null;
    }
  }

  /// Forget the pin — the escape hatch for "Disconnect / Forget adapter".
  /// [SettingsStorage] has no key-delete, so the value is neutralised to
  /// null (making [recall] return null, as if never pinned). Best-effort.
  Future<void> clear() async {
    try {
      await _storage.putSetting(_key, null);
    } catch (e, st) {
      _log('clear', e, st);
    }
  }

  void _log(String op, Object e, StackTrace st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
      'where': 'LastGoodAdapterStore $op failed',
    }));
  }
}
