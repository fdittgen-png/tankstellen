// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'obd2_comm_diagnostics.dart';

/// Best-effort BLE link tuning for an OBD2 recording session (#2261
/// concern 4), extracted from [FlutterBluePlusElmChannel] (#2907) so the
/// channel file stays under the #1680 400-line cap. Pure move — behaviour is
/// preserved.
///
/// Every request here is best-effort: Android-only (FBP throws `androidOnly`
/// elsewhere) and routinely rejected by ELM327 clones, so every call is
/// guarded — a rejection must never break an otherwise-healthy session.
class BleLinkTuner {
  /// #2261 concern 4 — best-effort MTU to request on a high-throughput
  /// (recording) link. 247 is the practical ATT payload ceiling on most
  /// Android BLE stacks; the negotiated value is whatever the peripheral
  /// grants. Skipped on the autoConnect passive path (FBP forbids requestMtu).
  static const int recordingMtu = 247;

  const BleLinkTuner();

  /// Bump to high connection priority + request the recording MTU. Skipped on
  /// the passive autoConnect path ([autoConnect] true) — FBP forbids
  /// requestMtu with autoConnect, and a parked-car wait wants low power.
  Future<void> tuneForRecording(
    BluetoothDevice device, {
    required bool autoConnect,
  }) async {
    await _setConnectionPriority(device, ConnectionPriority.high);
    if (autoConnect) return;
    try {
      final granted = await device.requestMtu(recordingMtu);
      // #2466 — record the negotiated ATT MTU into the gated comm-health
      // session (no-op unless Feature.debugMode armed the collector). The
      // peripheral may grant less than requested; the granted value wins.
      final diag = Obd2CommDiagnostics.instance;
      if (diag.enabled) diag.recordAdapterIdentity(mtu: granted);
    } catch (e, st) {
      // Many clones reject a non-default MTU — harmless, the default 23-byte
      // MTU still works. PHY (2M) is deliberately NOT requested (a clone trap).
      debugPrint('BleLinkTuner requestMtu skipped: $e\n$st');
    }
  }

  /// Drop to balanced connection priority when only the 1 Hz auto-record
  /// stream is live (#2261 concern 4).
  Future<void> tuneForBackground(BluetoothDevice device) =>
      _setConnectionPriority(device, ConnectionPriority.balanced);

  Future<void> _setConnectionPriority(
    BluetoothDevice device,
    ConnectionPriority priority,
  ) async {
    try {
      await device.requestConnectionPriority(
        connectionPriorityRequest: priority,
      );
    } catch (e, st) {
      debugPrint('BleLinkTuner requestConnectionPriority skipped: $e\n$st');
    }
  }
}
