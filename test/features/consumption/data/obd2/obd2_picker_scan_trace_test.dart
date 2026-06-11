// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';

/// #3184(e)/(f) — the SCAN itself is now traced:
///
///   * a standalone picker-UI scan ("I scanned and saw nothing") leaves a
///     finalised [Obd2ConnectOrigin.pickerScan] trace — previously NO
///     artefact existed for that complaint;
///   * a scan inside a live connect joins the connect's trace as a CHILD
///     and never stamps the parent's outcome (connect behaviour unchanged);
///   * a scanned device whose NAME matches the pinned adapter but whose
///     deviceId DIFFERS stamps the `pinned-id-mismatch` step — the #3168
///     iOS UUID-vs-MAC identity-drift discriminator, confirmable from one
///     field export.
void main() {
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  Obd2ConnectionService svc({
    List<List<Obd2AdapterCandidate>> batches = const [],
    Obd2PermissionState perm = Obd2PermissionState.granted,
  }) =>
      Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePerm(perm),
        bluetooth: _Facade(batches: batches),
        scanSettleDelay: Duration.zero,
      );

  Obd2AdapterCandidate candidate({
    String deviceId = '11:22:33:44:55:66',
    String deviceName = 'OBDLink CX',
  }) =>
      Obd2AdapterCandidate(
        deviceId: deviceId,
        deviceName: deviceName,
        advertisedServiceUuids: const [],
        rssi: -50,
      );

  group('standalone picker scan is traced (#3184(f))', () {
    test('a scan that finds an adapter finalises a pickerScan/success trace '
        'carrying the scanned device (RED on master: no trace at all)',
        () async {
      await svc(batches: [
        [candidate()]
      ]).scan().toList();

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.origin, Obd2ConnectOrigin.pickerScan);
      expect(trace.outcome, Obd2ConnectOutcome.success);
      expect(trace.scanned, isNotEmpty,
          reason: 'the ranked candidates must land in the scan trace');
    });

    test('an EMPTY scan finalises a pickerScan/scanEmpty trace — "I scanned '
        'and saw nothing" finally leaves an artefact', () async {
      await expectLater(
        svc().scan().toList(),
        throwsA(isA<Obd2ScanTimeout>()),
      );

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.origin, Obd2ConnectOrigin.pickerScan);
      expect(trace.outcome, Obd2ConnectOutcome.scanEmpty);
    });

    test('a permission denial inside the scan is traced too', () async {
      await expectLater(
        svc(perm: Obd2PermissionState.denied).scan().toList(),
        throwsA(isA<Obd2PermissionDenied>()),
      );

      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.outcome, Obd2ConnectOutcome.permissionDenied);
    });
  });

  group('scan inside a live connect joins the connect trace (#3184(f))', () {
    test('the scan becomes a CHILD: no separate trace, no premature outcome '
        'on the parent', () async {
      final root = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        adapterName: 'OBDLink CX',
        requestedTransport: Obd2ConnectTransport.ble,
      );

      await svc(batches: [
        [candidate(deviceId: 'AA:BB:CC:DD:EE:F1')]
      ]).scan().toList();

      expect(Obd2ConnectTraceLog.snapshot(), isEmpty,
          reason: 'the scan must NOT finalise the connect trace it joined');
      expect(root.hasOutcome, isFalse,
          reason: 'a child scan must never stamp the parent outcome');
      expect(identical(Obd2ConnectTraceLog.active, root), isTrue);

      Obd2ConnectTraceLog.endTrace(root);
      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.origin, Obd2ConnectOrigin.firstConnect,
          reason: 'the pickerScan origin never appears on a connect trace');
      expect(trace.scanned, isNotEmpty);
    });
  });

  group('a connect SUPERSEDES a live picker scan (#3184(f))', () {
    // The picker cancels its scan stream fire-and-forget before connecting,
    // so the scan trace may still be the active root when the connect's
    // beginTrace runs. The connect must get its OWN root — never join the
    // ambient scan as a child whose steps would be lost.
    test('the scan finalises (success — it surfaced the picked candidate) '
        'and the connect opens its own root trace', () {
      final scanRoot = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.pickerScan);
      scanRoot.recordScan(
        mac: 'AA:BB:CC:DD:EE:F1',
        name: 'OBDLink CX',
        rssi: -50,
        transport: Obd2ConnectTransport.ble,
        matchedProfileId: 'obdlink-cx',
      );

      final connectRoot = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        requestedTransport: Obd2ConnectTransport.ble,
      );

      expect(connectRoot.isRoot, isTrue,
          reason: 'the connect must NOT child-join the ambient scan');
      final scanTrace = Obd2ConnectTraceLog.snapshot().single;
      expect(scanTrace.origin, Obd2ConnectOrigin.pickerScan);
      expect(scanTrace.outcome, Obd2ConnectOutcome.success);

      connectRoot.setOutcome(Obd2ConnectOutcome.gattTimeout);
      Obd2ConnectTraceLog.endTrace(connectRoot);
      final snap = Obd2ConnectTraceLog.snapshot(); // newest-first
      expect(snap, hasLength(2));
      expect(snap.first.origin, Obd2ConnectOrigin.firstConnect);
      expect(snap.first.outcome, Obd2ConnectOutcome.gattTimeout,
          reason: 'the connect failure lands on the connect trace, not on '
              'an already-finalised scan trace');
    });

    test('a superseded EMPTY scan stays outcome-less (not a fake success)',
        () {
      Obd2ConnectTraceLog.beginTrace(origin: Obd2ConnectOrigin.pickerScan);
      final connectRoot = Obd2ConnectTraceLog.beginTrace(
          origin: Obd2ConnectOrigin.firstConnect);

      expect(connectRoot.isRoot, isTrue);
      expect(Obd2ConnectTraceLog.snapshot().single.outcome, isNull);
      Obd2ConnectTraceLog.endTrace(connectRoot);
    });
  });

  group('pinned-id-mismatch — the #3168 discriminator (#3184(e))', () {
    test('a scanned candidate with the PINNED NAME under a DIFFERENT id '
        'stamps pinned-id-mismatch on the connect trace', () async {
      final root = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        adapterName: 'OBDLink CX',
        requestedTransport: Obd2ConnectTransport.ble,
      );

      await svc(batches: [
        [candidate(deviceId: '11:22:33:44:55:66', deviceName: 'OBDLink CX')]
      ]).scan().toList();

      Obd2ConnectTraceLog.endTrace(root);
      final steps = Obd2ConnectTraceLog.snapshot().single.steps;
      final mismatch =
          steps.singleWhere((s) => s.label == 'pinned-id-mismatch');
      expect(mismatch.status, Obd2ConnectStepStatus.fail);
      // PII stays redacted in the step detail.
      expect(mismatch.detail, isNot(contains('11:22:33')));
      expect(mismatch.detail, isNot(contains('AA:BB:CC')));
    });

    test('the SAME id (case-insensitive) does NOT stamp a mismatch',
        () async {
      final root = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'aa:bb:cc:dd:ee:f1',
        adapterName: 'OBDLink CX',
        requestedTransport: Obd2ConnectTransport.ble,
      );

      await svc(batches: [
        [candidate(deviceId: 'AA:BB:CC:DD:EE:F1', deviceName: 'OBDLink CX')]
      ]).scan().toList();

      Obd2ConnectTraceLog.endTrace(root);
      expect(
        Obd2ConnectTraceLog.snapshot().single.steps.map((s) => s.label),
        isNot(contains('pinned-id-mismatch')),
      );
    });

    test('a DIFFERENT name under a different id does NOT stamp a mismatch',
        () async {
      final root = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        adapterName: 'OBDLink CX',
        requestedTransport: Obd2ConnectTransport.ble,
      );

      await svc(batches: [
        [candidate(deviceId: '11:22:33:44:55:66', deviceName: 'vLinker FD')]
      ]).scan().toList();

      Obd2ConnectTraceLog.endTrace(root);
      expect(
        Obd2ConnectTraceLog.snapshot().single.steps.map((s) => s.label),
        isNot(contains('pinned-id-mismatch')),
      );
    });

    test('a repeating scan batch stamps the mismatch only ONCE', () async {
      final root = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        adapterName: 'OBDLink CX',
        requestedTransport: Obd2ConnectTransport.ble,
      );

      final ghost =
          candidate(deviceId: '11:22:33:44:55:66', deviceName: 'OBDLink CX');
      await svc(batches: [
        [ghost],
        [ghost],
        [ghost],
      ]).scan().toList();

      Obd2ConnectTraceLog.endTrace(root);
      final labels = Obd2ConnectTraceLog.snapshot().single.steps
          .where((s) => s.label == 'pinned-id-mismatch');
      expect(labels, hasLength(1));
    });
  });
}

class _FakePerm implements Obd2Permissions {
  final Obd2PermissionState state;
  _FakePerm(this.state);
  @override
  Future<Obd2PermissionState> current() async => state;
  @override
  Future<Obd2PermissionState> request() async => state;
  @override
  Future<bool> requestNotifications() async => true;
}

class _Facade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  _Facade({required this.batches});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final b in batches) {
      yield b;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError('scan-only test facade');

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError('scan-only test facade');
}
