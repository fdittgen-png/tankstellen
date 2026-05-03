import 'package:flutter/foundation.dart';

/// Sealed event published by [IosStateRestorationService] when iOS
/// relaunches the app via Core Bluetooth state restoration
/// (#1295 phase 2).
///
/// Modelled as a Dart-3 sealed class — we don't use Freezed here
/// because the codebase has no precedent for multi-constructor
/// Freezed unions and a native sealed class gives us exhaustive
/// `switch` matching without a code-generation step. Equivalent to
/// the "Freezed sealed class" called for in the issue body — same
/// shape, fewer moving parts.
///
/// ## Variants
///
/// * [IosRestorationWillRestore] — emitted on iOS when
///   `centralManager:willRestoreState:` fires after a background
///   relaunch. Carries the list of CBPeripheral identifiers (UUID
///   strings, not MAC addresses — iOS hides the hardware MAC) that
///   the OS handed back to us. The service consumer (Phase 3 — BLE
///   listener + speed source + trip lifecycle) will rehydrate these
///   into `BluetoothDevice` instances and resume reading from the
///   already-connected peripheral.
///
/// * [IosRestorationNotSupported] — emitted on every non-iOS
///   platform (Android, Linux desktop tests, headless CI). The
///   sealed-class shape lets the consumer switch on it explicitly
///   instead of guarding every callsite with `Platform.isIOS`.
@immutable
sealed class IosRestorationEvent {
  const IosRestorationEvent();

  /// Convenience factory mirroring Freezed's named-constructor API
  /// so callers read `IosRestorationEvent.willRestore([...])`
  /// instead of the longer `IosRestorationWillRestore([...])`.
  /// Pure forwarder — no allocation or behaviour beyond that.
  const factory IosRestorationEvent.willRestore(
    List<String> peripheralUuids,
  ) = IosRestorationWillRestore;

  /// Convenience factory mirroring Freezed's named-constructor API
  /// for the no-op variant. Returns the `const` singleton so
  /// repeated `notSupported()` calls don't allocate.
  const factory IosRestorationEvent.notSupported() =
      IosRestorationNotSupported;
}

/// "iOS relaunched us via Core Bluetooth state restoration" event.
///
/// [peripheralUuids] is the list of `CBPeripheral.identifier.uuidString`
/// values the OS handed back. Empty list means iOS restored state
/// but no peripherals were tracked — still a useful signal for
/// breadcrumb logging in Phase 3.
final class IosRestorationWillRestore extends IosRestorationEvent {
  /// Peripheral UUIDs (CBPeripheral.identifier.uuidString) that iOS
  /// rehydrated for us. Phase 3 maps these to flutter_blue_plus
  /// `BluetoothDevice.fromId` instances.
  final List<String> peripheralUuids;

  const IosRestorationWillRestore(this.peripheralUuids);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IosRestorationWillRestore &&
          listEquals(other.peripheralUuids, peripheralUuids);

  @override
  int get hashCode => Object.hashAll(peripheralUuids);

  @override
  String toString() =>
      'IosRestorationEvent.willRestore(peripheralUuids: $peripheralUuids)';
}

/// "This platform doesn't support iOS state restoration" event.
///
/// Android emits this as the single value on the
/// `IosStateRestorationService.events` stream so consumers can
/// switch exhaustively without a `Platform.isIOS` guard.
final class IosRestorationNotSupported extends IosRestorationEvent {
  const IosRestorationNotSupported();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IosRestorationNotSupported;

  @override
  int get hashCode => (IosRestorationNotSupported).hashCode;

  @override
  String toString() => 'IosRestorationEvent.notSupported()';
}
