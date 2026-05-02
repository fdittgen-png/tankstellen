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
/// (ATZ → ATE0 → ATSP0 → …) never completed. The adapter is
/// paired at the OS level but unresponsive — usually because the
/// vehicle ignition is off or the chip is in a bad state.
class Obd2AdapterUnresponsive extends Obd2ConnectionError {
  const Obd2AdapterUnresponsive([
    super.message = 'Adapter did not answer — turn the ignition on and retry',
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
