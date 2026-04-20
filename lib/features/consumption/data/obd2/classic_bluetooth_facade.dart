import 'dart:async';

import 'adapter_registry.dart';
import 'classic_elm_channel.dart';
import 'elm_byte_channel.dart';

/// Facade over the Classic Bluetooth transport for OBD2 adapters
/// (#761). Mirrors [BluetoothFacade]'s contract — scan yields ranked
/// candidates, [channelFor] hands back an [ElmByteChannel] the
/// transport layer can drive.
///
/// Classic Bluetooth does not advertise services the way BLE does:
/// adapters are paired through Android's Bluetooth settings, then
/// enumerated via the OS `bondedDevices` list. Our picker UI
/// ultimately wants to surface bonded adapters first, then any
/// newly-discovered ones from a live scan.
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

/// Placeholder production impl that surfaces the Classic path
/// without yet wiring a real platform plugin. Rationale: the popular
/// `flutter_blue_classic` package is GPL-3 licensed, incompatible
/// with this MIT project. The license-clean replacement — either a
/// native MethodChannel or a future MIT-licensed plugin — is tracked
/// as a follow-up on #761.
///
/// Until the real impl lands, `scan()` completes immediately with an
/// empty list (no adapters surface) and `channelFor` returns a
/// [ClassicElmChannel] whose `open()` throws so the connection
/// service translates it to `Obd2AdapterUnresponsive` for the UI.
/// Tests inject a concrete fake that implements the abstract
/// contract properly, so unit coverage is unaffected.
class StubClassicBluetoothFacade implements ClassicBluetoothFacade {
  const StubClassicBluetoothFacade();

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // Intentionally empty: no Classic adapters surface until the
    // real platform wrapper ships. See class doc.
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId) =>
      ClassicElmChannel(address: deviceId);
}
