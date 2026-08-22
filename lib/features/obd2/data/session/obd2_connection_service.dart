// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../protocol/adapter_registry.dart';
import '../transport/bluetooth_facade.dart';
import '../transport/classic_bluetooth_facade.dart';
import '../protocol/elm327_adapter.dart';
import '../transport/elm_byte_channel.dart';
import '../last_good_adapter_store.dart';
import '../negotiated_protocol_cache.dart';
import 'obd2_adapter_identity.dart';
import '../obd2_adapter_wake_cache.dart';
import '../obd2_cache_openers.dart';
import '../obd2_comm_diagnostics.dart' show redactObd2Mac;
import '../../domain/obd2_connect_classifier.dart';
import '../obd2_connect_trace.dart';
import '../obd2_connect_trace_log.dart';
import '../../domain/obd2_connection_errors.dart';
import '../obd2_known_adapters_store.dart';
import '../transport/obd2_lost_bond_state.dart';
import '../transport/obd2_pairing_mode.dart';
import '../transport/obd2_permissions.dart';
import '../transport/obd2_platform_budgets.dart';
import '../obd2_read_telemetry.dart';
import '../transport/obd2_scan_governor.dart';
import 'obd2_service.dart';
import '../supported_pids_cache.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../vehicle/providers/vehicle_providers.dart';

