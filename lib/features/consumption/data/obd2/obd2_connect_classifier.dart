// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'obd2_connect_trace.dart';
import 'obd2_connection_errors.dart';

/// Central classifier (#2969 correction 2) mapping any thrown connect error
/// onto an [Obd2ConnectOutcome]. Covers the sealed [Obd2ConnectionError] set +
/// a raw [TimeoutException]; everything else degrades to
/// [Obd2ConnectOutcome.unknown] (the raw `toString()` is kept as failureDetail
/// for triage).
///
/// CALLED in every self-test driver catch arm AND `connectBest()`'s catch, so
/// the permission / BT-off / scan-timeout family — which throw BEFORE
/// `registry.rank()` runs, so `recordScan` never sees them — still produce the
/// right outcome.
Obd2ConnectOutcome classifyObd2ConnectError(Object error) {
  if (error is Obd2PermissionDenied) return Obd2ConnectOutcome.permissionDenied;
  if (error is Obd2BluetoothOff) return Obd2ConnectOutcome.bluetoothOff;
  if (error is Obd2ScanTimeout) return Obd2ConnectOutcome.scanEmpty;
  if (error is Obd2ProtocolInitFailed) {
    return Obd2ConnectOutcome.protocolInitFailed;
  }
  // Obd2AdapterUnresponsive covers BOTH a Classic rfcomm-open `false` (the
  // channel never opened) and a post-open silent-bus probe. The channel layers
  // raise it for the rfcomm-open-fail case with a distinct message; default it
  // to ignitionOff (the #1 real condition — a parked car) so the actionable
  // "turn the ignition on" guidance is the headline, and let a more specific
  // step/outcome stamped earlier (first-wins) override when the channel-open
  // classifier already ran.
  if (error is Obd2AdapterUnresponsive) {
    final msg = error.message.toUpperCase();
    if (msg.contains('CLASSIC') || msg.contains('RFCOMM')) {
      return Obd2ConnectOutcome.rfcommOpenFail;
    }
    return Obd2ConnectOutcome.ignitionOff;
  }
  if (error is Obd2DisconnectedException) return Obd2ConnectOutcome.unknown;
  if (error is TimeoutException) return Obd2ConnectOutcome.initTimeout;
  return Obd2ConnectOutcome.unknown;
}

/// Classify a BLE `channel.open()` failure (#2969 correction 3) onto an
/// [Obd2ConnectOutcome]. Distinct from [classifyObd2ConnectError] because a
/// raw BLE open failure is NOT an [Obd2ConnectionError] — it is an FBP
/// exception / StateError. Recorded INSIDE the channel-open catch BEFORE the
/// scan fallback re-runs, so the real wrong-transport timeout wins (first-wins)
/// over the fallback's scanEmpty.
Obd2ConnectOutcome classifyBleOpenOutcome(Object error) {
  final msg = error.toString().toUpperCase();
  if (msg.contains('133') || msg.contains('GATT_ERROR')) {
    return Obd2ConnectOutcome.gatt133;
  }
  if (msg.contains('TIMED OUT') ||
      msg.contains('TIMEOUT') ||
      error is TimeoutException) {
    return Obd2ConnectOutcome.gattTimeout;
  }
  if (error is StateError &&
      (msg.contains('ELM327 SERVICE') ||
          msg.contains('WRITE CHARACTERISTIC') ||
          msg.contains('NOTIFY CHARACTERISTIC'))) {
    return Obd2ConnectOutcome.serviceNotFound;
  }
  return Obd2ConnectOutcome.unknown;
}
