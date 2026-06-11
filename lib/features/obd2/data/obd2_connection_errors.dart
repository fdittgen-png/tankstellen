// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Typed errors for the OBD2 connection flow (#741).
///
/// Replaces the former catch-all `Exception('OBD-II error: …')` so the
/// UI can render an actionable message for each failure mode. Each
/// type carries a terse message meant to slot into a localised
/// snackbar via the existing `l10n` keys (added alongside #742).
sealed class Obd2ConnectionError implements Exception {
  final String message;
  const Obd2ConnectionError(this.message);

  @override
  String toString() => '$runtimeType: $message';

  /// #2745 — whether this is an EXPECTED, already-user-surfaced connect
  /// condition that the UI handles with a localized snackbar + a fall-through
  /// to the picker, and so must NOT also spool an ERROR trace (the field
  /// trace #5 was an `[ui] Obd2AdapterUnresponsive` ERROR for exactly this).
  ///
  /// `true` for the "adapter off / out of range / ignition off / not bonded"
  /// family ([Obd2AdapterUnresponsive], [Obd2EngineOff], [Obd2ScanTimeout],
  /// [Obd2BluetoothOff], [Obd2DisconnectedException]) — all of which the user
  /// can act on directly. `false` for [Obd2PermissionDenied] (needs a settings
  /// deep-link) and [Obd2ProtocolInitFailed] (a counterfeit-clone diagnostic
  /// worth keeping), which still ERROR-log so a genuine fault stays visible.
  bool get isExpectedUserCondition => switch (this) {
        Obd2AdapterUnresponsive() => true,
        Obd2EngineOff() => true,
        Obd2ScanTimeout() => true,
        Obd2BluetoothOff() => true,
        Obd2DisconnectedException() => true,
        // #3181 — pairing is a user-actionable hardware condition (confirm
        // the OS dialog / power-cycle the adapter), surfaced with its own
        // localized guidance — a breadcrumb, not an ERROR trace.
        Obd2PairingRequired() => true,
        Obd2PermissionDenied() => false,
        Obd2ProtocolInitFailed() => false,
      };
}

/// User refused to grant BLUETOOTH_SCAN / BLUETOOTH_CONNECT on
/// Android 12+, or location on older targets. The UI should offer a
/// "grant" button and — on `permanentlyDenied` — deep-link into
/// system settings.
class Obd2PermissionDenied extends Obd2ConnectionError {
  const Obd2PermissionDenied([super.message = 'Bluetooth permission denied']);
}

/// The OS Bluetooth radio is turned off (#1369). The user has the
/// permission but the adapter itself is disabled — `FlutterBluePlus`
/// rejects `startScan` with `PlatformException(startScan, "Bluetooth
/// must be turned on", ...)` in this state. Surfaced as its own typed
/// error so the picker / VIN reader can render a "Turn on Bluetooth
/// and try again" message instead of leaking the raw plugin exception
/// through the global error handler.
class Obd2BluetoothOff extends Obd2ConnectionError {
  const Obd2BluetoothOff([
    super.message = 'Turn on Bluetooth and try again',
  ]);
}

/// The scan window expired without any known adapter responding.
/// Usually means the vLinker is off, out of range, or the wrong
/// service UUID for its firmware variant.
class Obd2ScanTimeout extends Obd2ConnectionError {
  const Obd2ScanTimeout(
      [super.message = 'No OBD2 adapter found in range']);
}

/// BLE GATT connection succeeded but the ELM327 init sequence
/// (ATZ → ATE0 → ATSP0 → …) never completed. The adapter itself is
/// genuinely unresponsive — the chip is in a bad state, the channel
/// dropped mid-init, or the dongle is faulty. Distinct from
/// [Obd2EngineOff] (#3009): there, the adapter DID answer every AT
/// command and only the vehicle bus was silent.
class Obd2AdapterUnresponsive extends Obd2ConnectionError {
  const Obd2AdapterUnresponsive([
    super.message = 'Adapter did not answer — check the connection and retry',
  ]);
}

/// The adapter connected + initialised fine (every AT command answered)
/// but the vehicle bus was SILENT (#3009): `ATDPN` cached no protocol and
/// `0100` discovery found zero supported PIDs — the ECU never answered the
/// protocol probe (`SEARCHING…STOPPED` / `NO DATA`). The #1 real field
/// condition: a parked car with the ignition off. The ADAPTER is fine; the
/// engine is off. Raised so the UI shows an accurate "start the engine"
/// message instead of wrongly blaming the (working) adapter.
class Obd2EngineOff extends Obd2ConnectionError {
  const Obd2EngineOff([
    super.message =
        'No data from the vehicle — start the engine and retry',
  ]);
}

/// ATZ returned something unrecognisable. Most often this is a
/// counterfeit ELM327 clone whose firmware lies about its
/// capability string. The app keeps the channel open but surfaces
/// the raw string for debugging.
class Obd2ProtocolInitFailed extends Obd2ConnectionError {
  const Obd2ProtocolInitFailed(String rawResponse)
      : super('Adapter returned unexpected init string: $rawResponse');
}

/// BLE pairing/bonding is required but did not complete (#3181). The
/// OBDLink CX family initiates OS pairing via the first CCCD subscribe
/// (`setNotifyValue`) and only ACCEPTS new bonds in the first ~5 minutes
/// after power-on: a setNotify that fails with an authentication /
/// encryption / bonding error — or times out on a FIRST-connect deviceId
/// even under the generous pairing budget — lands here. Actionable
/// guidance: confirm the pairing dialog, or unplug/replug the adapter
/// and retry within 5 minutes.
class Obd2PairingRequired extends Obd2ConnectionError {
  const Obd2PairingRequired([
    super.message = 'Bluetooth pairing required — unplug the adapter, plug '
        'it back in, then retry within 5 minutes',
  ]);
}

/// The Bluetooth transport dropped mid-session (#797). Raised by
/// higher-level code (e.g. [TripRecordingController]) when the
/// scheduler observes a burst of transport errors that indicates the
/// adapter is no longer reachable — the underlying channel itself
/// throws `StateError('Transport closed')` or `TimeoutException`, and
/// the controller classifies those into this typed error so UI code
/// can render the "connection lost" banner without parsing strings.
class Obd2DisconnectedException extends Obd2ConnectionError {
  const Obd2DisconnectedException([
    super.message = 'OBD2 adapter disconnected mid-session',
  ]);
}
