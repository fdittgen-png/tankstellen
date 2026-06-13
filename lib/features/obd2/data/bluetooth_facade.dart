// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'adapter_registry.dart';
import 'ble_adapter_state_gate.dart';
import 'elm_byte_channel.dart';
import 'flutter_blue_plus_elm_channel.dart';
import 'obd2_connection_errors.dart';
import 'obd2_scan_governor.dart';

/// Thin façade over flutter_blue_plus for the connection service
/// (#741). Keeps the plugin API pinned to a small surface we can
/// fake in tests — the connection service only ever talks to this
/// interface, never to `FlutterBluePlus` directly. Rebinding to a
/// different BLE backend (e.g. flutter_reactive_ble or a desktop
/// serial shim) is a matter of swapping the implementation.
abstract class BluetoothFacade {
  /// Emit scan results for devices advertising any of [serviceUuids].
  /// The stream continues until [stopScan] is called. Each emitted
  /// list contains the accumulated candidates so far, not just the
  /// delta, so the UI can render "found N adapters" without
  /// accumulating separately.
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout,
  });

  Future<void> stopScan();

  /// Open a byte channel to the device identified by [deviceId] using
  /// the given [profile] UUIDs. The returned channel is un-opened;
  /// the transport layer calls `open()` to run the GATT dance.
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile);

  /// Build a byte channel straight from a known [mac] with NO scan
  /// (#2242). Used by the direct-connect reconnect / pre-warm path:
  /// `BluetoothDevice.fromId(mac)` addresses the adapter without first
  /// re-discovering it over the air, which is essential for clones that
  /// stop advertising in standby. No scan means no resolved profile, so
  /// the generic FFF0 Nordic-UART UUIDs are used — the dominant ELM327
  /// clone family. The returned channel's `open()` applies a bounded
  /// connect timeout and tears down any stale GATT client first
  /// (Android returns GATT_ERROR 133 otherwise). The channel is
  /// un-opened; the caller runs `open()`.
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout,
    bool autoConnect,
  });
}

