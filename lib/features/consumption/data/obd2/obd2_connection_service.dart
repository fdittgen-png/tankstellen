// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:async/async.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'adapter_registry.dart';
import 'bluetooth_facade.dart';
import 'classic_bluetooth_facade.dart';
import 'elm327_adapter.dart';
import 'elm_byte_channel.dart';
import 'negotiated_protocol_cache.dart';
import 'obd2_adapter_wake_cache.dart';
import 'obd2_cache_openers.dart';
import 'obd2_connection_errors.dart';
import 'obd2_permissions.dart';
import 'obd2_service.dart';
import 'supported_pids_cache.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../vehicle/providers/vehicle_providers.dart';

part 'obd2_connection_service.g.dart';

/// Vehicle identity the supported-PID cache (#811/#2253) refines its
/// per-adapter key with. Supplied lazily by the [Obd2ConnectionService]
/// owner so the data layer never depends on the vehicle feature's
/// providers directly — the Riverpod provider resolves the active
/// profile and hands these three fields through.
typedef Obd2VehicleKeyFields = ({
  String? make,
  String? model,
  int? year,
  String? vin,
});

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

  /// The channel opened by the most recent [connectByMacDirect] (#2242).
  /// Retained so the NEXT direct connect can tear it down before
  /// reopening — Android returns GATT_ERROR 133 if a stale GATT client
  /// for the same device is still open, which would silently fall the
  /// caller back to the scan path. Null once torn down / never used.
  ElmByteChannel? _lastDirectChannel;

  /// Persistent supported-PID bitmap cache (#811), wired into every
  /// session built here (#2253). Null in tests / configs that don't
  /// exercise the cache — the service then behaves exactly as before
  /// (blind PID querying, full support scan every connect).
  final SupportedPidsCache? supportedPidsCache;

  /// Persistent negotiated-protocol cache (#2261 concern 3), wired into
  /// every session built here. Null in tests / configs that don't
  /// exercise it — the service then always runs the cold ATSP0
  /// auto-search, exactly as before.
  final NegotiatedProtocolCache? negotiatedProtocolCache;

  /// Per-MAC observed-outcome wake cache (#2268 concern 3). A connect
  /// reads it to suppress the bounded wake window for a MAC observed
  /// never to need it, and writes back the fresh observation. Null ⇒ the
  /// session always honours the adapter's own [WakePolicy] (a no-op for
  /// every generic adapter, so behaviour is unchanged).
  final Obd2AdapterWakeCache? adapterWakeCache;

  /// Lazily resolves the active vehicle's make / model / year so the
  /// supported-PID cache key can be refined past adapterMac-only
  /// (#2253). Read fresh on every connect because the active vehicle
  /// can change between trips. Null ⇒ adapterMac-only keying.
  final Obd2VehicleKeyFields Function()? activeVehicleKeyFields;

  Obd2ConnectionService({
    required this.registry,
    required this.permissions,
    required this.bluetooth,
    this.classicBluetooth,
    this.supportedPidsCache,
    this.negotiatedProtocolCache,
    this.adapterWakeCache,
    this.activeVehicleKeyFields,
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
    // #1312 — stamp adapter identity onto the service so the trip
    // recorder can persist it on the saved [TripHistoryEntry] and the
    // detail screen can name the device that produced the recording.
    // The friendly name falls back to the registry's display label
    // when the BLE advertisement was empty (matches the picker rule).
    final name = candidate.candidate.deviceName.isEmpty
        ? candidate.profile.displayName
        : candidate.candidate.deviceName;
    return _openAndInit(
      channel: channel,
      adapter: candidate.profile.adapter,
      mac: candidate.candidate.deviceId,
      name: name,
    );
  }

  /// Shared channel → transport → service → init sequence used by both
  /// the scan-based [connect] and the no-scan [connectByMacDirect]
  /// (#2242). Keeping it in ONE place guarantees a direct connect
  /// produces a session identical to the scan path — notably the
  /// service-side ELM327 init (`adapter.initSequence` via
  /// [Obd2Service.connect]), which the transport itself no longer runs
  /// (#2233). Surfaces [Obd2AdapterUnresponsive] when init fails (the
  /// channel is closed before the error is rethrown).
  Future<Obd2Service> _openAndInit({
    required ElmByteChannel channel,
    required Elm327Adapter adapter,
    required String mac,
    required String name,
  }) async {
    // #2253/#2261 — build the session with the supported-PID + warm
    // negotiated-protocol caches wired in (see [buildObd2Session]).
    final vehicle = activeVehicleKeyFields?.call();
    final service = buildObd2Session(
      channel: channel,
      mac: mac,
      name: name,
      pidsCache: supportedPidsCache,
      protocolCache: negotiatedProtocolCache,
      make: vehicle?.make,
      model: vehicle?.model,
      year: vehicle?.year,
      vin: vehicle?.vin,
    );
    // #2268 concern 3 — a no-op override suppresses the wake window for a
    // MAC observed never to need it; null ⇒ honour the adapter policy.
    final wakeOverride = await adapterWakeCache?.overrideFor(mac);
    // #1330 — the per-adapter ELM327 adapter sets the init sequence/timing.
    final ok =
        await service.connect(adapter: adapter, wakePolicyOverride: wakeOverride);
    // #2268 concern 3 — persist the observed wake outcome (a no-op unless
    // the bounded window actually ran on this connect).
    await adapterWakeCache?.recordObservation(mac, service.wakeObservation);
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
    } on Obd2ConnectionError catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'Obd2ConnectionService.connectBest failed'}));
      rethrow;
    }
  }

  /// Pinned-adapter fast path (#1188). Runs a short scan and, as soon
  /// as a candidate matching [mac] appears, opens a connection without
  /// involving the picker UI. Returns null when [timeout] elapses
  /// without a match (the adapter is off, out of range, or the user
  /// has changed adapters since the MAC was persisted) so the caller
  /// can fall back to the manual picker. [Obd2ConnectionError]
  /// thrown by the underlying scan/connect flow propagates to the
  /// caller — those are real failures (permission denied, init
  /// timeout) that the caller should surface, not silently swallow.
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stream = scan(timeout: timeout);
    ResolvedObd2Candidate? match;
    try {
      await for (final batch in stream) {
        for (final c in batch) {
          if (c.candidate.deviceId == mac) {
            match = c;
            break;
          }
        }
        if (match != null) break;
      }
    } on Obd2ScanTimeout {
      // No adapters at all in range — fall through to picker.
      return null;
    }
    if (match == null) return null;
    return connect(match);
  }

  /// Direct-connect-by-MAC, NO scan (#2242). Addresses the adapter via
  /// `BluetoothDevice.fromId(mac)` with a bounded ~4 s [timeout],
  /// skipping the active scan — essential for ELM327 clones that stop
  /// advertising in standby (a scan never sees them; a direct GATT
  /// connect still wakes them). Tears down any prior direct channel
  /// first (Android GATT_ERROR 133 on a stale client), runs the SAME
  /// service-side init as [connect] via [_openAndInit].
  ///
  /// On any failure it falls back to the scan-based [connectByMac], so
  /// behaviour is never worse than today; returns null when both fail.
  /// [fallbackToScan] `false` (the #2245 in-trip path, which owns its
  /// own RSSI-gated scan) returns null immediately on a failed direct
  /// attempt instead of double-scanning.
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
  }) async {
    // Tear down a prior direct channel BEFORE reopening (dead-GATT
    // teardown). LOAD-BEARING on Android — a still-open GATT client for
    // the same device yields GATT_ERROR 133 on the next connect.
    await _teardownLastDirectChannel();

    // No scan ⇒ no resolved profile. Use the registry's generic FFF0
    // BLE profile for the adapter init quirks + display name; its UUIDs
    // match the channel [channelForDirect] builds.
    final generic = _genericBleProfile();
    final channel = bluetooth.channelForDirect(mac, connectTimeout: timeout);
    _lastDirectChannel = channel;
    try {
      return await _openAndInit(
        channel: channel,
        adapter: generic.adapter,
        mac: mac,
        name: generic.displayName,
      );
    } on Object catch (e, st) {
      // Direct attempt failed (connect timeout, GATT 133, init timeout,
      // missing characteristic, …). Close the half-open channel and
      // fall back to the scan path so behaviour is never worse than
      // today's [connectByMac].
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'Obd2ConnectionService.connectByMacDirect — '
            'falling back to scan',
      }));
      await _teardownLastDirectChannel();
      if (!fallbackToScan) return null;
      return connectByMac(mac);
    }
  }

  /// Passive autoConnect reconnect (#2261 concern 2). Opens a channel
  /// with `autoConnect:true` and NO bounded timeout, so the OS holds a
  /// low-power background GATT request that resolves the instant the
  /// pinned adapter advertises again — used by the reconnect scanner
  /// past its active-scan miss ceiling so a parked car stops burning the
  /// radio. NO scan fallback (the passive wait IS the fallback) and NO
  /// requestMtu (FBP forbids it with autoConnect). Returns null on any
  /// failure; runs the SAME service-side init via [_openAndInit].
  Future<Obd2Service?> connectByMacPassive(String mac) async {
    await _teardownLastDirectChannel();
    final generic = _genericBleProfile();
    final channel = bluetooth.channelForDirect(mac, autoConnect: true);
    _lastDirectChannel = channel;
    try {
      return await _openAndInit(
        channel: channel,
        adapter: generic.adapter,
        mac: mac,
        name: generic.displayName,
      );
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'Obd2ConnectionService.connectByMacPassive failed',
      }));
      await _teardownLastDirectChannel();
      return null;
    }
  }

  Future<void> _teardownLastDirectChannel() async {
    final prior = _lastDirectChannel;
    _lastDirectChannel = null;
    if (prior == null) return;
    try {
      await prior.close();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'Obd2ConnectionService: prior-direct-channel teardown',
      }));
    }
  }

  Obd2AdapterProfile _genericBleProfile() => registry.profiles.firstWhere(
        (p) => p.id == 'generic-fff0',
        orElse: () => registry.profiles.firstWhere(
          (p) => p.transport == BluetoothTransport.ble,
        ),
      );
}

@Riverpod(keepAlive: true)
Obd2ConnectionService obd2Connection(Ref ref) {
  return Obd2ConnectionService(
    registry: Obd2AdapterRegistry.defaults(),
    permissions: ref.watch(obd2PermissionsProvider),
    bluetooth: const PluginBluetoothFacade(),
    classicBluetooth: const PluginClassicBluetoothFacade(),
    // #2253 — activate the #811 supported-PID cache in production.
    supportedPidsCache: openSupportedPidsCache(),
    // #2261 concern 3 — activate the negotiated-protocol warm cache.
    negotiatedProtocolCache: openNegotiatedProtocolCache(),
    // #2268 concern 3 — per-MAC observed-outcome wake cache, backed by
    // the shared `settings` box (same pattern as the broken-MAP blocklist).
    adapterWakeCache:
        Obd2AdapterWakeCache(ref.watch(settingsStorageProvider)),
    activeVehicleKeyFields: () {
      // Defensive: the vehicle provider must never make a connect throw.
      try {
        final v = ref.read(activeVehicleProfileProvider);
        return (make: v?.make, model: v?.model, year: v?.year, vin: v?.vin);
      } catch (_) {
        return (make: null, model: null, year: null, vin: null);
      }
    },
  );
}
