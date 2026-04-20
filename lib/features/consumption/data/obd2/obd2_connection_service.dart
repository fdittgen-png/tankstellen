import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'adapter_registry.dart';
import 'bluetooth_facade.dart';
import 'bluetooth_obd2_transport.dart';
import 'obd2_connection_errors.dart';
import 'obd2_permissions.dart';
import 'obd2_service.dart';

part 'obd2_connection_service.g.dart';

/// Binds scan results to the adapter registry and hands back a ready
/// [Obd2Service] on connect (#741).
///
/// Intentionally platform-free: every plugin interaction goes through
/// the [BluetoothFacade] seam and every permission call through
/// [Obd2Permissions]. Tests inject fakes for both and drive the full
/// happy + error paths without a Bluetooth stack.
class Obd2ConnectionService {
  final Obd2AdapterRegistry registry;
  final Obd2Permissions permissions;
  final BluetoothFacade bluetooth;

  /// Cached ranked candidates from the most recent scan. Consumed by
  /// [reconnectLast] when the caller wants to rehydrate the highest-
  /// RSSI adapter without opening the picker again.
  List<ResolvedObd2Candidate> _lastRanked = const [];

  Obd2ConnectionService({
    required this.registry,
    required this.permissions,
    required this.bluetooth,
  });

  /// Stream of ranked, profile-matched candidates for the picker UI.
  /// Emits the accumulated list on every scan-results change.
  /// Throws [Obd2PermissionDenied] when the runtime permission grant
  /// is missing, [Obd2ScanTimeout] when the scan window elapses with
  /// zero known adapters seen.
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    final state = await permissions.request();
    if (state != Obd2PermissionState.granted) {
      throw const Obd2PermissionDenied();
    }

    var sawAny = false;
    final stream = bluetooth.scan(
      serviceUuids: registry.allServiceUuids,
      timeout: timeout,
    );
    await for (final batch in stream) {
      final ranked = registry.rank(batch);
      if (ranked.isNotEmpty) sawAny = true;
      _lastRanked = ranked;
      yield ranked;
    }
    if (!sawAny) {
      throw const Obd2ScanTimeout();
    }
  }

  /// Connect to the specific [candidate]. Opens the BLE channel, runs
  /// the ELM327 init sequence via [Obd2Service.connect], returns the
  /// ready service. Surfaces [Obd2AdapterUnresponsive] when the init
  /// fails (channel is closed before the error is rethrown).
  Future<Obd2Service> connect(ResolvedObd2Candidate candidate) async {
    final channel =
        bluetooth.channelFor(candidate.candidate.deviceId, candidate.profile);
    final transport = BluetoothObd2Transport(channel);
    final service = Obd2Service(transport);
    final ok = await service.connect();
    if (!ok) {
      await service.disconnect();
      throw const Obd2AdapterUnresponsive();
    }
    return service;
  }

  /// Convenience entry point — picks the highest-RSSI candidate from
  /// the last scan batch and connects. Returns null when no usable
  /// candidate is cached (e.g. the user hasn't scanned yet this
  /// session). Useful for the "first in-car test" flow that skips
  /// the picker UI (#742).
  Future<Obd2Service?> connectBest() async {
    if (_lastRanked.isEmpty) return null;
    try {
      return await connect(_lastRanked.first);
    } on Obd2ConnectionError catch (e) {
      debugPrint('Obd2ConnectionService.connectBest failed: $e');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
Obd2ConnectionService obd2Connection(Ref ref) {
  return Obd2ConnectionService(
    registry: Obd2AdapterRegistry.defaults(),
    permissions: ref.watch(obd2PermissionsProvider),
    bluetooth: const PluginBluetoothFacade(),
  );
}
