// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// #2900 — true when [e] is flutter_blue_plus's signal that the BLE adapter
/// dropped mid-write / mid-session, so the write should be reclassified into
/// the recoverable `Obd2DisconnectedException` rather than escaping as a raw
/// exception that floods the error log (error-log #23: a raw
/// `FlutterBluePlusException | writeCharacteristic | fbp-code: 6 | device is
/// not connected` spooled 25× as the ~1 Hz speed poller kept writing into a
/// dropped link). Mirrors the #2671 [ClassicElmChannel] + #2524
/// [BluetoothObd2Transport] reclassification precedents.
///
/// Matches:
/// - [FlutterBluePlusException] with `fbp-code: 6` (the observed
///   "device is not connected" write failure), or whose description says the
///   device is not connected / disconnected;
/// - [FlutterBluePlusException] / [PlatformException] carrying Android
///   GATT_ERROR 133 — the "stack gave up" code seen mid-write on a dying link
///   (an established session, not the connect-time stale-GATT case);
/// - [PlatformException] whose code/message says the device is not connected /
///   disconnected.
///
/// A genuine non-disconnect BLE error (e.g. a clone rejecting a write mode)
/// returns false and still surfaces unchanged.
bool isBleAdapterDisconnect(Object e) {
  if (e is FlutterBluePlusException) {
    if (e.code == 6 || e.code == 133) return true;
    return _mentionsDisconnect(e.description);
  }
  if (e is PlatformException) {
    if (e.code == '133') return true;
    return _mentionsDisconnect(e.code) || _mentionsDisconnect(e.message);
  }
  return false;
}

bool _mentionsDisconnect(String? text) {
  if (text == null) return false;
  final t = text.toLowerCase();
  return t.contains('not connected') ||
      t.contains('disconnected') ||
      t.contains('gatt_error') ||
      t.contains('133');
}

/// Bin a BLE `open()` failure into a stable, low-cardinality reason tag for the
/// gated comm-diagnostics `failuresByReason` map (#2466). Kept coarse +
/// platform-derived so an exported error-log shows *why* a connect failed
/// (GATT timeout vs missing ELM service vs other) without leaking a
/// high-cardinality raw message.
String classifyBleConnectFailure(Object e) {
  final msg = e.toString().toUpperCase();
  if (msg.contains('TIMEOUT') || msg.contains('GATT_CONNECTION_TIMEOUT')) {
    return 'gatt-connection-timeout';
  }
  // Android GATT_ERROR 133 — the catch-all "stack gave up" code, most often a
  // stale GATT client or an out-of-range adapter.
  if (msg.contains('133') || msg.contains('GATT_ERROR')) {
    return 'gatt-error-133';
  }
  // The service / characteristic discovery `StateError`s thrown during open().
  if (e is StateError &&
      (msg.contains('ELM327 SERVICE') ||
          msg.contains('WRITE CHARACTERISTIC') ||
          msg.contains('NOTIFY CHARACTERISTIC'))) {
    return 'service-not-found';
  }
  return 'other';
}
