import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'obd2_connection_state_provider.g.dart';

/// Coarse live state of the app-wide OBD2 adapter connection (#784).
///
/// Mirrors the 5 cases the UI must distinguish:
/// - [idle] — no saved adapter, or Bluetooth off; nothing to show.
/// - [attempting] — a background reconnect is in flight.
/// - [connected] — the adapter is paired and reachable; the app is
///   either actively recording or ready to.
/// - [unreachable] — the last attempt failed (adapter off, out of
///   range, already in use by another app). Retries in backoff.
/// - [permissionDenied] — Bluetooth permission not granted; user
///   action required before any further attempts.
enum Obd2ConnectionState {
  idle,
  attempting,
  connected,
  unreachable,
  permissionDenied,
}

/// Snapshot observed by every screen via the shell-wide status dot
/// (#784). Carries the state + (when available) the adapter label so
/// the popover can render "Connected to vLinker FS" without a second
/// provider lookup.
@immutable
class Obd2ConnectionSnapshot {
  final Obd2ConnectionState state;
  final String? adapterName;
  final String? adapterMac;

  const Obd2ConnectionSnapshot({
    this.state = Obd2ConnectionState.idle,
    this.adapterName,
    this.adapterMac,
  });

  Obd2ConnectionSnapshot copyWith({
    Obd2ConnectionState? state,
    String? adapterName,
    String? adapterMac,
    bool clearAdapter = false,
  }) =>
      Obd2ConnectionSnapshot(
        state: state ?? this.state,
        adapterName: clearAdapter ? null : (adapterName ?? this.adapterName),
        adapterMac: clearAdapter ? null : (adapterMac ?? this.adapterMac),
      );

  /// Whether the status dot should render at all. No saved adapter →
  /// no dot; keeps the first-run UI clutter-free.
  bool get hasVisibleIndicator =>
      state != Obd2ConnectionState.idle || adapterName != null;
}

/// App-wide owner of the OBD2 connection status (#784).
///
/// Phase-1 scope: state machine + API for callers (boot probe,
/// manual disconnect, permission changes) to drive it. The actual
/// boot-time Bluetooth scan + auto-connect isolate is deferred to
/// the follow-up PR so this lands without coupling to the native
/// plugin surface.
@Riverpod(keepAlive: true)
class Obd2ConnectionStatus extends _$Obd2ConnectionStatus {
  @override
  Obd2ConnectionSnapshot build() => const Obd2ConnectionSnapshot();

  /// Record that a connection attempt is starting for the saved
  /// [adapterName] / [adapterMac]. Called by the boot probe and by
  /// manual retry actions.
  void markAttempting({required String adapterName, required String adapterMac}) {
    state = state.copyWith(
      state: Obd2ConnectionState.attempting,
      adapterName: adapterName,
      adapterMac: adapterMac,
    );
  }

  /// Record that the adapter is now connected. Preserves the
  /// adapter label in case a previous [markAttempting] never fired
  /// (e.g. on a reconnection from a persisted cache).
  void markConnected({String? adapterName, String? adapterMac}) {
    state = state.copyWith(
      state: Obd2ConnectionState.connected,
      adapterName: adapterName,
      adapterMac: adapterMac,
    );
  }

  /// Record that the last attempt failed. The adapter label stays
  /// so the popover can still name the thing the app is trying to
  /// reach.
  void markUnreachable() {
    state = state.copyWith(state: Obd2ConnectionState.unreachable);
  }

  void markPermissionDenied() {
    state = state.copyWith(state: Obd2ConnectionState.permissionDenied);
  }

  /// Forget the saved adapter entirely. Called when the user taps
  /// "Disconnect" / "Forget" from the popover.
  void markIdle() {
    state = const Obd2ConnectionSnapshot();
  }
}