part 'obd2_connect_by_mac.dart';
part 'obd2_connect_entries.dart';
part 'obd2_connect_profile_fallback.dart';
part 'obd2_connect_scan.dart';
part 'obd2_connection_service.g.dart';
part 'obd2_open_and_init.dart';
part 'obd2_passive_preempt.dart';

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

  /// #3019 / Epic #3013 phase 3 — auto-pin store for the last-good
  /// adapter. Every SUCCESSFUL connect (the single [_openAndInit]
  /// chokepoint) records the MAC + transport + name here so the
  /// trip-independent reconnect controller can try the fast pinned path
  /// first on the next drop. Local-only (Hive `settings` box), NOT synced.
  /// Null in tests / configs that don't wire it — pinning is then skipped.
  final LastGoodAdapterStore? lastGoodAdapterStore;

  /// #3181 — set of deviceIds that have EVER completed a successful
  /// connect on this phone. The "first connect" discriminator for pairing
  /// mode: an unknown id gets the generous setNotify pairing budget (the
  /// OBDLink CX pairs via the first CCCD subscribe). Null in tests /
  /// configs that don't wire it — pairing mode is then never armed.
  final KnownObd2AdaptersStore? knownAdaptersStore;

  /// #3168 — re-persist seam fired when the scan fallback rematches a
  /// ROTATED iOS CBPeripheral UUID by adapter name (see
  /// [connectUuidRematched]): the pinned id was absent from a non-empty
  /// scan, exactly one device advertised the persisted name, and the
  /// connect to its fresh id SUCCEEDED. The provider wires it to
  /// [repersistRotatedAdapterIdentity] (vehicle-profile update); null in
  /// tests / configs that don't wire it — the rematch still connects,
  /// only the re-persist is skipped.
  final Obd2AdapterIdentityRotated? onAdapterIdentityRotated;

  /// #2906 — settle pause after [_stopScanBeforeConnect] stops the radio and
  /// before a `channel.open()` fires. A `connect()` racing an active scan
  /// still winding down on the radio is the GATT_ERROR 133 trap; a short
  /// settle lets `stopScan()` actually quiesce it. Injectable so tests run
  /// [Duration.zero]; production keeps the observed-safe ~120 ms.
  final Duration scanSettleDelay;

  /// #3185 — process-wide scan-start token bucket (production wires
  /// [Obd2ScanGovernor.process], shared with the facade's scan-seed), so a
  /// dense connect episode can't trip Android's silent 5-scans/30s throttle.
  final Obd2ScanGovernor scanGovernor;

  Obd2ConnectionService({
    required this.registry,
    required this.permissions,
    required this.bluetooth,
    this.classicBluetooth,
    this.supportedPidsCache,
    this.negotiatedProtocolCache,
    this.adapterWakeCache,
    this.activeVehicleKeyFields,
    this.lastGoodAdapterStore,
    this.knownAdaptersStore,
    this.onAdapterIdentityRotated,
    this.scanSettleDelay = const Duration(milliseconds: 120),
    Obd2ScanGovernor? scanGovernor,
  }) : scanGovernor = scanGovernor ?? Obd2ScanGovernor();

  /// #3103 — whether this device can discover Bluetooth-CLASSIC (SPP)
  /// adapters at all. True only when a Classic facade is wired, which the
  /// provider does ONLY on Android. On iOS this is false: Apple restricts
  /// Classic/SPP to MFi hardware, so a Classic-only adapter (vLinker BM,
  /// Konnwei KW902, BAFX…) is invisible to any third-party app — a hard
  /// platform limit, not a bug. The picker reads this to EXPLAIN the limit
  /// ("iPhone uses Bluetooth-LE adapters only") instead of silently showing
  /// nothing, without itself branching on the platform.
  bool get supportsClassicDiscovery => classicBluetooth != null;

  /// Stream of ranked, profile-matched candidates for the picker UI.
  /// Emits the accumulated list on every scan-results change.
  /// Throws [Obd2PermissionDenied] when the runtime permission grant
  /// is missing, [Obd2ScanTimeout] when the scan window elapses with
  /// zero known adapters seen. Body in [_scanImpl] (a `part`, #3760);
  /// the thin instance method stays overridable for test fakes.
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) =>
      _scanImpl(this, timeout: timeout);

  /// Connect to the specific [candidate]. Dispatches on the
  /// resolved profile's transport — BLE goes through [bluetooth],
  /// Classic goes through [classicBluetooth]. Opens the channel,
  /// runs the ELM327 init, returns the ready service. Surfaces
  /// [Obd2AdapterUnresponsive] when init fails (channel is closed
  /// before the error is rethrown).
  ///
  /// Single-flight admission lives UPSTREAM in the one
  /// `Obd2LinkSupervisor` (#3529, Epic #3527) — this service just runs
  /// the attempt it is handed. Body in [_connectTraced] (a `part`, #3760).
  Future<Obd2Service> connect(ResolvedObd2Candidate candidate) =>
      _connectTraced(this, candidate);

  /// Shared channel → transport → service → init sequence used by both
  /// the scan-based [connect] and the no-scan by-MAC paths (#2242). Full
  /// contract on [_openAndInitImpl] (a `part`, #3760); this thin private
  /// delegate keeps `svc._openAndInit` reachable from every sibling part.
  Future<Obd2Service> _openAndInit({
    required ElmByteChannel channel,
    required Elm327Adapter adapter,
    required String mac,
    required String name,
    String linkKind = 'ble',
    bool logFailureAsError = true,
  }) =>
      _openAndInitImpl(this,
          channel: channel,
          adapter: adapter,
          mac: mac,
          name: name,
          linkKind: linkKind,
          logFailureAsError: logFailureAsError);

  /// Convenience entry point — picks the highest-RSSI candidate from
  /// the last scan batch and connects. Returns null when no usable
  /// candidate is cached (e.g. the user hasn't scanned yet this
  /// session). Useful for the "first in-car test" flow that skips
  /// the picker UI (#742). Body in [_connectBestTraced] (a `part`, #3760).
  Future<Obd2Service?> connectBest() => _connectBestTraced(this);

  /// Pinned-adapter fast path (#1188). Runs a short scan and, as soon
  /// as a candidate matching [mac] appears, opens a connection without
  /// involving the picker UI. Returns null when [timeout] elapses
  /// without a match (the adapter is off, out of range, or the user
  /// has changed adapters since the MAC was persisted) so the caller
  /// can fall back to the manual picker. [Obd2ConnectionError]
  /// thrown by the underlying scan/connect flow propagates to the
  /// caller — those are real failures (permission denied, init
  /// timeout) that the caller should surface, not silently swallow.
  /// Body in [_connectByMacImpl] (a `part`, #3760).
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
    String? adapterName,
  }) =>
      _connectByMacImpl(this, mac, timeout: timeout, adapterName: adapterName);

  /// Direct-connect-by-MAC, NO scan (#2242). See [_connectByMacDirect] for the
  /// full contract. A thin INSTANCE method (not an `extension`) so test fakes
  /// can `@override` it — the body lives in the `part` file to keep this file
  /// under the #1680 cap (#2190); the #2969 trace wrap moved to
  /// [_connectByMacDirectTraced] (#3760).
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    // #3113 — null ⇒ the platform-aware cold-connect budget computed in
    // [_connectByMacDirect] (iOS 7s / Android 4s). A caller may still pin an
    // explicit timeout.
    Duration? timeout,
    bool fallbackToScan = true,
    String? adapterName,
  }) =>
      _connectByMacDirectTraced(this, mac,
          timeout: timeout,
          fallbackToScan: fallbackToScan,
          adapterName: adapterName);

  /// Direct-connect-by-MAC over Bluetooth **CLASSIC** SPP, NO scan (#2565).
  /// See [_connectByMacClassicDirect]. Thin overridable instance method.
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
          {String? adapterName}) =>
      _connectByMacClassicDirectTraced(this, mac, adapterName: adapterName);

  /// #3025 / Epic #3013 — TRANSPORT-AWARE direct-connect-by-MAC for the
  /// FIRST-connect / pinned-adapter path. The single entry the cold connect
  /// orchestrators (the trajets pre-warm, the picker's pinned fast path) thread
  /// through so a Classic adapter is NEVER reached on the doomed BLE GATT path.
  ///
  /// The bug this fixes: the pre-warm / pinned connect called the BLE
  /// [connectByMacDirect] UNCONDITIONALLY, so a Classic-SPP adapter could
  /// only ever 4 s-timeout — and that doomed BLE GATT to the same MAC then
  /// POISONED the subsequent RFCOMM socket (`read ret: -1`), so the Classic
  /// fallback ALSO failed. The in-trip reconnect (#2565), the trip-independent
  /// reconnect (#3016) and the self-test (#2969) were already transport-aware.
  ///
  /// Transport is inferred from the paired [adapterName] via the registry name
  /// matchers (the same recovery the self-test uses): a name like
  /// `vLinker BM-Android` resolves to [BluetoothTransport.classic] →
  /// [connectByMacClassicDirect] (RFCOMM, no 4 s BLE timeout, NEVER touches
  /// `channelForDirect`). A BLE name → [connectByMacDirect]. An UNKNOWN /
  /// nameless adapter keeps the historical BLE-direct-first behaviour with the
  /// Classic facade as a fallback — and the BLE channel is fully torn down
  /// (GATT disconnected) between the two so no half-open GATT can poison the
  /// RFCOMM socket. The decision is stamped on the trace's `requestedTransport`
  /// so a future field trace is truthful (a Classic adapter shows `rtx:
  /// classic`, not `ble`).
  ///
  /// Body lives in `obd2_connect_by_mac` (a `part`); this thin overridable
  /// instance method keeps test fakes able to `@override` it.
  Future<Obd2Service?> connectByMacTransportAware(
    String mac, {
    String? adapterName,
    bool fallbackToScan = true,
  }) =>
      _connectByMacTransportAware(this, mac,
          adapterName: adapterName, fallbackToScan: fallbackToScan);

  /// Passive autoConnect reconnect (#2261 concern 2). See
  /// [_connectByMacPassive]. Thin overridable instance method.
  Future<Obd2Service?> connectByMacPassive(String mac, {String? adapterName}) =>
      _connectByMacPassiveTraced(this, mac, adapterName: adapterName);

  /// #2906 — stop the active BLE + Classic scan and pause [scanSettleDelay]
  /// so the radio quiesces before a `channel.open()` connect. Idempotent +
  /// best-effort. Body lives in `obd2_connect_by_mac` (a `part`) so this file
  /// stays under the #1680 cap; the thin instance method keeps it reachable
  /// from [connect] here and from the by-MAC direct/passive paths there.
  Future<void> stopScanBeforeConnect() => _stopScanBeforeConnect(this);

  /// #2907 — close + null any prior direct/passive channel. Body in
  /// [_teardownLastDirectChannelImpl] (a `part`, #3760); this thin private
  /// delegate keeps it reachable from every sibling part unchanged.
  Future<void> _teardownLastDirectChannel() =>
      _teardownLastDirectChannelImpl(this);
}

