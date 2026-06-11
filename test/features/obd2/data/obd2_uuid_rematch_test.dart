// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_adapter_identity.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3168 — `connectByMac`'s scan fallback rematches a ROTATED iOS
/// CBPeripheral UUID by the persisted adapter name, re-persists the fresh
/// id via the `onAdapterIdentityRotated` seam, and stage-tags the whole
/// thing in the connect trace (`uuid-rematch` / `uuid-repersist`).
void main() {
  silenceErrorLoggerSpool();

  const pinnedUuid = '12345678-9ABC-4DEF-8012-3456789ABCDE';
  const rotatedUuid = 'FEDCBA98-7654-4321-8FED-CBA987654321';
  const adapterName = 'OBDLink CX';

  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  Obd2AdapterCandidate cx(String id, {String name = adapterName}) =>
      Obd2AdapterCandidate(
        deviceId: id,
        deviceName: name,
        advertisedServiceUuids: const [],
        rssi: -55,
      );

  List<Obd2ConnectStep> stepsNamed(String label) => [
        for (final t in Obd2ConnectTraceLog.snapshot())
          for (final s in t.steps)
            if (s.label == label) s,
      ];

  test('rotated UUID + unique name match → connects to the fresh id AND '
      're-persists it through the rotation seam', () async {
    final rotations = <({String staleId, Obd2AdapterIdentity fresh})>[];
    final svc = _build(
      bt: _FakeFacade(batches: [
        [cx(rotatedUuid)],
      ]),
      onRotated: ({required staleId, required fresh}) async =>
          rotations.add((staleId: staleId, fresh: fresh)),
    );

    final ready = await svc.connectByMac(pinnedUuid, adapterName: adapterName);

    expect(ready, isNotNull,
        reason: 'the rotated-UUID adapter must reconnect via the rematch');
    expect(ready!.adapterMac, rotatedUuid,
        reason: 'the session must run on the FRESH peripheral id');
    expect(rotations, hasLength(1));
    expect(rotations.single.staleId, pinnedUuid);
    expect(rotations.single.fresh.deviceId, rotatedUuid);
    expect(rotations.single.fresh.name, adapterName);
    expect(rotations.single.fresh.uuidIos, rotatedUuid);
    await ready.disconnect();

    // Stage tags: the field trace must show WHEN the rotation happened.
    final rematch = stepsNamed('uuid-rematch');
    expect(rematch, hasLength(1));
    expect(rematch.single.status, Obd2ConnectStepStatus.ok);
    final repersist = stepsNamed('uuid-repersist');
    expect(repersist, hasLength(1));
    expect(repersist.single.status, Obd2ConnectStepStatus.ok);
    // The #3184(e) discriminator fires alongside the rematch.
    expect(stepsNamed('pinned-id-mismatch'), isNotEmpty);
  });

  test('exact-id hit → NO rematch, NO rotation callback (same-uuid row of '
      'the decision table)', () async {
    var rotated = 0;
    final svc = _build(
      bt: _FakeFacade(batches: [
        [cx(pinnedUuid)],
      ]),
      onRotated: ({required staleId, required fresh}) async => rotated++,
    );

    final ready = await svc.connectByMac(pinnedUuid, adapterName: adapterName);

    expect(ready, isNotNull);
    expect(ready!.adapterMac, pinnedUuid);
    expect(rotated, 0);
    await ready.disconnect();
    expect(stepsNamed('uuid-rematch'), isEmpty);
  });

  test('name collision — two same-named fresh candidates → ambiguous: '
      'returns null (picker fallback) and stamps the skip', () async {
    var rotated = 0;
    final svc = _build(
      bt: _FakeFacade(batches: [
        [cx(rotatedUuid), cx('00000000-1111-4222-8333-444455556666')],
      ]),
      onRotated: ({required staleId, required fresh}) async => rotated++,
    );

    final ready = await svc.connectByMac(pinnedUuid, adapterName: adapterName);

    expect(ready, isNull, reason: 'an ambiguous rematch must never guess');
    expect(rotated, 0);
    final rematch = stepsNamed('uuid-rematch');
    expect(rematch, hasLength(1));
    expect(rematch.single.status, Obd2ConnectStepStatus.fail);
    expect(rematch.single.detail, contains('ambiguous'));
  });

  test('MAC-shaped pinned id (Android) + same-named other MAC → harmless: '
      'no rematch, null as before', () async {
    var rotated = 0;
    final svc = _build(
      bt: _FakeFacade(batches: [
        [cx('11:22:33:44:55:66')],
      ]),
      onRotated: ({required staleId, required fresh}) async => rotated++,
    );

    final ready =
        await svc.connectByMac('AA:BB:CC:DD:EE:FF', adapterName: adapterName);

    expect(ready, isNull);
    expect(rotated, 0);
    expect(stepsNamed('uuid-rematch'), isEmpty);
  });

  test('no persisted adapter name → rematch not eligible, null as before',
      () async {
    final svc = _build(
      bt: _FakeFacade(batches: [
        [cx(rotatedUuid)],
      ]),
      onRotated: ({required staleId, required fresh}) async {},
    );

    final ready = await svc.connectByMac(pinnedUuid);

    expect(ready, isNull);
    expect(stepsNamed('uuid-rematch'), isEmpty);
  });

  test('FAULT INJECTION — a THROWING rotation seam is swallowed: the connect '
      'that just succeeded still returns its service (never throws)',
      () async {
    final svc = _build(
      bt: _FakeFacade(batches: [
        [cx(rotatedUuid)],
      ]),
      onRotated: ({required staleId, required fresh}) =>
          Future<void>.error(StateError('repersist exploded')),
    );

    final ready = await svc.connectByMac(pinnedUuid, adapterName: adapterName);

    expect(ready, isNotNull,
        reason: 'a failed re-persist must never derail the live session');
    await ready!.disconnect();
    final repersist = stepsNamed('uuid-repersist');
    expect(repersist, hasLength(1));
    expect(repersist.single.status, Obd2ConnectStepStatus.fail);
  });
}

Obd2ConnectionService _build({
  required BluetoothFacade bt,
  Obd2AdapterIdentityRotated? onRotated,
}) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _FakePermissions(),
      bluetooth: bt,
      onAdapterIdentityRotated: onRotated,
      scanSettleDelay: Duration.zero,
    );

class _FakePermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _FakeFacade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  _FakeFacade({required this.batches});

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _FakeChannel();

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      _FakeChannel();
}

/// Answers every write with the canonical ELM327 prompt so the init
/// sequence completes (mirrors the connection-service test fakes).
class _FakeChannel implements ElmByteChannel {
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;

  static const Map<String, String> _respondTo = {
    'ATZ': 'ELM327 v1.5>',
    'ATE0': 'OK>',
    'ATL0': 'OK>',
    'ATH0': 'OK>',
    'ATSP0': 'OK>',
  };

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async {
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    final cmd = String.fromCharCodes(bytes).trim();
    final reply = _respondTo[cmd] ?? 'OK>';
    _ctrl.add(reply.codeUnits);
  }

  @override
  Future<void> close() async {
    _open = false;
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}
