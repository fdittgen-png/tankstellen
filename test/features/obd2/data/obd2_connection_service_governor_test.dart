// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_scan_governor.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3185 → #3533 — what remains of the connection-service wiring tests.
///
/// The service-level single-flight admission (`Obd2ConnectSupervisor`,
/// its `supervisor-admission` trace step, and the passive skip-cycle)
/// was DELETED in the #3527 rewrite: the one `Obd2LinkSupervisor` is now
/// the single dial path app-wide, and its single-flight invariant is
/// locked by `test/features/obd2/obd2_link_supervisor_test.dart` plus
/// `obd2_single_owner_invariant_test.dart`. The scan GOVERNOR (radio
/// budget) stayed on the connection service — this file keeps it locked.
void main() {
  silenceErrorLoggerSpool();
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  test('scan() pays into the injected scan governor (one token per start)',
      () async {
    final governor = Obd2ScanGovernor();
    final svc = Obd2ConnectionService(
      registry: Obd2AdapterRegistry.defaults(),
      permissions: _GrantedPermissions(),
      bluetooth: _EmptyFacade(),
      scanSettleDelay: Duration.zero,
      scanGovernor: governor,
    );
    // The facade yields no batches → the scan window closes empty and the
    // service throws Obd2ScanTimeout; the token was still spent on the start.
    await expectLater(svc.scan().toList(), throwsA(anything));
    expect(governor.debugStartCount, 1);
  });
}

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

/// Facade whose scan yields nothing and whose channels are never used.
class _EmptyFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError('never used — scan yields no candidates');

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError('never used — no direct path in this test');
}
