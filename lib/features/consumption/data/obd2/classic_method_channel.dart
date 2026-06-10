// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';

/// Thin Dart binding for the in-repo Kotlin plugin `Obd2ClassicPlugin`
/// (#763). Separated from [PluginClassicBluetoothFacade] so tests can
/// swap this out via a constructor-injected fake without touching the
/// façade surface that production call sites use.
///
/// Channel names are kept in one place here — the Kotlin side
/// mirrors the same strings. Keep them in sync.
class Obd2ClassicMethodChannel {
  static const _methodChannel =
      MethodChannel('tankstellen.obd2/classic');
  static const _incomingChannel =
      EventChannel('tankstellen.obd2/classic/incoming');

  const Obd2ClassicMethodChannel();

  /// Enumerates every Bluetooth Classic device the OS already
  /// bonded with. The realistic vLinker FS flow: the user pairs in
  /// Android settings once, then the adapter shows up here on every
  /// app launch. Returns `[]` when Bluetooth is off or the query
  /// fails.
  Future<List<ClassicBondedDevice>> bondedDevices() async {
    final raw = await _methodChannel.invokeListMethod<dynamic>('bondedDevices')
        ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => ClassicBondedDevice(
              address: m['address'] as String? ?? '',
              name: m['name'] as String? ?? '',
            ))
        .where((d) => d.address.isNotEmpty)
        .toList();
  }

  /// Open an RFCOMM socket to [address] on the Serial Port Profile UUID.
  /// Returns `true` on success. Must be called once per connection —
  /// subsequent calls close the prior socket first.
  ///
  /// #2969 — accepts BOTH the new Map return shape `{ok, strategy, error}` and
  /// the legacy bare `bool` (bidirectional back-compat: an old native side ↔ a
  /// new Dart side, and vice-versa, both work). Use [connectDetailed] when the
  /// strategy / native error are wanted for the connect trace.
  Future<bool> connect({required String address, required String uuid}) async =>
      (await connectDetailed(address: address, uuid: uuid)).ok;

  /// As [connect] but returning the parsed native result so the connect-trace
  /// can surface WHICH RFCOMM strategy won / the terminal failure mode + the
  /// last native IOException (#2969 correction 5).
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
  }) async {
    final raw = await _methodChannel.invokeMethod<dynamic>(
      'connect',
      {'address': address, 'uuid': uuid},
    );
    return parseClassicConnectResult(raw);
  }

  /// Write [bytes] to the currently-open socket. Throws
  /// [PlatformException] when not connected or the socket's output
  /// stream errors.
  Future<void> write(List<int> bytes) async {
    await _methodChannel.invokeMethod<void>(
      'write',
      {'bytes': Uint8List.fromList(bytes)},
    );
  }

  /// Close the current socket and cancel the reader thread.
  /// Idempotent — safe to call multiple times.
  Future<void> disconnect() async {
    await _methodChannel.invokeMethod<void>('disconnect');
  }

  /// #3183 — the device's `Build.VERSION.SDK_INT` from the native side.
  /// Throws ([MissingPluginException] / [PlatformException] / [StateError])
  /// when the native plugin predates the method or the probe fails — the
  /// caller ([PluginObd2Permissions]) owns the fallback.
  Future<int> sdkInt() async {
    final v = await _methodChannel.invokeMethod<int>('sdkInt');
    if (v == null) {
      throw StateError('sdkInt: native side returned null');
    }
    return v;
  }

  /// Incoming bytes from the socket's input stream, pushed by the
  /// reader thread on the native side. Subscribing starts the
  /// EventChannel; cancelling stops listening but the socket stays
  /// open — call [disconnect] to fully close.
  Stream<List<int>> get incoming => _incomingChannel
      .receiveBroadcastStream()
      .map<List<int>>((event) {
        if (event is List) {
          return event.cast<int>();
        }
        return const <int>[];
      });
}

/// Minimal tuple describing a bonded Classic BT device.
class ClassicBondedDevice {
  final String address;
  final String name;
  const ClassicBondedDevice({required this.address, required this.name});
}

/// Parsed native RFCOMM connect result (#2969). [strategy] names which socket
/// variant won (`secure` / `insecure` / `reflection`) or the terminal failure
/// mode (`exhausted` / `no-adapter` / `bad-address` / `interrupted`); [error]
/// carries the last native IOException message. Both null when the native side
/// returned the legacy bare `bool`.
typedef ClassicConnectResult = ({bool ok, String? strategy, String? error});

/// Parse the native `connect` reply, accepting BOTH the #2969 Map shape
/// `{ok, strategy, error}` AND the legacy bare `bool` (bidirectional
/// back-compat). A null reply (channel returned nothing) is treated as a clean
/// failure. Tolerant of a `Map<dynamic, dynamic>` (the platform-channel codec
/// hands maps back loosely typed).
ClassicConnectResult parseClassicConnectResult(Object? raw) {
  if (raw is bool) return (ok: raw, strategy: null, error: null);
  if (raw is Map) {
    final ok = raw['ok'];
    return (
      ok: ok is bool ? ok : false,
      strategy: raw['strategy'] as String?,
      error: raw['error'] as String?,
    );
  }
  // null / unexpected shape → clean failure.
  return (ok: false, strategy: null, error: null);
}
