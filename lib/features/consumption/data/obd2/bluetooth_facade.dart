import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'adapter_registry.dart';
import 'elm_byte_channel.dart';
import 'flutter_blue_plus_elm_channel.dart';
import 'obd2_connection_errors.dart';

/// Thin façade over flutter_blue_plus for the connection service
/// (#741). Keeps the plugin API pinned to a small surface we can
/// fake in tests — the connection service only ever talks to this
/// interface, never to `FlutterBluePlus` directly. Rebinding to a
/// different BLE backend (e.g. flutter_reactive_ble or a desktop
/// serial shim) is a matter of swapping the implementation.
abstract class BluetoothFacade {
  /// Emit scan results for devices advertising any of [serviceUuids].
  /// The stream continues until [stopScan] is called. Each emitted
  /// list contains the accumulated candidates so far, not just the
  /// delta, so the UI can render "found N adapters" without
  /// accumulating separately.
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout,
  });

  Future<void> stopScan();

  /// Open a byte channel to the device identified by [deviceId] using
  /// the given [profile] UUIDs. The returned channel is un-opened;
  /// the transport layer calls `open()` to run the GATT dance.
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile);
}

/// Production façade — the only place in the codebase that directly
/// imports `flutter_blue_plus` for the OBD2 flow (apart from the
/// existing `FlutterBluePlusElmChannel`).
class PluginBluetoothFacade implements BluetoothFacade {
  const PluginBluetoothFacade();

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) {
    final controller = StreamController<List<Obd2AdapterCandidate>>();
    final accumulated = <String, Obd2AdapterCandidate>{};

    // #1369 — `FlutterBluePlus.startScan` is async; previously its
    // future was unawaited so a `PlatformException(startScan,
    // "Bluetooth must be turned on", ...)` (BT radio off) leaked to
    // the zone error handler instead of reaching the consumer's
    // onError. Route the rejection back through the controller so
    // the picker / VIN reader sees a typed `Obd2BluetoothOff` (or
    // the original plugin exception for any unrelated failure).
    unawaited(
      FlutterBluePlus.startScan(
        withServices: serviceUuids.map(Guid.new).toList(),
        timeout: timeout,
      ).catchError((Object e, StackTrace st) {
        if (controller.isClosed) return;
        final mapped = _looksBluetoothOff(e) ? const Obd2BluetoothOff() : e;
        controller.addError(mapped, st);
        unawaited(controller.close());
      }),
    );

    final sub = FlutterBluePlus.scanResults.listen(
      (results) {
        for (final r in results) {
          final candidate = Obd2AdapterCandidate(
            deviceId: r.device.remoteId.str,
            deviceName: r.advertisementData.advName.isEmpty
                ? r.device.platformName
                : r.advertisementData.advName,
            advertisedServiceUuids:
                r.advertisementData.serviceUuids.map((g) => g.str).toList(),
            rssi: r.rssi,
          );
          accumulated[candidate.deviceId] = candidate;
        }
        controller.add(accumulated.values.toList());
      },
      onError: controller.addError,
    );

    // Clean up when the caller cancels or the timeout elapses.
    controller.onCancel = () async {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    };
    Timer(timeout, () async {
      await FlutterBluePlus.stopScan();
      await controller.close();
    });

    return controller.stream;
  }

  /// Recognise the platform-channel rejection FlutterBluePlus emits
  /// when the OS Bluetooth radio is disabled. The exact wording comes
  /// from `flutter_blue_plus_android`; matched case-insensitively
  /// against a substring so a future plugin update''s phrasing tweak
  /// does not silently downgrade us to the generic-error path.
  @visibleForTesting
  static bool debugLooksBluetoothOff(Object e) => _looksBluetoothOff(e);

  static bool _looksBluetoothOff(Object e) {
    if (e is! PlatformException) return false;
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains('must be turned on') ||
        msg.contains('bluetooth must be on') ||
        msg.contains('bluetooth_off');
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) {
    final device = BluetoothDevice.fromId(deviceId);
    return FlutterBluePlusElmChannel(
      device,
      uuids: Elm327BleUuids(
        service: Guid(profile.serviceUuid),
        writeChar: Guid(profile.writeCharUuid),
        notifyChar: Guid(profile.notifyCharUuid),
      ),
    );
  }
}
