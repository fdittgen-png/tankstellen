/// Abstract event source for the OS-level Bluetooth auto-connect
/// bridge that drives hands-free trip recording (#1004 phase 2).
///
/// The native Android foreground service (phase 2b — not yet shipped)
/// observes BLE connect / disconnect transitions for the user's paired
/// ELM327 adapter and bridges them through a `MethodChannel` /
/// `EventChannel` into [BackgroundAdapterListener.events]. Tests inject
/// a [FakeBackgroundAdapterListener] from
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

/// The paired adapter has come into BLE range and a session is open.
/// In production this maps to the native foreground service receiving
/// `ACTION_ACL_CONNECTED` (or the equivalent flutter_blue_plus state)
/// for the device matching the configured MAC.
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

/// Production stub for the time between this PR (phase 2a, Dart
/// scaffolding only) and phase 2b (the native Android bridge).
///
/// Every method throws so a Riverpod provider that accidentally wires
/// the coordinator into production before the native bridge is ready
/// fails loudly on the first event read instead of silently consuming
/// every disconnect. This is the same defensive pattern as
/// `UnimplementedError` on a `freezed` `union` arm — the program never
/// reaches the `throw` in practice (the auto-record flow is gated on
/// the `autoRecord` flag in [VehicleProfile], which stays `false` by
/// default), but if someone forgets the gate the failure is loud.
class UnimplementedBackgroundAdapterListener
    implements BackgroundAdapterListener {
  const UnimplementedBackgroundAdapterListener();

  static const String _why =
      'Phase 2 native foreground service not yet implemented '
      '(#1004 phase 2). AutoTripCoordinator should be gated on the '
      'autoRecord vehicle config; until the native bridge lands the '
      'coordinator should never be wired.';

  @override
  Stream<BackgroundAdapterEvent> get events => throw UnimplementedError(_why);

  @override
  Future<void> start({required String mac}) =>
      throw UnimplementedError(_why);

  @override
  Future<void> stop() => throw UnimplementedError(_why);
}
