// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';

/// #3014 (Epic #3013, Phase 2) — GATT-133 recovery in the channel-open retry.
///
/// A cache-poisoned device (a clone whose GATT table mutated, or a stale cache
/// from an aborted attempt) returns Android GATT_ERROR 133 until the native
/// service cache is dropped. The transport's open-retry loop now, on a 133:
///   * closes the half-open client (truly), then
///   * drops the native GATT cache via [Obd2GattRecoverable.refreshGattCache]
///     (best-effort, Android-only, never throws), then
///   * backs off (jittered) and retries.
///
/// This drives the REAL [BluetoothObd2Transport.connect] retry loop with a
/// channel that throws a 133 on attempt 1 and succeeds on attempt 2, asserting
/// the cache refresh ran exactly once between them. A plain (non-133) transient
/// must NOT trigger a cache refresh.
class _Gatt133Channel implements ElmByteChannel, Obd2GattRecoverable {
  _Gatt133Channel({
    required this.failuresBefore133Success,
    this.transientIsGatt133 = true,
  });

  /// How many open() attempts throw before the next one succeeds.
  final int failuresBefore133Success;

  /// When true, the open failure is a GATT_ERROR 133; when false, a plain
  /// (recoverable but non-133) timeout — so the no-refresh case is provable.
  final bool transientIsGatt133;

  final _controller = StreamController<List<int>>.broadcast();
  int openAttempts = 0;
  int closeCalls = 0;
  int refreshCalls = 0;
  bool _open = false;

  @override
  Future<void> open() async {
    openAttempts++;
    if (openAttempts <= failuresBefore133Success) {
      if (transientIsGatt133) {
        throw FlutterBluePlusException(
          ErrorPlatform.android,
          'connect',
          133,
          'ANDROID_SPECIFIC_ERROR (GATT_ERROR)',
        );
      }
      throw TimeoutException('connect timed out');
    }
    _open = true;
  }

  @override
  Future<void> refreshGattCache() async {
    refreshCalls++;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    _open = false;
    if (!_controller.isClosed) await _controller.close();
  }

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> write(List<int> bytes) async {}
}

void main() {
  group('BluetoothObd2Transport — GATT-133 recovery (#3014)', () {
    test(
        'a 133 on attempt 1 then success on attempt 2 → the native GATT cache '
        'is dropped between attempts, and the connect succeeds', () async {
      final channel = _Gatt133Channel(failuresBefore133Success: 1);
      final transport = BluetoothObd2Transport(channel);
      addTearDown(transport.disconnect);

      await transport.connect();

      expect(transport.isConnected, isTrue,
          reason: 'the retry after the cache refresh must connect');
      expect(channel.openAttempts, 2,
          reason: 'one 133 failure + one success');
      expect(channel.closeCalls, 1,
          reason: 'the half-open client is closed before the retry');
      expect(channel.refreshCalls, 1,
          reason: 'a 133 must drop the native GATT cache exactly once before '
              'the retry — the cache-poisoned-device fix');
    });

    test(
        'a plain (non-133) transient does NOT drop the GATT cache — only a 133 '
        'warrants the Android-only refresh', () async {
      final channel = _Gatt133Channel(
        failuresBefore133Success: 1,
        transientIsGatt133: false,
      );
      final transport = BluetoothObd2Transport(channel);
      addTearDown(transport.disconnect);

      await transport.connect();

      expect(transport.isConnected, isTrue);
      expect(channel.openAttempts, 2);
      expect(channel.refreshCalls, 0,
          reason: 'a timeout is not a cache-poisoning 133 — no refresh');
    });

    test(
        'a refreshGattCache that THROWS is swallowed — the retry still proceeds '
        '(#1103 best-effort, OEM-variable reflection)', () async {
      final channel = _ThrowingRefreshChannel();
      final transport = BluetoothObd2Transport(channel);
      addTearDown(transport.disconnect);

      // Must not throw the refresh error — the connect succeeds on the retry.
      await transport.connect();
      expect(transport.isConnected, isTrue);
      expect(channel.refreshAttempts, 1);
    });
  });
}

/// A 133 channel whose cache-refresh throws, proving the transport swallows it.
class _ThrowingRefreshChannel implements ElmByteChannel, Obd2GattRecoverable {
  final _controller = StreamController<List<int>>.broadcast();
  int openAttempts = 0;
  int refreshAttempts = 0;
  bool _open = false;

  @override
  Future<void> open() async {
    openAttempts++;
    if (openAttempts == 1) {
      throw FlutterBluePlusException(
          ErrorPlatform.android, 'connect', 133, 'GATT_ERROR');
    }
    _open = true;
  }

  @override
  Future<void> refreshGattCache() async {
    refreshAttempts++;
    throw PlatformException(code: 'reflection-blocked');
  }

  @override
  Future<void> close() async {
    _open = false;
    if (!_controller.isClosed) await _controller.close();
  }

  @override
  bool get isOpen => _open;
  @override
  Stream<List<int>> get incoming => _controller.stream;
  @override
  Future<void> write(List<int> bytes) async {}
}
