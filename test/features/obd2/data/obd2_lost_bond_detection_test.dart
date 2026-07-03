// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/classic_bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_lost_bond_state.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import '../../../helpers/silence_error_logger.dart';

/// #3423 (Epic #3415 task 6) — lost-bond detection at the Classic connect
/// chokepoint.
///
/// The field failure mode: Android drops the bond to the pinned Classic
/// adapter (a "forget device", a BT-stack reset, an OS upgrade). An RFCOMM
/// open to an unbonded MAC is doomed by construction, so every connect and
/// in-trip reconnect cycle burnt the whole-ladder budget and stamped a
/// generic `rfcomm-open-fail` — an endless, silent scan-empty/rfcomm loop
/// with no hint that the ONLY fix is re-pairing in system settings.
///
/// `_connectByMacClassicDirect` now consults `isBonded` FIRST: a definite
/// miss stamps the distinct `bond-lost` failure on the connect trace
/// (outcome `pairingRequired`, failureDetail `bond-lost: …`), raises the
/// [Obd2LostBondState] guided-re-pair state, and never dials RFCOMM. An
/// UNKNOWN bonded list (`null`) must degrade to the ordinary dial.
void main() {
  silenceErrorLoggerSpool();

  const mac = 'AA:BB:CC:DD:EE:DA';

  setUp(() {
    Obd2ConnectTraceLog.clear();
    Obd2LostBondState.instance.reset();
  });
  tearDown(() {
    Obd2ConnectTraceLog.clear();
    Obd2LostBondState.instance.reset();
  });

  Obd2ConnectionService buildService(_BondAwareClassicFacade classic) =>
      Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _GrantedPermissions(),
        bluetooth: _UnusedBleFacade(),
        classicBluetooth: classic,
        scanSettleDelay: Duration.zero,
      );

  group('lost-bond detection (#3423)', () {
    test(
        'a pinned Classic MAC ABSENT from bondedDevices stamps the distinct '
        'bond-lost failure and NEVER dials RFCOMM', () async {
      final classic = _BondAwareClassicFacade(bonded: false);
      final service = buildService(classic);

      final svc = await service.connectByMacClassicDirect(mac);

      expect(svc, isNull);
      expect(classic.channelForCalls, isEmpty,
          reason: 'an RFCOMM open to an unbonded MAC is doomed by '
              'construction — the dial must be skipped, not burnt through '
              'the whole-ladder budget');
      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.outcome, Obd2ConnectOutcome.pairingRequired,
          reason: 'the lost bond is a pairing condition, not a generic '
              'rfcomm-open-fail / scan-empty');
      expect(trace.failureDetail, contains('bond-lost'),
          reason: 'the failureDetail must carry the DISTINCT bond-lost tag '
              'so a field export tells a dropped bond apart from the '
              'ordinary out-of-range rfcomm failure');
      expect(
        trace.steps.any((s) =>
            s.label == 'classic-bond-check' &&
            s.status == Obd2ConnectStepStatus.fail),
        isTrue,
        reason: 'the bond check must appear as its own failed trace step',
      );
    });

    test('the lost bond raises the guided-re-pair state for the UI seam',
        () async {
      final classic = _BondAwareClassicFacade(bonded: false);
      final service = buildService(classic);

      await service.connectByMacClassicDirect(mac);

      final event = Obd2LostBondState.instance.current.value;
      expect(event, isNotNull,
          reason: 'the #3422 recovery banner listens on this state to show '
              'the guided re-pair (system Bluetooth settings) CTA');
      expect(event!.mac, mac);
    });

    test(
        'repeated reconnect cycles do NOT re-publish an identical lost-bond '
        'event (idempotent per MAC)', () async {
      final classic = _BondAwareClassicFacade(bonded: false);
      final service = buildService(classic);

      await service.connectByMacClassicDirect(mac);
      final first = Obd2LostBondState.instance.current.value;
      await service.connectByMacClassicDirect(mac);

      expect(identical(Obd2LostBondState.instance.current.value, first), isTrue,
          reason: 'the scanner re-checks every backoff cycle — churning a '
              'fresh event each time would just rebuild listeners');
    });

    test(
        'a BONDED MAC dials RFCOMM as before and CLEARS a stale lost-bond '
        'state (the user re-paired in system settings)', () async {
      Obd2LostBondState.instance.noteLostBond(mac);
      final classic = _BondAwareClassicFacade(bonded: true);
      final service = buildService(classic);

      await service.connectByMacClassicDirect(mac);

      expect(classic.channelForCalls, [mac],
          reason: 'a bonded adapter takes the ordinary RFCOMM dial');
      expect(Obd2LostBondState.instance.current.value, isNull,
          reason: 'a definite bonded=true proves the re-pair landed — the '
              'guidance must dismiss itself on the very next cycle');
    });

    test(
        'an UNKNOWN bonded list (null) degrades to the ordinary dial — '
        'never misclassified as a lost bond', () async {
      final classic = _BondAwareClassicFacade(bonded: null);
      final service = buildService(classic);

      await service.connectByMacClassicDirect(mac);

      expect(classic.channelForCalls, [mac],
          reason: 'unknown must never block the connect');
      expect(Obd2LostBondState.instance.current.value, isNull,
          reason: 'only a DEFINITE false may raise the re-pair state');
      final trace = Obd2ConnectTraceLog.snapshot().single;
      expect(trace.failureDetail ?? '', isNot(contains('bond-lost')),
          reason: 'no bond-lost stamp on an unreadable bonded list');
    });
  });

  group('Obd2LostBondState (#3423)', () {
    test('clearFor ignores a different MAC; reset drops unconditionally', () {
      Obd2LostBondState.instance.noteLostBond(mac);
      Obd2LostBondState.instance.clearFor('11:22:33:44:55:66');
      expect(Obd2LostBondState.instance.current.value, isNotNull);
      Obd2LostBondState.instance.clearFor('aa:bb:cc:dd:ee:da');
      expect(Obd2LostBondState.instance.current.value, isNull,
          reason: 'MAC comparison must be case-insensitive');
      Obd2LostBondState.instance.noteLostBond(mac);
      Obd2LostBondState.instance.reset();
      expect(Obd2LostBondState.instance.current.value, isNull);
    });
  });
}