@Riverpod(keepAlive: true)
Obd2ConnectionService obd2Connection(Ref ref) {
  // #3184(d) — register the adapter-radio-state probe so every ROOT
  // connect/scan trace opens with an `adapter-state` step 0. Lives at this
  // plugin-wiring seam (the one place outside the channel/facade that may
  // touch FlutterBluePlus) so the trace log stays platform-free.
  // `adapterStateNow` is FBP's cached last-known state — no platform call.
  Obd2ConnectTraceLog.adapterStateProbe =
      () => FlutterBluePlus.adapterStateNow.name;
  return Obd2ConnectionService(
    registry: Obd2AdapterRegistry.defaults(),
    permissions: ref.watch(obd2PermissionsProvider),
    bluetooth: const PluginBluetoothFacade(),
    // #3103 — wire the Classic/SPP facade ONLY on Android. iOS cannot use
    // Bluetooth-Classic for non-MFi hardware (Apple restriction), and the
    // facade's method channel has no iOS handler — leaving it wired would
    // raise a spurious MissingPluginException on every iOS scan. Null on iOS
    // ⇒ the scan's `?? Stream.empty()` yields zero Classic candidates by
    // design, and `supportsClassicDiscovery` is false so the picker explains
    // the BLE-only limit. The platform gate lives at this provider seam (the
    // plugin-wiring layer), not in shared business logic.
    classicBluetooth: defaultTargetPlatform == TargetPlatform.android
        ? const PluginClassicBluetoothFacade()
        : null,
    // #2253 — activate the #811 supported-PID cache in production.
    supportedPidsCache: openSupportedPidsCache(),
    // #2261 concern 3 — activate the negotiated-protocol warm cache.
    negotiatedProtocolCache: openNegotiatedProtocolCache(),
    // #2268 concern 3 — per-MAC observed-outcome wake cache, backed by
    // the shared `settings` box (same pattern as the broken-MAP blocklist).
    adapterWakeCache:
        Obd2AdapterWakeCache(ref.watch(settingsStorageProvider)),
    // #3019 / Epic #3013 phase 3 — auto-pin the last-good adapter on every
    // successful connect, backed by the same local `settings` box. Read by
    // the trip-independent reconnect controller for the fast pinned path.
    lastGoodAdapterStore:
        LastGoodAdapterStore(ref.watch(settingsStorageProvider)),
    // #3181 — known-good deviceId set (same local `settings` box). The
    // "first connect" discriminator that arms the generous setNotify
    // pairing budget for a never-bonded adapter (OBDLink CX).
    knownAdaptersStore:
        KnownObd2AdaptersStore(ref.watch(settingsStorageProvider)),
    // #3185 — share the PROCESS-wide scan token bucket with the facade's
    // scan-seed: the Android 5-scans/30s throttle is per app, so every scan
    // start must drain the same bucket.
    scanGovernor: Obd2ScanGovernor.process,
    // #3168 — when the scan fallback rematches a ROTATED iOS CBPeripheral
    // UUID by name, re-persist the fresh id onto every vehicle profile
    // pinned to the stale one (the user-facing adapter name + every other
    // preference stay intact). The helper never throws (best-effort), so
    // the connect that just succeeded can never be derailed.
    onAdapterIdentityRotated: (
            {required String staleId, required Obd2AdapterIdentity fresh}) =>
        repersistRotatedAdapterIdentity(
      profiles: ref.read(vehicleProfileListProvider),
      save: ref.read(vehicleProfileListProvider.notifier).save,
      staleId: staleId,
      fresh: fresh,
    ),
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
