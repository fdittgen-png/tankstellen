// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'flutter_blue_plus_elm_channel.dart';

/// #3014 (Epic #3013, Phase 2) — SCAN-BEFORE-CONNECT, the single
/// highest-leverage SmartOBD fix.
///
/// The cold BLE direct path connected to a raw MAC the OS held NO fresh
/// scan-result handle for → the textbook GATT-133 / 15 s timeout trap;
/// discovery was never reached. The fix runs a brief TARGETED scan for the MAC
/// FIRST (then `stopScan`s) so Android holds a fresh handle before the cold
/// connect.
///
/// FBP `device.connect` is not fakeable, so the channel exposes the raw connect
/// behind the `@protected @visibleForTesting rawConnect` seam (the `writeRaw`
/// precedent) and the discovery behind `discoverAndBind`. This test overrides
/// both to (a) prove the seed runs BEFORE the connect on the cold path, and
/// (b) model the field contract: a cold-MAC connect with NO fresh handle 133s,
/// a scan-seeded connect succeeds. RED on master: the cold path had no seed.
class _TestChannel extends FlutterBluePlusElmChannel {
  _TestChannel(
    super.device, {
    super.connectTimeout,
    super.autoConnect,
    super.scanSeed,
  });

  final order = <String>[];

  @override
  Future<void> rawConnect({
    required bool autoConnect,
    int? mtu,
    Duration? timeout,
  }) async {
    order.add('connect');
    // Model the GATT-133 trap: the cold direct path runs the scan-before-connect
    // seed FIRST. If the seed ran but MISSED the MAC (no fresh handle), the cold
    // connect 133s. If the seed ran and SAW the MAC, it succeeds. The
    // scan-path / passive paths run NO seed (debugScanSeedRan == false), so they
    // always succeed here.
    if (debugScanSeedRan && !debugScanSeedSawMac) {
      throw StateError('android: GATT_ERROR 133 (no fresh handle)');
    }
  }

  @override
  Future<void> discoverAndBind() async {
    order.add('discover');
  }

  // Stub the FBP-bound seams so open() runs end-to-end without a BLE stack.
  @override
  void bindConnectionState() {}

  @override
  Future<void> tuneForRecording() async {}
}

void main() {
  BluetoothDevice device() => BluetoothDevice.fromId('AA:BB:CC:DD:EE:31');

  group('scan-before-connect — the cold BLE direct path seeds first (#3014)',
      () {
    test(
        'open() runs the targeted scan-seed BEFORE the cold connect, then '
        'connects off the fresh handle (RED on master: no seed)', () async {
      var seedRan = false;
      final ch = _TestChannel(
        device(),
        connectTimeout: const Duration(seconds: 4),
        scanSeed: () async {
          seedRan = true;
          return true; // the targeted scan saw the MAC ⇒ fresh handle
        },
      );

      await ch.open();

      expect(seedRan, isTrue, reason: 'the seed must have run');
      expect(ch.debugScanSeedRan, isTrue);
      expect(ch.debugScanSeedSawMac, isTrue);
      expect(ch.order, ['connect', 'discover'],
          reason: 'the seed runs inside connectDevice BEFORE rawConnect; the '
              'order list only records connect/discover, and connect must '
              'precede discover');
      // The seed must have completed before the raw connect was attempted —
      // proven by the connect succeeding (no 133) on the fresh handle.
      expect(ch.isOpen, isTrue);
    });

    test(
        'a scan-seed MISS surfaces the cold-MAC GATT_ERROR 133 (the trap the '
        'fix dodges when the scan DOES see the MAC)', () async {
      final ch = _TestChannel(
        device(),
        connectTimeout: const Duration(seconds: 4),
        scanSeed: () async => false, // targeted scan missed the MAC
      );

      await expectLater(ch.open(), throwsA(isA<StateError>()));
      expect(ch.debugScanSeedRan, isTrue,
          reason: 'the seed still ran (best-effort) — it just missed');
      expect(ch.debugScanSeedSawMac, isFalse);
    });

    test('the passive autoConnect path runs NO scan-seed', () async {
      var seedRan = false;
      final ch = _TestChannel(
        device(),
        autoConnect: true,
        scanSeed: () async {
          seedRan = true;
          return true;
        },
      );

      await ch.open();

      expect(seedRan, isFalse,
          reason: 'the passive path is the OS-held background request — no '
              'seed is needed and none must run');
      expect(ch.debugScanSeedRan, isFalse);
      expect(ch.isOpen, isTrue);
    });

    test('the scan-path (no bounded timeout) runs NO scan-seed', () async {
      var seedRan = false;
      // connectTimeout null ⇒ the scan-first path: the picker scan already gave
      // Android a fresh handle, so no targeted seed is wired by the facade.
      final ch = _TestChannel(
        device(),
        scanSeed: () async {
          seedRan = true;
          return true;
        },
      );

      await ch.open();
      expect(seedRan, isFalse);
    });
  });

  group('refreshGattCache — never throws (#3014 / #2349)', () {
    test(
        'refreshGattCache returns NORMALLY when the underlying clearGattCache '
        'throws (off-Android / OEM-blocked reflection) — the docstring contract',
        () {
      // On the unit-test platform FBP is "unsupported", so the real
      // `_device.clearGattCache()` THROWS — exactly the fault the swallow must
      // absorb. The transport calls this on the failure path, where any escape
      // would mask the real connect error (#1103).
      final ch = FlutterBluePlusElmChannel(device());
      expect(ch.refreshGattCache(), completes,
          reason: 'a throwing clearGattCache must be swallowed so the '
              'GATT-133 retry proceeds and the real error is preserved');
    });
  });

  group('#3118 — post-connect timeouts are iOS-aware', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('iOS gets longer setNotify + discover budgets (slow CoreBluetooth) — '
        'the OBDLink CX 4s setNotify TimeoutException fix', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(FlutterBluePlusElmChannel.debugSetNotifyTimeout,
          const Duration(seconds: 7));
      expect(FlutterBluePlusElmChannel.debugDiscoverTimeout,
          const Duration(seconds: 8));
    });

    test('Android keeps the tight load-bearing budgets (#2242/#3014)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(FlutterBluePlusElmChannel.debugSetNotifyTimeout,
          const Duration(seconds: 4));
      expect(FlutterBluePlusElmChannel.debugDiscoverTimeout,
          const Duration(seconds: 5));
    });
  });
}
