import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'adapter_registry.dart';
import 'bluetooth_facade.dart';
import 'bluetooth_obd2_transport.dart';
import 'classic_bluetooth_facade.dart';
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

  /// Classic-BT facade (#761). Runs alongside [bluetooth] so an
  /// adapter like the vLinker FS — which uses Bluetooth Classic
  /// SPP, not BLE — is discoverable. Nullable for backward
  /// compatibility with tests that only exercise the BLE path.
  final ClassicBluetoothFacade? classicBluetooth;

  /// Cached ranked candidates from the most recent scan. Consumed by
  /// [reconnectLast] when the caller wants to rehydrate the highest-
  /// RSSI adapter without opening the picker again.
  List<ResolvedObd2Candidate> _lastRanked = const [];

  Obd2ConnectionService({
    required this.registry,
    required this.permissions,
    required this.bluetooth,
    this.classicBluetooth,
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
    final accumulated = <String, Obd2AdapterCandidate>{};

    final bleStream = bluetooth.scan(
      serviceUuids: registry.allServiceUuids,
      timeout: timeout,
    );
    final classicStream = classicBluetooth?.scan(timeout: timeout) ??
        const Stream<List<Obd2AdapterCandidate>>.empty();

    // #761 — merge BLE + Classic scan streams. Both emit the
    // accumulated-so-far list each tick, so we key by deviceId and
    // re-rank on every event. Closing either stream doesn't end the
    // merged stream — the window is the OUTER [timeout], enforced
    // by the facades themselves.
    final merged = StreamGroup.merge<List<Obd2AdapterCandidate>>(
      [bleStream, classicStream],
    );

    await for (final batch in merged) {
      for (final c in batch) {
        accumulated[c.deviceId] = c;
      }
      final ranked = registry.rank(accumulated.values.toList());
      if (ranked.isNotEmpty) sawAny = true;
      _lastRanked = ranked;
      yield ranked;
    }
    if (!sawAny) {
      throw const Obd2ScanTimeout();
    }
  }

  /// Connect to the specific [candidate]. Dispatches on the
  /// resolved profile's transport — BLE goes through [bluetooth],
  /// Classic goes through [classicBluetooth]. Opens the channel,
  /// runs the ELM327 init, returns the ready service. Surfaces
  /// [Obd2AdapterUnresponsive] when init fails (channel is closed
  /// before the error is rethrown).
  Future<Obd2Service> connect(ResolvedObd2Candidate candidate) async {
    final channel = switch (candidate.profile.transport) {
      BluetoothTransport.ble => bluetooth.channelFor(
          candidate.candidate.deviceId, candidate.profile),
      BluetoothTransport.classic => (classicBluetooth ??
              (throw const Obd2AdapterUnresponsive(
                  'Classic BT transport requested but no Classic '
                  'facade is wired — app misconfiguration')))
          .channelFor(candidate.candidate.deviceId),
    };
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
    classicBluetooth: const StubClassicBluetoothFacade(),
  );
}