/// Classic facade whose bonded list is scripted: [bonded] `false` models the
/// OS-dropped bond, `true` an intact pairing, `null` an unreadable list.
/// The channel it hands out fails its open() fast so the bonded=true path
/// stays deterministic (the dial ATTEMPT — [channelForCalls] — is what the
/// tests assert, not a full ELM init).
class _BondAwareClassicFacade implements ClassicBluetoothFacade {
  _BondAwareClassicFacade({required this.bonded});
  final bool? bonded;
  final List<String> channelForCalls = [];

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool?> isBonded(String mac) async => bonded;

  @override
  ElmByteChannel channelFor(String deviceId) {
    channelForCalls.add(deviceId);
    return _FailFastChannel();
  }
}

/// Channel whose open() throws immediately — keeps the bonded=true /
/// unknown paths fast while still proving the RFCOMM dial was attempted.
class _FailFastChannel implements ElmByteChannel {
  final StreamController<List<int>> _ctrl = StreamController.broadcast();

  @override
  bool get isOpen => false;

  @override
  Stream<List<int>> get incoming => _ctrl.stream;

  @override
  Future<void> open() async =>
      throw StateError('rfcomm open failed (scripted)');

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> close() async {
    if (!_ctrl.isClosed) await _ctrl.close();
  }
}

class _UnusedBleFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      _FailFastChannel();

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      _FailFastChannel();
}

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;

  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;

  @override
  Future<bool> requestNotifications() async => true;
}
