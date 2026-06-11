// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// #3181 — process-wide FIRST-CONNECT pairing mode.
///
/// The OBDLink CX (and other secure-BLE adapters) initiates OS-level
/// pairing via the FIRST CCCD subscribe (`setNotifyValue`): on a
/// never-bonded phone that call BLOCKS on the OS pairing dialog until the
/// human taps "Pair". The steady-state setNotify budget (iOS 7 s /
/// Android 4 s, #3118/#3014) clips that tap, so a first connect could
/// only ever time out mid-pairing — and the adapter only accepts new
/// bonds in the first ~5 minutes after power-on, so every later retry
/// timed out at setNotify until the adapter was power-cycled.
///
/// [Obd2ConnectionService] marks a deviceId here when its store says the
/// device has NEVER completed a successful connect; the BLE channel then
/// widens the setNotify budget to [firstConnectSetNotifySecs] and flips
/// [pairingWaitPending] while the (possibly pairing-blocked) subscribe is
/// in flight so the UI can show "confirm the pairing request" guidance.
///
/// Static ambient state (the [Obd2ConnectTraceLog] precedent): the
/// channel is constructed by the facade layer, which has no seam to
/// thread a per-connect policy through without breaking every fake.
/// Single-isolate like the rest of the OBD2 stack — no synchronisation.
class Obd2PairingMode {
  Obd2PairingMode._();

  /// Generous setNotify budget for a FIRST connect (#3181): the CCCD
  /// subscribe may block on the OS pairing dialog, and a human needs
  /// time to read + tap it. 30 s is well inside the adapter's ~5-minute
  /// pairing-acceptance window while still bounding a genuinely dead
  /// adapter.
  static const int firstConnectSetNotifySecs = 30;

  static final Set<String> _firstConnectIds = <String>{};

  static String _norm(String deviceId) => deviceId.trim().toUpperCase();

  /// Arm first-connect pairing mode for [deviceId]. No-op for an empty id.
  static void markFirstConnect(String deviceId) {
    final id = _norm(deviceId);
    if (id.isEmpty) return;
    _firstConnectIds.add(id);
  }

  /// Disarm first-connect pairing mode for [deviceId]. Idempotent.
  static void clearFirstConnect(String deviceId) {
    _firstConnectIds.remove(_norm(deviceId));
  }

  /// Whether [deviceId] is currently in first-connect pairing mode.
  static bool isFirstConnect(String deviceId) =>
      _firstConnectIds.contains(_norm(deviceId));

  /// The setNotify budget (seconds) the BLE channel should use for
  /// [deviceId]: the generous [firstConnectSetNotifySecs] while the id is
  /// in first-connect mode, otherwise the caller's steady-state
  /// [platformDefaultSecs] (#3118 — iOS 7 / Android 4, untouched).
  static int setNotifyBudgetSecsFor(
    String deviceId, {
    required int platformDefaultSecs,
  }) =>
      isFirstConnect(deviceId)
          ? firstConnectSetNotifySecs
          : platformDefaultSecs;

  /// True while a FIRST-CONNECT setNotify — the call that can block on
  /// the OS pairing dialog — is in flight. The picker's connecting view
  /// listens and shows the "confirm the pairing request on your phone"
  /// hint while it is true.
  static final ValueNotifier<bool> pairingWaitPending =
      ValueNotifier<bool>(false);

  /// Flip [pairingWaitPending] on. Never throws (#1103) — a throwing UI
  /// listener must not derail the connect path.
  static void notePairingWaitStarted() {
    try {
      pairingWaitPending.value = true;
    } catch (e, st) {
      debugPrint('Obd2PairingMode: pairingWaitPending listener threw '
          '(ignored): $e\n$st');
    }
  }

  /// Flip [pairingWaitPending] off. Never throws (#1103).
  static void notePairingWaitEnded() {
    try {
      pairingWaitPending.value = false;
    } catch (e, st) {
      debugPrint('Obd2PairingMode: pairingWaitPending listener threw '
          '(ignored): $e\n$st');
    }
  }

  /// Test reset — drops every marked id and the pending flag.
  @visibleForTesting
  static void resetForTest() {
    _firstConnectIds.clear();
    pairingWaitPending.value = false;
  }
}
