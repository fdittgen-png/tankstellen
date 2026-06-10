// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// #3182 — bounded wait for the Bluetooth adapter to report `poweredOn`
/// before the FIRST scan / connect is dispatched.
///
/// FBP's darwin side creates the `CBCentralManager` LAZILY in the first
/// method call and immediately rejects a scan/connect issued while the
/// manager still reports state `unknown` ("bluetooth must be turned on.
/// (unknown)") — i.e. the very first BLE action after a cold app launch
/// failed spuriously even though the radio was on. Waiting (bounded) for
/// `adapterState == on` lets CoreBluetooth finish powering the manager up.
///
/// Best-effort by contract:
///   * a genuinely-off adapter never emits `on`, so the wait times out and
///     the caller FALLS THROUGH to the existing dispatch — whose rejection
///     still maps to the proper typed [Obd2BluetoothOff];
///   * any probe failure (platform channel quirk) is logged and swallowed —
///     the gate must never block or fail a scan/connect on its own.
///
/// [states] is injectable for tests (`FlutterBluePlus.adapterState` is a
/// static and unfakeable otherwise).
Future<void> waitForAdapterOn({
  Stream<BluetoothAdapterState>? states,
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    await (states ?? FlutterBluePlus.adapterState)
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(timeout);
  } on TimeoutException {
    // Adapter never reported `on` within the budget — either genuinely off
    // (the caller's dispatch surfaces the typed Obd2BluetoothOff) or a slow
    // platform; either way the caller proceeds.
  } catch (_) {
    // Best-effort gate: a failing adapterState probe — a platform-channel
    // quirk, a missing plugin in a test harness, or the state stream ending
    // without an `on` (StateError from `.first`) — must never block or fail
    // the scan/connect that follows; the dispatch's own error mapping owns
    // surfacing real conditions.
  }
}
