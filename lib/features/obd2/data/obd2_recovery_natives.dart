// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'classic_method_channel.dart';

/// #3422 — the Bluetooth consent-dialog actions rung 3 of the wedge-recovery
/// ladder fires. These are system DIALOGS the user must confirm — NOT silent
/// toggles: `BluetoothAdapter.enable()/disable()` throw `SecurityException`
/// on API 31+ (#3404), so the two-tap consent cycle is the strongest in-app
/// BT reset available. OEM-dependent — resolve before firing.
const String kBtActionRequestDisable =
    'android.bluetooth.adapter.action.REQUEST_DISABLE';

/// See [kBtActionRequestDisable].
const String kBtActionRequestEnable =
    'android.bluetooth.adapter.action.REQUEST_ENABLE';

/// #3422 — native seams the wedge-recovery escalation ladder drives. One
/// abstract surface so a unit test wires a scriptable fake and exercises the
/// full rung ordering with zero platform channels.
abstract class Obd2WedgeRecoveryNatives {
  /// Rung 1: refresh the local SDP / RFCOMM-channel cache for [mac].
  Future<bool> fetchUuidsWithSdp(String mac);

  /// Rung 2 (config-gated): drop the bond (reflection `removeBond()`).
  Future<bool> removeBond(String mac);

  /// Rung 2: re-pair (public `createBond()`; may show the pairing dialog).
  Future<bool> createBond(String mac);

  /// Rung 3: whether the Bluetooth adapter is currently enabled.
  Future<bool> adapterEnabled();

  /// Rung 3: whether an Activity resolves for [action] (OEM-dependent).
  Future<bool> resolveBtIntent(String action);

  /// Rung 3: fire the consent dialog for [action].
  Future<bool> fireBtIntent(String action);

  /// Rung 3 fallback + rung 4 button: deep-link the system BT settings.
  Future<bool> openBluetoothSettings();
}

/// Thin Dart binding for the `tankstellen.obd2/recovery` MethodChannel that
/// `MainActivity` registers (#3422). Activity-bound on the Kotlin side —
/// firing an intent needs an Activity context — unlike the context-only
/// [Obd2ClassicMethodChannel] the device-level hooks ride on.
class Obd2RecoveryIntentChannel {
  static const _channel = MethodChannel('tankstellen.obd2/recovery');

  const Obd2RecoveryIntentChannel();

  /// Whether an Activity resolves for [action]. Throws on an old native side
  /// — [ChannelObd2WedgeRecoveryNatives] owns the guard.
  Future<bool> resolveBtIntent(String action) async =>
      await _channel.invokeMethod<bool>(
        'resolveBtIntent',
        {'action': action},
      ) ??
      false;

  /// Fire the consent dialog for [action].
  Future<bool> fireBtIntent(String action) async =>
      await _channel.invokeMethod<bool>('fireBtIntent', {'action': action}) ??
      false;

  /// Deep-link the system Bluetooth settings screen.
  Future<bool> openBluetoothSettings() async =>
      await _channel.invokeMethod<bool>('openBluetoothSettings') ?? false;
}

/// Production [Obd2WedgeRecoveryNatives]: device-level hooks over the
/// in-repo Classic plugin channel, intent hooks over the Activity-bound
/// recovery channel. Every method NEVER throws — a missing/old native side,
/// an iOS build (no such channels), or a platform error all degrade to
/// `false`, and the ladder simply falls through to the next rung.
class ChannelObd2WedgeRecoveryNatives implements Obd2WedgeRecoveryNatives {
  final Obd2ClassicMethodChannel _classic;
  final Obd2RecoveryIntentChannel _intents;

  const ChannelObd2WedgeRecoveryNatives({
    Obd2ClassicMethodChannel classic = const Obd2ClassicMethodChannel(),
    Obd2RecoveryIntentChannel intents = const Obd2RecoveryIntentChannel(),
  })  : _classic = classic,
        _intents = intents;

  @override
  Future<bool> fetchUuidsWithSdp(String mac) =>
      _guard('fetchUuidsWithSdp', () => _classic.fetchUuidsWithSdp(mac));

  @override
  Future<bool> removeBond(String mac) =>
      _guard('removeBond', () => _classic.removeBond(mac));

  @override
  Future<bool> createBond(String mac) =>
      _guard('createBond', () => _classic.createBond(mac));

  @override
  Future<bool> adapterEnabled() =>
      _guard('adapterEnabled', _classic.adapterEnabled);

  @override
  Future<bool> resolveBtIntent(String action) =>
      _guard('resolveBtIntent', () => _intents.resolveBtIntent(action));

  @override
  Future<bool> fireBtIntent(String action) =>
      _guard('fireBtIntent', () => _intents.fireBtIntent(action));

  @override
  Future<bool> openBluetoothSettings() =>
      _guard('openBluetoothSettings', _intents.openBluetoothSettings);

  /// Run one native hook defensively (the never-throws contract above): a
  /// [MissingPluginException] (old native / iOS), a [PlatformException] or
  /// any other error degrades to `false` so the ladder falls through.
  Future<bool> _guard(String what, Future<bool> Function() call) async {
    try {
      return await call();
    } catch (e, st) {
      debugPrint('ChannelObd2WedgeRecoveryNatives: $what failed '
          '(rung falls through, #3422): $e\n$st');
      return false;
    }
  }
}
