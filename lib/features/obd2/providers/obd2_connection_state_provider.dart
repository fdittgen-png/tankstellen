// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/adapter_capability.dart';

part 'obd2_connection_state_provider.g.dart';

/// Coarse live state of the app-wide OBD2 adapter connection (#784).
///
/// Mirrors the 3 cases the UI must distinguish:
/// - [idle] — no saved adapter, or Bluetooth off; nothing to show.
/// - [connected] — the adapter is paired and reachable; the app is
///   either actively recording or ready to.
/// - [permissionDenied] — Bluetooth permission not granted; user
///   action required before any further attempts.
enum Obd2ConnectionState {
  idle,
  connected,
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

  /// Runtime capability tier reported by the connected adapter (#1401
  /// phase 6). Populated by [Obd2ConnectionStatus.markConnected] when
  /// the live `Obd2Service` knows its capability after the init-time
  /// `ATI` probe; null on every other state. Surfaced in the vehicle
  /// settings UI so users can tell whether their adapter unlocks
  /// OEM-PID / passive-CAN flows or is bounded to standard PIDs.
  final Obd2AdapterCapability? capability;

  const Obd2ConnectionSnapshot({
    this.state = Obd2ConnectionState.idle,
    this.adapterName,
    this.adapterMac,
    this.capability,
  });

  Obd2ConnectionSnapshot copyWith({
    Obd2ConnectionState? state,
    String? adapterName,
    String? adapterMac,
    Obd2AdapterCapability? capability,
    bool clearAdapter = false,
    bool clearCapability = false,
  }) =>
      Obd2ConnectionSnapshot(
        state: state ?? this.state,
        adapterName: clearAdapter ? null : (adapterName ?? this.adapterName),
        adapterMac: clearAdapter ? null : (adapterMac ?? this.adapterMac),
        capability: clearCapability ? null : (capability ?? this.capability),
      );

  /// Whether the status dot should render at all. No saved adapter →
  /// no dot; keeps the first-run UI clutter-free.
  bool get hasVisibleIndicator =>
      state != Obd2ConnectionState.idle || adapterName != null;
}

/// App-wide owner of the OBD2 connection status (#784).
@Riverpod(keepAlive: true)
class Obd2ConnectionStatus extends _$Obd2ConnectionStatus {
  @override
  Obd2ConnectionSnapshot build() => const Obd2ConnectionSnapshot();

  /// Record that the adapter is now connected.
  ///
  /// [capability] should be the value read from the live
  /// `Obd2Service.capability` getter after init completes (#1401
  /// phase 6). When null, the snapshot keeps any prior capability —
  /// useful for callers that already stamped it via an earlier
  /// transition and only want to flip the state.
  void markConnected({
    String? adapterName,
    String? adapterMac,
    Obd2AdapterCapability? capability,
  }) {
    state = state.copyWith(
      state: Obd2ConnectionState.connected,
      adapterName: adapterName,
      adapterMac: adapterMac,
      capability: capability,
    );
  }

  void markPermissionDenied() {
    state = state.copyWith(
      state: Obd2ConnectionState.permissionDenied,
      clearCapability: true,
    );
  }

  /// Forget the saved adapter entirely. Called when the user taps
  /// "Disconnect" / "Forget" from the popover.
  void markIdle() {
    state = const Obd2ConnectionSnapshot();
  }
}
