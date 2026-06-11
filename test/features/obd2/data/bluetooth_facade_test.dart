// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';

/// Unit tests for the [PluginBluetoothFacade] BT-off classifier
/// (#1369).
///
/// `PluginBluetoothFacade._looksBluetoothOff` is the boundary that
/// turns a raw `flutter_blue_plus_android` `PlatformException` into a
/// typed `Obd2BluetoothOff`. The plugin's exact wording has changed
/// between versions, so the substring match must stay tolerant of
/// small phrasing tweaks (different capitalisation, "must be on" vs
/// "must be turned on", explicit `bluetooth_off` codes, etc.).
void main() {
  group('PluginBluetoothFacade.debugLooksBluetoothOff (#1369)', () {
    test('matches the canonical FlutterBluePlus 1.36 phrasing', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'Bluetooth must be turned on',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test('matches a case-insensitive variant', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'BLUETOOTH MUST BE TURNED ON',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test('matches the alternate "must be on" phrasing', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'Bluetooth must be on',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test('matches an explicit bluetooth_off code in the message', () {
      final ex = PlatformException(
        code: 'startScan',
        message: 'BLUETOOTH_OFF: adapter disabled',
      );
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isTrue);
    });

    test(
      'rejects unrelated PlatformExceptions so they propagate as-is',
      () {
        final ex = PlatformException(
          code: 'permission_denied',
          message: 'BLUETOOTH_SCAN permission required',
        );
        expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isFalse);
      },
    );

    test('rejects non-PlatformException objects', () {
      expect(
        PluginBluetoothFacade.debugLooksBluetoothOff(
          ArgumentError('not a platform exception'),
        ),
        isFalse,
      );
      expect(
        PluginBluetoothFacade.debugLooksBluetoothOff(
          'Bluetooth must be turned on',
        ),
        isFalse,
      );
    });

    test('handles a PlatformException with a null message gracefully', () {
      final ex = PlatformException(code: 'startScan');
      expect(PluginBluetoothFacade.debugLooksBluetoothOff(ex), isFalse);
    });
  });

  // #1392 — the explicit `startScan` future was wrapped by #1370, but
  // the `scanResults` stream's `onError` was forwarding the raw
  // `PlatformException(startScan, "Bluetooth must be turned on", ...)`
  // straight through. Both code paths must funnel through the same
  // `_mapBluetoothError` helper so a BT-off rejection on either path
  // surfaces as `Obd2BluetoothOff`.
  group('PluginBluetoothFacade.debugMapBluetoothError (#1392)', () {
    test(
      'scanResults stream BT-off rejection maps to Obd2BluetoothOff',
      () {
        // Same shape as the FlutterBluePlus rejection that previously
        // leaked through the `scanResults` stream's onError to the
        // global zone error handler as `[other] PlatformException`.
        final ex = PlatformException(
          code: 'startScan',
          message: 'Bluetooth must be turned on',
        );
        final mapped = PluginBluetoothFacade.debugMapBluetoothError(ex);
        expect(
          mapped,
          isA<Obd2BluetoothOff>(),
          reason:
              'BT-off PlatformException must be normalised to the typed '
              'error regardless of which call site (explicit-future or '
              'scanResults stream) caught it.',
        );
      },
    );

    test(
      'returns the original error for non-BT-off PlatformExceptions',
      () {
        final ex = PlatformException(
          code: 'permission_denied',
          message: 'BLUETOOTH_SCAN permission required',
        );
        final mapped = PluginBluetoothFacade.debugMapBluetoothError(ex);
        expect(mapped, same(ex));
      },
    );

    test('returns the original error for non-PlatformException objects', () {
      final err = StateError('transport closed');
      final mapped = PluginBluetoothFacade.debugMapBluetoothError(err);
      expect(mapped, same(err));
    });
  });

  // #2953 — the `scanResults` listener fed `controller.add(...)` with NO
  // `isClosed` guard, so a `FlutterBluePlus.scanResults` callback that
  // fires AFTER the scan's timeout `Timer` closed the controller threw
  // `Bad state: Cannot add event after closing` straight into the zone
  // error handler — the engine-off field-log #30 flood (14/22 entries).
  // The guarded feed must drop a late result silently and never throw.
  group('PluginBluetoothFacade.debugSafeAddScanResults (#2953)', () {
    final candidate = Obd2AdapterCandidate(
      deviceId: 'AA:BB:CC:DD:EE:01',
      deviceName: 'OBDII',
      advertisedServiceUuids: const [],
      rssi: -60,
    );

    test('forwards results to an OPEN controller (the normal path)', () async {
      final controller = StreamController<List<Obd2AdapterCandidate>>();
      final received = <List<Obd2AdapterCandidate>>[];
      final sub = controller.stream.listen(received.add);

      PluginBluetoothFacade.debugSafeAddScanResults(controller, [candidate]);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.single.deviceId, 'AA:BB:CC:DD:EE:01');

      await sub.cancel();
      await controller.close();
    });

    test('a late add AFTER close is dropped silently — does NOT throw',
        () async {
      final controller = StreamController<List<Obd2AdapterCandidate>>();
      // A drained listener so the non-broadcast controller's `close()`
      // future completes (mirrors a consumer that already cancelled).
      final sub = controller.stream.listen((_) {});
      // Close it first (mirrors the timeout Timer / onCancel having run),
      // then deliver a late scan result the way a queued `scanResults`
      // callback would.
      await controller.close();
      expect(controller.isClosed, isTrue);

      expect(
        () => PluginBluetoothFacade.debugSafeAddScanResults(controller, [
          candidate,
        ]),
        returnsNormally,
        reason: 'a post-close scanResults callback must be a no-op, not a '
            '`Bad state: Cannot add event after closing` (field log #30)',
      );

      await sub.cancel();
    });
  });
}
