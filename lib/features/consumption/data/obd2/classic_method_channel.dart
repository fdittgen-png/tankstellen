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

  /// Open an RFCOMM socket to [address] on the Serial Port Profile
  /// UUID. Returns `true` on success. Must be called once per
  /// connection — subsequent calls close the prior socket first.
  Future<bool> connect({required String address, required String uuid}) async {
    final ok = await _methodChannel.invokeMethod<bool>(
      'connect',
      {'address': address, 'uuid': uuid},
    );
    return ok ?? false;
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
