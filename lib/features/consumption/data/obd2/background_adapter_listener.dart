// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Abstract event source for the OS-level Bluetooth auto-connect
/// bridge that drives hands-free trip recording (#1004 phase 2).
///
/// The native Android foreground service (shipped as
/// [AndroidBackgroundAdapterListener] + the Kotlin
/// `AutoRecordForegroundService`) observes BLE connect / disconnect
/// transitions for the user's paired ELM327 adapter and bridges them
/// through a `MethodChannel` / `EventChannel` into
/// [BackgroundAdapterListener.events]. The service `<service>` entry is
/// currently commented out in the manifest pending the Google Play
/// "Foreground Service Use" form (#1498); while it is disabled, the
/// foreground-active arming fallback (#2282 concern 1) drives
/// engine-start detection from the live engine instead. Tests inject a
/// [FakeBackgroundAdapterListener] from
/// `fake_background_adapter_listener.dart` to drive the
/// [AutoTripCoordinator] state machine deterministically without any
/// real Bluetooth stack.
///
/// The interface deliberately exposes only what the coordinator needs
/// (start watching a single MAC, stop watching, observe a stream of
/// connect / disconnect events). RSSI, advertisement data, and other
/// scan metadata stay encapsulated inside the bridge — the auto-record
/// flow only cares whether the paired adapter is reachable right now.
library;

/// Sealed envelope for everything the listener emits. Sealed so the
/// coordinator's `switch` is exhaustively checked at compile time —
/// adding a new event type (e.g. `AdapterUnavailable`) forces every
/// consumer to acknowledge it.
sealed class BackgroundAdapterEvent {
  /// MAC address of the adapter the event refers to. The coordinator
  /// filters on this value so events for a different paired vehicle do
  /// not trigger a trip on the active one.
  String get mac;

  /// Wall-clock instant the bridge observed the transition. Sourced
  /// from the platform side so a delay between native delivery and
  /// Dart processing does not skew the disconnect-save timer window.
  DateTime get at;

  const BackgroundAdapterEvent();
}

/// The paired adapter has come into BLE range and a GATT link is up.
/// In production this maps to the native foreground service's
/// `BluetoothGattCallback.onConnectionStateChange` reporting
/// `STATE_CONNECTED` for the device matching the configured MAC (the
/// service holds an `autoConnect=true` GATT client, not an
/// `ACTION_ACL_CONNECTED` broadcast receiver).
class AdapterConnected extends BackgroundAdapterEvent {
  @override
  final String mac;
  @override
  final DateTime at;

  const AdapterConnected({required this.mac, required this.at});

  @override
  String toString() => 'AdapterConnected(mac=$mac, at=$at)';
}

/// The paired adapter has dropped — either the user walked out of
/// range, parked and stepped out of the car, or a transient BLE glitch
/// kicked the link. The coordinator does NOT save immediately; it
/// starts a debounce timer (configurable via
/// `disconnectSaveDelaySec`) so that a brief re-pair does not leave a
/// half-saved trip in the history list.
class AdapterDisconnected extends BackgroundAdapterEvent {
  @override
  final String mac;
  @override
  final DateTime at;

  const AdapterDisconnected({required this.mac, required this.at});

  @override
  String toString() => 'AdapterDisconnected(mac=$mac, at=$at)';
}

/// The contract the coordinator binds against. Production wires this
/// to the native foreground service via a `MethodChannel`; tests wire
/// it to [FakeBackgroundAdapterListener].
abstract class BackgroundAdapterListener {
  /// Broadcast stream of connect / disconnect transitions. Late
  /// subscribers MUST be tolerated — the coordinator may attach after
  /// the native bridge has already started emitting; the listener is
  /// responsible for buffering or replaying the most recent state if
  /// that matters for its implementation. (The fake uses a broadcast
  /// stream, which simply drops events with no live subscriber; the
  /// production bridge gates emission on `start` so this is moot in
  /// practice.)
  Stream<BackgroundAdapterEvent> get events;

  /// Begin listening for transitions on [mac]. Idempotent: calling
  /// `start` twice with the same MAC is a no-op; calling it with a
  /// different MAC implicitly stops the previous watch. Must be called
  /// before the coordinator subscribes to [events]; the production
  /// bridge will not deliver events until `start` arms it.
  Future<void> start({required String mac});

  /// Stop watching. Releases native resources (the foreground service
  /// may keep running for other consumers; the bridge unregisters its
  /// own subscriber). Safe to call when no watch is active.
  Future<void> stop();
}

/// Non-Android stub for the background bridge.
///
/// The Android foreground-service bridge ships as
/// [AndroidBackgroundAdapterListener]; this stub stands in only on
/// platforms that have no native background BLE bridge yet (iOS,
/// desktop). The orchestrator constructs it solely when
/// `defaultTargetPlatform` is non-Android, so non-Android builds keep
/// compiling without a runtime arming. Every method throws so that if a
/// future caller ever wires it into a live flow on such a platform, the
/// mistake fails loudly on the first event read instead of silently
/// swallowing connect/disconnect transitions. (On those platforms the
/// foreground-active arming fallback — #2282 concern 1 — provides
/// engine-start detection while the app is in front.)
class UnimplementedBackgroundAdapterListener
    implements BackgroundAdapterListener {
  const UnimplementedBackgroundAdapterListener();

  static const String _why =
      'No native background BLE bridge on this platform — '
      'UnimplementedBackgroundAdapterListener is a non-Android stub and '
      'must not be wired into a live auto-record flow. The orchestrator '
      'only constructs it on non-Android platforms to keep builds '
      'compiling; engine detection there uses the foreground-active arm.';

  @override
  Stream<BackgroundAdapterEvent> get events => throw UnimplementedError(_why);

  @override
  Future<void> start({required String mac}) =>
      throw UnimplementedError(_why);

  @override
  Future<void> stop() => throw UnimplementedError(_why);
}