/// Production façade — the only place in the codebase that directly
/// imports `flutter_blue_plus` for the OBD2 flow (apart from the
/// existing `FlutterBluePlusElmChannel`).
class PluginBluetoothFacade implements BluetoothFacade {
  const PluginBluetoothFacade();

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) {
    final controller = StreamController<List<Obd2AdapterCandidate>>();
    final accumulated = <String, Obd2AdapterCandidate>{};

    // #1369 — `FlutterBluePlus.startScan` is async; previously its
    // future was unawaited so a `PlatformException(startScan,
    // "Bluetooth must be turned on", ...)` (BT radio off) leaked to
    // the zone error handler instead of reaching the consumer's
    // onError. Route the rejection back through the controller so
    // the picker / VIN reader sees a typed `Obd2BluetoothOff` (or
    // the original plugin exception for any unrelated failure).
    // #3182 — wait (bounded) for `adapterState == on` BEFORE dispatching the
    // scan. FBP's darwin side creates the CBCentralManager lazily in the
    // first method call and instantly rejects a scan issued while it still
    // reports `unknown` — the first post-launch scan failed spuriously on
    // iOS. On timeout the scan is dispatched anyway, so a genuinely-off
    // adapter still surfaces the typed Obd2BluetoothOff via the mapping below.
    unawaited(
      waitForAdapterOn()
          .then((_) => FlutterBluePlus.startScan(
                withServices: serviceUuids.map(Guid.new).toList(),
                timeout: timeout,
              ))
          .catchError((Object e, StackTrace st) {
        if (controller.isClosed) return;
        final mapped = _mapBluetoothError(e);
        controller.addError(mapped, st);
        unawaited(controller.close());
      }),
    );

    final sub = FlutterBluePlus.scanResults.listen(
      (results) {
        for (final r in results) {
          final candidate = Obd2AdapterCandidate(
            deviceId: r.device.remoteId.str,
            deviceName: r.advertisementData.advName.isEmpty
                ? r.device.platformName
                : r.advertisementData.advName,
            advertisedServiceUuids:
                r.advertisementData.serviceUuids.map((g) => g.str).toList(),
            rssi: r.rssi,
            // #3097 — this facade IS the BLE transport, so every hit it
            // surfaces was discovered over BLE. resolve() uses this to send a
            // generic-named clone to a BLE profile (which connects on iOS),
            // not the Classic-only generic fallback.
            discoveryTransport: BluetoothTransport.ble,
          );
          accumulated[candidate.deviceId] = candidate;
        }
        _safeAddScanResults(controller, accumulated.values.toList());
      },
      // #1392 — mirror the explicit-future catchError above. Without
      // this mapping the raw `PlatformException(startScan, "Bluetooth
      // must be turned on", ...)` reaches the consumer (and from there
      // the global zone error handler as `[other] PlatformException`)
      // when FlutterBluePlus rejects via the stream rather than the
      // future. The `isClosed` guard handles the race with the timeout
      // timer below that may have already closed the controller.
      onError: (Object e, StackTrace st) {
        if (controller.isClosed) return;
        controller.addError(_mapBluetoothError(e), st);
      },
    );

    // Clean up when the caller cancels or the timeout elapses. Both
    // paths cancel [sub] FIRST (#2953): a still-live `scanResults`
    // subscription is the source of the late `controller.add` that
    // throws once the controller is closed. `onCancel` fires on a
    // consumer cancel; the timeout `Timer` is the close path that does
    // NOT trigger `onCancel`, so it must cancel [sub] itself.
    controller.onCancel = () async {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    };
    Timer(timeout, () async {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
      await controller.close();
    });

    return controller.stream;
  }

  /// #2953 — guarded feed for the `scanResults` listener. A
  /// `FlutterBluePlus.scanResults` callback can fire AFTER [controller]
  /// was closed (the timeout `Timer` or `onCancel` closed it, but a
  /// result already queued on the event loop still reaches the
  /// listener): the field log #30 spooled `Bad state: Cannot add event
  /// after closing` 14× during the engine-off connect/scan/disconnect
  /// churn. The `onError` path is already `isClosed`-guarded; this
  /// mirrors it for the data path so a late result is dropped silently
  /// instead of throwing into the zone error handler. `@visibleForTesting`
  /// so the guard is unit-tested directly without driving the plugin.
  @visibleForTesting
  static void debugSafeAddScanResults(
    StreamController<List<Obd2AdapterCandidate>> controller,
    List<Obd2AdapterCandidate> results,
  ) =>
      _safeAddScanResults(controller, results);

  static void _safeAddScanResults(
    StreamController<List<Obd2AdapterCandidate>> controller,
    List<Obd2AdapterCandidate> results,
  ) {
    if (!controller.isClosed) controller.add(results);
  }

  /// Recognise that a scan/connect failed because the OS Bluetooth radio is
  /// off. #3273 — the primary signal is the TYPED, language-independent adapter
  /// state ([FlutterBluePlus.adapterStateNow]); the English-substring match is
  /// kept only as a backstop for the race where the error arrives before the
  /// adapter state flips. (FBP is pinned at 1.36.8 — the 2.x typed-error API is
  /// off-limits per the proprietary-license decision #2072 — so this is the
  /// most robust signal available without a version bump.)
  @visibleForTesting
  static bool debugLooksBluetoothOff(Object e) => _looksBluetoothOff(e);

  /// Test seam for the error mapping used by both the explicit-future
  /// `catchError` and the `scanResults` stream's `onError` (#1392).
  /// Both call sites must funnel through this helper so a BT-off
  /// rejection on either path surfaces as `Obd2BluetoothOff`.
  @visibleForTesting
  static Object debugMapBluetoothError(Object e) => _mapBluetoothError(e);

  static bool _looksBluetoothOff(Object e) {
    // #3273 — primary, typed signal: FBP's cached last-known adapter state (no
    // platform call), independent of any error wording / localization. Guarded
    // so a harness without the FBP binding falls through to the backstop below
    // rather than throwing.
    try {
      if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
        return true;
      }
    } on Object {
      // ignore: silent_catch — no FBP binding (unit test): fall through to the
      // wording backstop; this probe is best-effort and must never throw here.
    }
    // Backstop: the platform-channel rejection WORDING, for the race where the
    // error surfaces before adapterStateNow flips to off. Restricted to the BLE
    // exception types — now incl. FlutterBluePlusException, which the old code
    // missed (it only matched PlatformException) — so an arbitrary object /
    // raw string that merely happens to contain the wording is NOT treated as
    // a radio-off signal.
    if (e is! PlatformException && e is! FlutterBluePlusException) return false;
    final msg = e.toString().toLowerCase();
    return msg.contains('must be turned on') ||
        msg.contains('bluetooth must be on') ||
        msg.contains('bluetooth_off');
  }

  static Object _mapBluetoothError(Object e) =>
      _looksBluetoothOff(e) ? const Obd2BluetoothOff() : e;

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) {
    final device = BluetoothDevice.fromId(deviceId);
    return FlutterBluePlusElmChannel(
      device,
      uuids: Elm327BleUuids(
        service: Guid(profile.serviceUuid),
        writeChar: Guid(profile.writeCharUuid),
        notifyChar: Guid(profile.notifyCharUuid),
      ),
    );
  }

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) {
    // No scan ⇒ no resolved profile. The FFF0 Nordic-UART family
    // (Elm327BleUuids.vgate, = the generic-fff0 profile UUIDs) is the
    // dominant ELM327 BLE clone, so it is the safe default for a
    // direct-by-MAC connect. The 4 s connectTimeout is LOAD-BEARING:
    // FBP `autoConnect:false` can otherwise block ~35 s on a sleeping
    // adapter (#2242).
    //
    // #2261 concern 2 — `autoConnect:true` switches to a passive GATT
    // wait (no bounded timeout): the reconnect scanner uses this once
    // its active-scan miss ceiling is reached, so a parked car stops
    // burning the radio on repeated active scans.
    final device = BluetoothDevice.fromId(mac);
    return FlutterBluePlusElmChannel(
      device,
      uuids: Elm327BleUuids.vgate,
      connectTimeout: autoConnect ? null : connectTimeout,
      autoConnect: autoConnect,
      // #3014 — scan-before-connect ONLY on the cold bounded direct path. The
      // passive autoConnect path needs no seed (it IS the OS-held background
      // request). The targeted scan gives Android a fresh scan-result handle
      // for the raw MAC so the cold `connect()` doesn't fall into the GATT-133
      // trap (the SmartOBD root cause).
      scanSeed: autoConnect ? null : () => _seedScanForMac(mac),
    );
  }

  /// #3014 — run a brief TARGETED scan for [mac] and resolve `true` the instant
  /// it is seen, then `stopScan`. Bounded by [_seedScanTimeout]; a miss resolves
  /// `false` at the timeout. `stopScan` is called on EVERY exit path — fbp
  /// serializes all BLE ops behind a global mutex, so a scan still live on the
  /// radio would deadlock the connect that follows.
  static Future<bool> _seedScanForMac(String mac) async {
    final completer = Completer<bool>();
    StreamSubscription<List<ScanResult>>? sub;

    Future<void> finish(bool sawMac) async {
      if (completer.isCompleted) return;
      await sub?.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {
        // ignore: silent_catch — Best-effort — a stopScan that throws (no scan in flight, plugin
        // quirk) must not block the connect that follows.
      }
      if (!completer.isCompleted) completer.complete(sawMac);
    }

    sub = FlutterBluePlus.scanResults.listen(
      (results) {
        for (final r in results) {
          if (r.device.remoteId.str.toUpperCase() == mac.toUpperCase()) {
            unawaited(finish(true));
            return;
          }
        }
      },
      onError: (_) => unawaited(finish(false)),
    );

    try {
      // #3182 — same lazy-CBCentralManager gate as [scan]: the seed scan is
      // often the FIRST BLE call of the session (the direct-by-MAC reconnect
      // path), so it must not be rejected with state `unknown` on iOS.
      await waitForAdapterOn();
      // #3185 — the seed scan drains the SAME OS scan budget as the full
      // service scans, so it pays into the same process-wide token bucket.
      // A dense reconnect episode (seed + fallback scan + user retry) used
      // to exceed Android's 5-scans/30s throttle, after which every scan
      // silently returned nothing. Fails open; never throws.
      await Obd2ScanGovernor.process.admitScanStart(reason: 'scan-seed');
      // withRemoteIds filters the scan to just this MAC (Android: 48-bit MAC,
      // iOS: 128-bit GUID) so the OS surfaces a fresh handle quickly without
      // sweeping the whole BLE neighbourhood.
      await FlutterBluePlus.startScan(
        withRemoteIds: [mac],
        timeout: _seedScanTimeout,
      );
    } catch (_) {
      // BT off / scan-start rejection — no seed possible; the bounded connect
      // still runs and will fail-fast + be classified by the channel.
      await finish(false);
      return completer.future;
    }

    // Safety net: resolve at the scan timeout even if the result stream never
    // delivers our MAC and the plugin's own timeout callback is delayed.
    Timer(_seedScanTimeout + const Duration(milliseconds: 250),
        () => unawaited(finish(false)));

    return completer.future;
  }

  /// #3014 — the targeted scan-before-connect window. Short by design: a fresh
  /// handle for a MAC that is actually present arrives in well under a second;
  /// a longer window only delays the bounded connect for an absent adapter.
  static const Duration _seedScanTimeout = Duration(seconds: 3);
}
