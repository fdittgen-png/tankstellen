// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_in_range_probe.dart';
import 'package:tankstellen/features/obd2/data/obd2_scan_governor.dart';

/// Fake [BluetoothFacade] that replays PRE-SEEDED scan batches in the real
/// event shape (accumulated candidate lists) — deliberately NOT an echo of
/// the request, so a probe that "sees" the target can only do so because
/// the fixture actually advertises it.
class _FakeFacade implements BluetoothFacade {
  _FakeFacade(this.batches);

  final List<List<Obd2AdapterCandidate>> batches;
  int scanCalls = 0;
  Set<String>? lastServiceUuids;
  Duration? lastTimeout;

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) {
    scanCalls++;
    lastServiceUuids = serviceUuids;
    lastTimeout = timeout;
    return Stream.fromIterable(batches);
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError('probe never opens a channel');

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError('probe never opens a channel');
}

Obd2AdapterCandidate _candidate(String id, {String name = 'vLinker FS'}) =>
    Obd2AdapterCandidate(
      deviceId: id,
      deviceName: name,
      advertisedServiceUuids: const ['0000fff0-0000-1000-8000-00805f9b34fb'],
      rssi: -62,
    );

void main() {
  const mac = 'AA:BB:CC:DD:EE:01';

  late Obd2ScanGovernor governor;

  setUp(() {
    // Fresh isolated token bucket with a no-op wait so a saturated bucket
    // could never sleep the suite.
    governor = Obd2ScanGovernor(wait: (_) async {});
    BreadcrumbCollector.clear();
  });

  group('buildObd2InRangeProbe (#3421) — BLE transport', () {
    test('advert sighted in a later batch → true (case-insensitive id)',
        () async {
      final facade = _FakeFacade([
        [_candidate('11:22:33:44:55:66', name: 'someone else')],
        [
          _candidate('11:22:33:44:55:66', name: 'someone else'),
          // Lower-cased id in the advert; the pinned mac is upper-case.
          _candidate('aa:bb:cc:dd:ee:01'),
        ],
      ]);
      final probe = buildObd2InRangeProbe(
        bluetooth: facade,
        scanGovernor: governor,
        transportHint: 'ble',
      );

      expect(await probe(mac), isTrue);
      expect(facade.scanCalls, 1);
      // #3097 — unfiltered scan (a withServices filter starves name-only
      // clones), bounded by the short probe window.
      expect(facade.lastServiceUuids, isEmpty);
      expect(facade.lastTimeout, const Duration(seconds: 3));
      // #3185 — every probe pays into the process-wide scan budget.
      expect(governor.debugStartCount, 1);
      // #3421 acceptance — the result is stamped as a breadcrumb.
      expect(
        BreadcrumbCollector.snapshot()
            .map((b) => b.action)
            .where((a) => a.contains('ble-probe sighted')),
        isNotEmpty,
      );
    });

    test('silent scan window (no sighting of the pinned mac) → false',
        () async {
      final facade = _FakeFacade([
        [_candidate('11:22:33:44:55:66', name: 'someone else')],
      ]);
      final probe = buildObd2InRangeProbe(
        bluetooth: facade,
        scanGovernor: governor,
        transportHint: 'ble',
      );

      expect(await probe(mac), isFalse);
      expect(governor.debugStartCount, 1);
      expect(
        BreadcrumbCollector.snapshot()
            .map((b) => b.action)
            .where((a) => a.contains('ble-probe miss')),
        isNotEmpty,
      );
    });

    test('an empty scan window → false', () async {
      final facade = _FakeFacade(const []);
      final probe = buildObd2InRangeProbe(
        bluetooth: facade,
        scanGovernor: governor,
        transportHint: 'ble',
      );
      expect(await probe(mac), isFalse);
    });

    test(
        'a scan failure propagates to the caller (the scanner already '
        'de-noises probe throws, #2953)', () async {
      final facade = _ThrowingScanFacade();
      final probe = buildObd2InRangeProbe(
        bluetooth: facade,
        scanGovernor: governor,
        transportHint: 'ble',
      );
      await expectLater(probe(mac), throwsA(isA<StateError>()));
    });
  });

  group('buildObd2InRangeProbe (#3421) — non-BLE transports', () {
    test('classic pin → true WITHOUT touching the radio (no advert to sight)',
        () async {
      final facade = _FakeFacade(const []);
      final probe = buildObd2InRangeProbe(
        bluetooth: facade,
        scanGovernor: governor,
        transportHint: 'classic',
      );
      expect(await probe(mac), isTrue);
      expect(facade.scanCalls, 0);
      expect(governor.debugStartCount, 0);
    });

    test('unknown transport → conservatively true without scanning '
        '(a wrongly-probed Classic pin would starve forever)', () async {
      final facade = _FakeFacade(const []);
      final probe = buildObd2InRangeProbe(
        bluetooth: facade,
        scanGovernor: governor,
        transportHint: null,
      );
      expect(await probe(mac), isTrue);
      expect(facade.scanCalls, 0);
    });
  });
}

/// Facade whose scan stream errors (BT off / plugin rejection).
class _ThrowingScanFacade extends _FakeFacade {
  _ThrowingScanFacade() : super(const []);

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) =>
      Stream.error(StateError('startScan rejected'));
}
