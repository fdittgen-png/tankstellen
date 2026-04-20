import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart' as fbc;

import 'adapter_registry.dart';
import 'classic_elm_channel.dart';
import 'elm_byte_channel.dart';

/// Facade over `flutter_blue_classic` for the Classic-SPP transport
/// path (#761). Mirrors [BluetoothFacade]'s contract — scan yields
/// ranked candidates, [channelFor] hands back an [ElmByteChannel].
///
/// Classic BT does not advertise services the same way BLE does.
/// "Scanning" here means two things: (a) the already-bonded devices
/// list (which is what vLinker FS users have after pairing in
/// Android settings), and (b) optionally a live discovery via
/// `startScan`. We surface bonded devices FIRST because that's the
/// realistic user flow — Classic SPP requires an OS-level pair
/// before any app can connect.
abstract class ClassicBluetoothFacade {
  /// Emit the set of Classic BT candidates — bonded devices first,
  /// then any newly-discovered adapters. The stream completes after
  /// [timeout]. Classic has no RSSI during bonded enumeration, so
  /// [Obd2AdapterCandidate.rssi] is 0 for those entries.
  Stream<List<Obd2AdapterCandidate>> scan({Duration timeout});

  Future<void> stopScan();

  /// Build an un-opened [ElmByteChannel] for [deviceId] using SPP.
  /// The transport layer calls `open()` to actually connect.
  ElmByteChannel channelFor(String deviceId);
}

/// Production impl backed directly by [fbc.FlutterBlueClassic].
class PluginClassicBluetoothFacade implements ClassicBluetoothFacade {
  final fbc.FlutterBlueClassic _plugin;

  PluginClassicBluetoothFacade({fbc.FlutterBlueClassic? plugin})
      : _plugin = plugin ?? fbc.FlutterBlueClassic();

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    final accumulated = <String, Obd2AdapterCandidate>{};

    // Pass 1: bonded devices. Most users pair the vLinker via
    // Android settings; this surfaces those without a scan.
    try {
      final bonded = await _plugin.bondedDevices ?? const [];
      for (final d in bonded) {
        final c = _fromDevice(d);
        if (c != null) accumulated[c.deviceId] = c;
      }
      yield accumulated.values.toList();
    } on Exception catch (e) {
      debugPrint('ClassicBluetoothFacade: bondedDevices failed: $e');
    }

    // Pass 2: live discovery for un-bonded adapters. Only meaningful
    // when the user hasn't paired yet. The plugin's scanResults is
    // hot; we listen for at most [timeout] before completing.
    _plugin.startScan();
    final controller = StreamController<List<Obd2AdapterCandidate>>();
    late StreamSubscription<fbc.BluetoothDevice> sub;
    sub = _plugin.scanResults.listen(
      (d) {
        final c = _fromDevice(d);
        if (c != null) {
          accumulated[c.deviceId] = c;
          controller.add(accumulated.values.toList());
        }
      },
      onError: controller.addError,
    );
    Timer(timeout, () async {
      await sub.cancel();
      _plugin.stopScan();
      await controller.close();
    });
    yield* controller.stream;
  }

  @override
  Future<void> stopScan() async => _plugin.stopScan();

  @override
  ElmByteChannel channelFor(String deviceId) =>
      ClassicElmChannel(address: deviceId, plugin: _plugin);

  /// Map a `flutter_blue_classic` [fbc.BluetoothDevice] onto our
  /// transport-agnostic [Obd2AdapterCandidate]. Returns null when
  /// the device has no name — anonymous Classic devices can't be
  /// matched against the registry's name heuristics.
  Obd2AdapterCandidate? _fromDevice(fbc.BluetoothDevice d) {
    final name = d.name;
    if (name == null || name.isEmpty) return null;
    return Obd2AdapterCandidate(
      deviceId: d.address,
      deviceName: name,
      advertisedServiceUuids: const [],
      rssi: d.rssi ?? 0,
    );
  }
}
