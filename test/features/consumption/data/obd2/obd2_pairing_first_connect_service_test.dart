// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'last_good_adapter_store.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_known_adapters_store.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_pairing_mode.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import '../../../../helpers/silence_error_logger.dart';

const _mac = 'AA:BB:CC:DD:EE:31';

/// #3181 — service-level first-connect pairing mode:
///   * `_openAndInit` arms [Obd2PairingMode] for a deviceId the
///     [KnownObd2AdaptersStore] has never seen (and clears it in finally);
///   * a pairing-classified failure surfaces as the TYPED
///     [Obd2PairingRequired] (not the generic adapter-unresponsive) and is
///     NOT masked by the scan fallback;
///   * a known-good deviceId never enters pairing mode.
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    Obd2ConnectTraceLog.clear();
    Obd2PairingMode.resetForTest();
  });
  tearDown(() {
    Obd2ConnectTraceLog.clear();
    Obd2PairingMode.resetForTest();
  });

  test(
      'first connect (unknown deviceId): pairing mode is ARMED while the '
      'channel opens, the pairing failure rethrows TYPED, the scan fallback '
      'is SKIPPED, and the mode is cleared after (RED on master)', () async {
    final storage = _FakeSettingsStorage();
    final facade = _Facade(openError: const Obd2PairingRequired());
    final service = _service(facade, storage);

    await expectLater(
      service.connectByMacDirect(_mac, fallbackToScan: true),
      throwsA(isA<Obd2PairingRequired>()),
    );

    expect(facade.channel!.firstConnectAtOpen, isTrue,
        reason: 'the channel must see pairing mode armed at open() time so '
            'enableNotify picks the 30 s budget');
    expect(facade.scanCalls, 0,
        reason: 'a pairing failure must NOT fall back to the scan — it would '
            'mask the guidance and burn the 5-minute bond window');
    expect(Obd2PairingMode.isFirstConnect(_mac), isFalse,
        reason: 'cleared in finally — a failed attempt must not leak the mode');
    final trace = Obd2ConnectTraceLog.snapshot().first;
    expect(trace.outcome, Obd2ConnectOutcome.pairingRequired);
    expect(trace.steps.map((s) => s.label), contains('first-connect'));
  });

  test('a KNOWN-GOOD deviceId never enters pairing mode', () async {
    final storage = _FakeSettingsStorage();
    await KnownObd2AdaptersStore(storage).markKnownGood(_mac);
    final facade = _Facade(openError: TimeoutException('Timed out after 4s'));
    final service = _service(facade, storage);

    await service.connectByMacDirect(_mac, fallbackToScan: false);

    expect(facade.channel!.firstConnectAtOpen, isFalse,
        reason: 'steady-state budget for an already-bonded adapter');
  });

  test('the auto-pinned last-good adapter is NOT a first connect '
      '(pre-#3181 migration)', () async {
    final storage = _FakeSettingsStorage();
    // Simulate a pre-#3181 user: the pin exists, the known-good set does not.
    storage.data['obdLastGoodAdapter'] = {
      'mac': _mac,
      'transportKind': 'ble',
      'name': 'OBDLink CX',
    };
    final facade = _Facade(openError: TimeoutException('Timed out after 4s'));
    final service = _service(facade, storage);

    await service.connectByMacDirect(_mac, fallbackToScan: false);

    expect(facade.channel!.firstConnectAtOpen, isFalse);
  });
}

Obd2ConnectionService _service(_Facade facade, _FakeSettingsStorage storage) =>
    Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _FakePerm(),
      bluetooth: facade,
      knownAdaptersStore: KnownObd2AdaptersStore(storage),
      lastGoodAdapterStore: LastGoodAdapterStore(storage),
      scanSettleDelay: Duration.zero,
    );

class _FakePerm implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _Facade implements BluetoothFacade {
  _Facade({required this.openError});

  final Object openError;
  int scanCalls = 0;
  _CapturingChannel? channel;

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    scanCalls++;
    throw const Obd2ScanTimeout();
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      channel = _CapturingChannel(deviceId, openError);

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      channel = _CapturingChannel(mac, openError);
}

/// Captures whether pairing mode was armed for its deviceId at `open()`
/// time — the moment the real channel selects the setNotify budget.
class _CapturingChannel implements ElmByteChannel {
  _CapturingChannel(this.deviceId, this.error);

  final String deviceId;
  final Object error;
  bool? firstConnectAtOpen;
  // ignore: close_sinks
  final _controller = StreamController<List<int>>.broadcast();

  @override
  bool get isOpen => false;
  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> open() async {
    firstConnectAtOpen ??= Obd2PairingMode.isFirstConnect(deviceId);
    throw error;
  }

  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Future<void> close() async {}
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};
  @override
  dynamic getSetting(String key) => data[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => data[key] = value;
  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
