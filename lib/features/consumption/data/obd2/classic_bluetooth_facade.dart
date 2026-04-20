import 'dart:async';

import 'package:flutter/foundation.dart';

import 'adapter_registry.dart';
import 'classic_elm_channel.dart';
import 'classic_method_channel.dart';
import 'elm_byte_channel.dart';

/// Facade over the Classic Bluetooth transport for OBD2 adapters
/// (#761 abstraction, #763 real impl).
///
/// Classic BT adapters are paired through Android's Bluetooth
/// settings and then enumerated via the OS `bondedDevices` list.
/// The picker UI surfaces bonded adapters only — discovery of
/// un-paired adapters is out of scope; the usage flow is "pair
/// once, use forever".
abstract class ClassicBluetoothFacade {
  /// Emit the set of Classic BT candidates. Classic has no RSSI
  /// during bonded enumeration, so [Obd2AdapterCandidate.rssi] is 0.
  Stream<List<Obd2AdapterCandidate>> scan({Duration timeout});

  Future<void> stopScan();

  /// Build an un-opened [ElmByteChannel] for [deviceId] using SPP.
  /// The transport layer calls `open()` to actually connect.
  ElmByteChannel channelFor(String deviceId);
}

/// Production impl wiring the native [Obd2ClassicMethodChannel]
/// plugin (#763). All I/O goes through the MethodChannel pair
/// registered by `Obd2ClassicPlugin.kt`.
class PluginClassicBluetoothFacade implements ClassicBluetoothFacade {
  final Obd2ClassicMethodChannel _plugin;

  const PluginClassicBluetoothFacade({
    Obd2ClassicMethodChannel plugin = const Obd2ClassicMethodChannel(),
  }) : _plugin = plugin;

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    try {
      final bonded = await _plugin.bondedDevices();
      yield bonded
          .map((d) => Obd2AdapterCandidate(
                deviceId: d.address,
                deviceName: d.name,
                advertisedServiceUuids: const [],
                rssi: 0,
              ))
          .toList();
    } on Exception catch (e) {
      debugPrint('PluginClassicBluetoothFacade: bondedDevices failed: $e');
    }
  }

  @override
  Future<void> stopScan() async {
    // Bonded-only enumeration is instant; nothing to cancel.
  }

  @override
  ElmByteChannel channelFor(String deviceId) =>
      ClassicElmChannel(address: deviceId, plugin: _plugin);
}
