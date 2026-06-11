// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'adapter_registry.dart';
import 'bluetooth_facade.dart';
import 'classic_bluetooth_facade.dart';
import 'elm327_adapter.dart';
import 'elm_byte_channel.dart';
import 'last_good_adapter_store.dart';
import 'negotiated_protocol_cache.dart';
import 'obd2_adapter_identity.dart';
import 'obd2_adapter_wake_cache.dart';
import 'obd2_cache_openers.dart';
import 'obd2_comm_diagnostics.dart' show redactObd2Mac;
import 'obd2_connect_classifier.dart';
import 'obd2_connect_supervisor.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import 'obd2_known_adapters_store.dart';
import 'obd2_pairing_mode.dart';
import 'obd2_permissions.dart';
import 'obd2_read_telemetry.dart';
import 'obd2_scan_governor.dart';
import 'obd2_service.dart';
import 'supported_pids_cache.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../vehicle/providers/vehicle_providers.dart';

part 'obd2_connect_by_mac.dart';
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
  /// before a `channel.open()` fires. Android BLE is fragile if a `connect()`
  /// races an active scan still winding down on the radio — a stale scan can
  /// hold the controller long enough that the connect returns GATT_ERROR 133.
  /// A short settle lets `stopScan()` actually quiesce the radio. Injectable
  /// so tests run it as [Duration.zero] (no real wait); production keeps the
  /// observed-safe ~120 ms.
  final Duration scanSettleDelay;

  /// #3185 — single-flight connect ADMISSION. Every public connect entry
  /// threads through it, so the six historical connect owners (picker
  /// pinned fast-path, recording pre-warm, auto-record orchestrator,
  /// trip-independent reconnect, in-trip ReconnectConnector, VIN reader)
  /// are demoted to REQUESTERS — a second entrant queues instead of
  /// tearing the first's half-open GATT down mid-handshake. Per-instance,
  /// which IS per-process in production (this service is a keepAlive
  /// singleton); tests get isolated instances.
  final Obd2ConnectSupervisor supervisor;

  /// #3185 — process-wide scan-start token bucket (the production provider
  /// wires [Obd2ScanGovernor.process], shared with the facade's scan-seed),
  /// so a dense connect episode can't trip Android's silent 5-scans/30s
  /// throttle. Tests default to a fresh isolated bucket.
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
    Obd2ConnectSupervisor? supervisor,
    Obd2ScanGovernor? scanGovernor,
  })  : supervisor = supervisor ?? Obd2ConnectSupervisor(),
        scanGovernor = scanGovernor ?? Obd2ScanGovernor();

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
  /// zero known adapters seen.
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // #3184(f) — picker-UI scans get a trace too. A standalone scan ("I
    // scanned and saw nothing") previously left NO artefact. When a
    // connect entry already opened a trace, this begin returns a CHILD
    // recording into the same trace (and the end/outcome below become
    // no-ops via [Obd2ConnectTraceHandle.isRoot]), so connect-path
    // behaviour is unchanged.
    final scanTrace =
        Obd2ConnectTraceLog.beginTrace(origin: Obd2ConnectOrigin.pickerScan);
    var sawAny = false;
    try {
      final state = await permissions.request();
      if (state != Obd2PermissionState.granted) {
        throw const Obd2PermissionDenied();
      }

      // #3185 — pace the radio scan start through the governor so a dense
      // connect episode (scan-seed + fallback scans + user retry) can't trip
      // Android's silent 5-scans/30s throttle. Fails open; a throttle pause
      // is stamped on the trace as a `scan-throttle` step.
      await scanGovernor.admitScanStart(reason: 'service-scan');

      final accumulated = <String, Obd2AdapterCandidate>{};

      // #3097 — scan UNFILTERED: a withServices filter starves iOS of name-only
      // ELM327 clones; registry.rank still drops non-adapter noise post-scan.
      final bleStream =
          bluetooth.scan(serviceUuids: const {}, timeout: timeout);
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

      // #2969 — record each newly-seen ranked candidate into the active
      // connect trace so a failed connect's trace carries the scan list
      // (device + RSSI + matched profile + transport). Deduped by MAC so a
      // repeating batch doesn't spam the capped list.
      final tracedScanMacs = <String>{};
      // #3184(e)/#3168 — deviceIds already stamped `pinned-id-mismatch`.
      final mismatchStamped = <String>{};
      await for (final batch in merged) {
        for (final c in batch) {
          accumulated[c.deviceId] = c;
        }
        final ranked = registry.rank(accumulated.values.toList());
        if (ranked.isNotEmpty) sawAny = true;
        _lastRanked = ranked;
        final trace = Obd2ConnectTraceLog.active;
        if (trace != null) {
          for (final r in ranked) {
            if (tracedScanMacs.add(r.candidate.deviceId)) {
              trace.recordScan(
                mac: r.candidate.deviceId,
                name: r.candidate.deviceName,
                rssi: r.candidate.rssi,
                transport: r.profile.transport == BluetoothTransport.classic
                    ? Obd2ConnectTransport.classic
                    : Obd2ConnectTransport.ble,
                matchedProfileId: r.profile.id,
              );
            }
            _stampPinnedIdMismatch(trace, r, mismatchStamped);
          }
        }
        yield ranked;
      }
      if (!sawAny) {
        throw const Obd2ScanTimeout();
      }
      // classification-only binding; rethrow preserves the stack.
      // ignore: catch_no_st
    } catch (e) {
      if (scanTrace.isRoot) scanTrace.setOutcomeFromError(e);
      rethrow;
    } finally {
      if (scanTrace.isRoot && !scanTrace.hasOutcome) {
        scanTrace.setOutcome(sawAny
            ? Obd2ConnectOutcome.success
            : Obd2ConnectOutcome.scanEmpty);
      }
      Obd2ConnectTraceLog.endTrace(scanTrace);
    }
  }

  /// #3184(e) — the #3168 discriminator: a scanned device whose NAME
  /// matches the pinned adapter's name but whose deviceId DIFFERS. On iOS
  /// the deviceId is a per-app CBPeripheral UUID (not the MAC) and can
  /// rotate after an unpair / restore / adapter re-provision — the pinned
  /// id then dials a ghost while the real adapter advertises under a new
  /// id. This step makes that visible in the field trace: see #3168.
  void _stampPinnedIdMismatch(
    Obd2ConnectTraceHandle trace,
    ResolvedObd2Candidate r,
    Set<String> stamped,
  ) {
    final pinnedMac = trace.rawRequestedMac;
    final pinnedName = trace.adapterName;
    if (pinnedMac == null || pinnedMac.isEmpty) return;
    if (pinnedName == null || pinnedName.isEmpty) return;
    final c = r.candidate;
    if (c.deviceName != pinnedName) return;
    if (c.deviceId.toUpperCase() == pinnedMac.toUpperCase()) return;
    if (!stamped.add(c.deviceId)) return;
    trace.addStep(
      label: 'pinned-id-mismatch',
      status: Obd2ConnectStepStatus.fail,
      detail: 'scanned "${c.deviceName}" under id '
          '${redactObd2Mac(c.deviceId)} but the pinned id is '
          '${redactObd2Mac(pinnedMac)} — iOS UUID-vs-MAC identity drift? '
          '(#3168)',
    );
  }

  /// Connect to the specific [candidate]. Dispatches on the
  /// resolved profile's transport — BLE goes through [bluetooth],
  /// Classic goes through [classicBluetooth]. Opens the channel,
  /// runs the ELM327 init, returns the ready service. Surfaces
  /// [Obd2AdapterUnresponsive] when init fails (channel is closed
  /// before the error is rethrown).
  ///
  /// #3185 — like every public connect entry, runs under the single-flight
  /// [supervisor]: a concurrent caller queues instead of racing. A nested
  /// re-entry (the scan fallback of a by-MAC connect lands here) runs
  /// inline inside the outer admission.
  Future<Obd2Service> connect(ResolvedObd2Candidate candidate) =>
      supervisor.admit(
        owner: 'connect',
        attempt: () => _connectTraced(candidate),
      );

  /// The pre-#3185 [connect] body (trace open/outcome wrap around
  /// [_connectResolved]); kept verbatim so admission stays a thin shell.
  Future<Obd2Service> _connectTraced(ResolvedObd2Candidate candidate) async {
    // #2969 — open (or join) a connect trace for the scan-based path. A child
    // when an outer by-MAC/best trace is already open (so the whole attempt is
    // ONE trace); the root when `connect(candidate)` is the entry (the
    // reconnect scan-fallback calls it directly). On success/throw the wrapper
    // stamps the outcome; the steps + resolved transport are recorded below.
    final trace = Obd2ConnectTraceLog.beginTrace(
      origin: Obd2ConnectOrigin.firstConnect,
      mac: candidate.candidate.deviceId,
      // #3014 — the scan resolved a real candidate, so its name is known: the
      // advertised name, or the registry display label when the advertisement
      // was anonymous. Fills the trace headline for a scan-path connect.
      adapterName: candidate.candidate.deviceName.isEmpty
          ? candidate.profile.displayName
          : candidate.candidate.deviceName,
      requestedTransport:
          candidate.profile.transport == BluetoothTransport.classic
              ? Obd2ConnectTransport.classic
              : Obd2ConnectTransport.ble,
    );
    try {
      final svc = await _connectResolved(candidate);
      trace.setOutcome(Obd2ConnectOutcome.success);
      return svc;
      // rethrow preserves the stack; the (e) binding only classifies the trace.
      // ignore: catch_no_st
    } catch (e) {
      trace.setOutcomeFromError(e);
      rethrow;
    } finally {
      Obd2ConnectTraceLog.endTrace(trace);
    }
  }

  /// The scan-based connect body (#2969 extraction): channel → transport →
  /// service → init for an already-resolved [candidate]. Kept separate so the
  /// public [connect] can wrap it in a connect trace.
  Future<Obd2Service> _connectResolved(ResolvedObd2Candidate candidate) async {
    // #2906 — stop any active scan (BLE + Classic) and let the radio settle
    // BEFORE the channel opens. Android BLE returns GATT_ERROR 133 when a
    // `connect()` races a scan still winding down on the controller; the
    // scan-fallback `connect` is the worst offender (it reaches here straight
    // out of the `await for` scan loop, whose subscription cancels — and so
    // calls `stopScan()` — only asynchronously). Stopping + settling here
    // closes that race for every connect path that funnels through `connect`.
    await stopScanBeforeConnect();
    // #2907 — tear down any stale direct/passive channel from a PRIOR
    // by-MAC connect before the scan path opens a fresh one. The
    // [connectByMacDirect]/[connectByMacPassive] paths already self-clean,
    // but the SCAN-fallback `connect` did not — so an in-trip reconnect that
    // tried a direct connect (which retained `_lastDirectChannel`) and then
    // fell back to the gated scan left that GATT client open, and Android
    // returned GATT_ERROR 133 on the scan-path open against the same device
    // (the repeat-133 reconnect trap). Idempotent + best-effort.
    await _teardownLastDirectChannel();
    // #2969 — stamp the resolved transport on the active connect trace. The
    // scan path resolved a real profile, so this is the authoritative transport
    // (unlike the no-scan by-MAC paths, which stamp their requested transport).
    Obd2ConnectTraceLog.active?.setResolvedTransport(
      candidate.profile.transport == BluetoothTransport.classic
          ? Obd2ConnectTransport.classic
          : Obd2ConnectTransport.ble,
    );
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
    // detail screen can name the device. The friendly name falls back to
    // the registry display label when the advertisement was empty.
    final name = candidate.candidate.deviceName.isEmpty
        ? candidate.profile.displayName
        : candidate.candidate.deviceName;
    return _openAndInit(
      channel: channel,
      adapter: candidate.profile.adapter,
      mac: candidate.candidate.deviceId,
      name: name,
      linkKind: obd2LinkKindOf(candidate.profile.transport),
    );
  }

  /// Shared channel → transport → service → init sequence used by both
  /// the scan-based [connect] and the no-scan [connectByMacDirect]
  /// (#2242). Keeping it in ONE place guarantees a direct connect
  /// produces a session identical to the scan path — notably the
  /// service-side ELM327 init (`adapter.initSequence` via
  /// [Obd2Service.connect]), which the transport itself no longer runs
  /// (#2233). Surfaces [Obd2AdapterUnresponsive] when init fails (the
  /// channel is closed first).
  Future<Obd2Service> _openAndInit({
    required ElmByteChannel channel,
    required Elm327Adapter adapter,
    required String mac,
    required String name,
    String linkKind = 'ble',
    bool logFailureAsError = true,
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
      linkKind: linkKind, // #2465 — gated comm-diagnostics session label
    );
    // #3181 — FIRST-connect detection: a deviceId with NO recorded
    // successful connect (and that isn't the auto-pinned last-good
    // adapter — the pre-#3181 migration case) gets pairing mode armed for
    // the duration of this attempt, so the BLE channel widens the
    // setNotify budget to the 30 s pairing window and the UI can show the
    // "confirm the pairing request" hint. Cleared in `finally` so a
    // failed attempt never leaks the mode.
    final firstConnect = _isFirstConnectDevice(mac);
    if (firstConnect) {
      Obd2PairingMode.markFirstConnect(mac);
      Obd2ConnectTraceLog.active?.addStep(
        label: 'first-connect',
        status: Obd2ConnectStepStatus.ok,
        detail: 'deviceId has no prior successful connect — '
            '${Obd2PairingMode.firstConnectSetNotifySecs}s pairing budget '
            'armed (#3181)',
      );
    }
    try {
      // #2268 concern 3 — a no-op override suppresses the wake window for a
      // MAC observed never to need it; null ⇒ honour the adapter policy.
      final wakeOverride = await adapterWakeCache?.overrideFor(mac);
      // #1330 init. #2379 — recoverable attempts suppress the fail trace.
      final ok = await service.connect(adapter: adapter,
          wakePolicyOverride: wakeOverride,
          logFailureAsError: logFailureAsError);
      // #2268 concern 3 — persist the observed wake outcome (no-op unless the bounded window ran).
      await adapterWakeCache?.recordObservation(mac, service.wakeObservation);
      if (!ok) {
        // #2969 — `Obd2Service.connect` swallowed the real failure into a `false`,
        // so classify the connect-trace outcome from the AT transcript teed so
        // far (channel-open outcomes were already stamped FIRST at the channel
        // layer, and first-wins keeps those): ATZ garbage → counterfeit clone,
        // an AT timeout → init timeout, else a silent ECU / ignition off. A no-op
        // when no trace is active (a non-connect-path caller).
        final trace = Obd2ConnectTraceLog.active;
        if (trace != null && !trace.hasOutcome) {
          trace.setOutcome(trace.classifyInitFailureOutcome());
        }
        await service.disconnect();
        // #3181 — a pairing-classified failure (the channel-open catch /
        // Obd2Service.connect stamped it, first-wins) surfaces TYPED so the
        // by-MAC paths skip the masking scan fallback and the UI shows the
        // "power-cycle and retry within 5 minutes" guidance — not the
        // generic adapter-unresponsive message.
        if (trace?.outcome == Obd2ConnectOutcome.pairingRequired) {
          throw const Obd2PairingRequired();
        }
        throw const Obd2AdapterUnresponsive();
      }
      // #3181 — ANY successful init (even an engine-off one) proves the
      // BOND + link work, so the deviceId is no longer a first connect.
      await knownAdaptersStore?.markKnownGood(mac);
    } finally {
      if (firstConnect) Obd2PairingMode.clearFirstConnect(mac);
    }
    // #3009/#3035 — init SUCCEEDED (every AT answered) but the vehicle bus
    // may be SILENT. CRITICAL distinction (#3035): the `0100` probe is now
    // tri-state ([Obd2Service.busProbe]). Stamp `ignitionOff` ONLY on
    // [Obd2BusProbeResult.probedSilent] — the ECU stayed silent through every
    // retry, the real engine-off signature. A [Obd2BusProbeResult.transient]
    // (the first `0100` merely TIMED OUT during the protocol search on a slow
    // clone) must NOT be classified engine-off — that was the false positive
    // that told a live car "turn the ignition on" and spun reconnects. The
    // connect still returns the service either way (first-wins on the trace);
    // we only correct the CLASSIFICATION, never the working connect path.
    if (service.busProbe == Obd2BusProbeResult.probedSilent) {
      Obd2ConnectTraceLog.active?.setOutcome(Obd2ConnectOutcome.ignitionOff);
    }
    // #3019 / Epic #3013 phase 3 — auto-pin the last-good adapter so the
    // trip-INDEPENDENT reconnect controller can try the fast pinned path on
    // the next drop. #3035 — but do NOT pin on a confirmed engine-off
    // (`probedSilent`): pinning a silent-bus connect is exactly what fed the
    // teardown→reconnect→engine-off loop. The HARDWARE link is good on a
    // [Obd2BusProbeResult.answered] OR [Obd2BusProbeResult.transient] connect
    // (a slow-but-live car) and on a warm cache-hit (`busAnswered`), so pin in
    // those cases. Best-effort + local-only (the store swallows + logs a write
    // failure), so it never derails a connect that just succeeded.
    final pinnable = service.busProbe != Obd2BusProbeResult.probedSilent &&
        (service.busAnswered ||
            service.busProbe == Obd2BusProbeResult.transient);
    if (pinnable) {
      await lastGoodAdapterStore?.recordFrom(
        mac: service.adapterMac,
        transportKind: service.linkKind,
        name: service.adapterName,
      );
    }
    return service;
  }

  /// #3181 — whether [mac] has NEVER completed a successful connect on
  /// this phone. False when no [knownAdaptersStore] is wired (tests /
  /// legacy configs — pairing mode is then never armed), when the store
  /// knows the id, or when it matches the auto-pinned last-good adapter
  /// (a pre-#3181 user who already connected must not re-enter pairing
  /// mode before the store backfills on their next success).
  bool _isFirstConnectDevice(String mac) {
    final store = knownAdaptersStore;
    if (store == null) return false;
    if (store.isKnownGood(mac)) return false;
    final pinned = lastGoodAdapterStore?.recall();
    if (pinned != null &&
        pinned.mac.trim().toUpperCase() == mac.trim().toUpperCase()) {
      return false;
    }
    return true;
  }

  /// Convenience entry point — picks the highest-RSSI candidate from
  /// the last scan batch and connects. Returns null when no usable
  /// candidate is cached (e.g. the user hasn't scanned yet this
  /// session). Useful for the "first in-car test" flow that skips
  /// the picker UI (#742).
  ///
  /// #3185 — single-flight admitted (see [connect]); the inner
  /// `connect(candidate)` re-entry runs inline inside this admission.
  Future<Obd2Service?> connectBest() =>
      supervisor.admit(owner: 'connectBest', attempt: _connectBestTraced);

  Future<Obd2Service?> _connectBestTraced() async {
    // #2969 — connectBest() was the silent dead-end: an empty `_lastRanked`
    // returned null with NO trace, so the user's "it won't connect" left
    // nothing. Open a trace at the entry so even the no-candidate case is
    // captured with a `scanEmpty` outcome. The inner `connect(candidate)` joins
    // this as a child trace, so a real attempt is still ONE trace.
    final trace = Obd2ConnectTraceLog.beginTrace(
      origin: Obd2ConnectOrigin.firstConnect,
    );
    try {
      if (_lastRanked.isEmpty) {
        trace.addStep(
          label: 'rank',
          status: Obd2ConnectStepStatus.fail,
          detail: 'no ranked candidate cached — scan first',
        );
        trace.setOutcome(Obd2ConnectOutcome.scanEmpty);
        return null;
      }
      final svc = await _connectBestInner();
      trace.setOutcome(Obd2ConnectOutcome.success);
      return svc;
      // rethrow preserves the stack; the (e) binding only classifies the trace
      // (permission / BT-off throw before registry.rank, so recordScan misses).
      // ignore: catch_no_st
    } catch (e) {
      trace.setOutcomeFromError(e);
      rethrow;
    } finally {
      Obd2ConnectTraceLog.endTrace(trace);
    }
  }

  /// De-noise wrapper preserved from the pre-#2969 `connectBest`: the trace is
  /// owned by the public method above; this keeps the #2935/#2943 breadcrumb-
  /// vs-ERROR behaviour. (Kept as a separate seam so the trace bookkeeping and
  /// the error-log de-noise stay independently testable.)
  Future<Obd2Service> _connectBestInner() async {
    try {
      return await connect(_lastRanked.first);
    } catch (e, st) {
      // #2379 final-failure log → #2943 (error-log #28/29): completing the
      // #2935 de-noise. An EXPECTED engine-off condition (Obd2AdapterUnresponsive
      // et al.) or a bare ELM327 connect TimeoutException de-noises to a
      // breadcrumb here instead of spooling an ERROR on every probe of a
      // parked car (5× in that log); a GENUINE fault (Obd2PermissionDenied,
      // Obd2ProtocolInitFailed, any non-expected error) still ERROR-logs on
      // `other`. The error is rethrown either way so the caller's own
      // handling is unchanged. (Catching broadly — not just
      // Obd2ConnectionError — lets the shared de-noiser classify a raw
      // TimeoutException too; #1103 satisfied via the (e, st) binding.)
      recordObd2ConnectTransient(e, st,
          where: 'Obd2ConnectionService.connectBest failed',
          layer: ErrorLayer.other);
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
    String? adapterName,
  }) =>
      _supervised('connectByMac', () => _traced(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: mac,
        adapterName: adapterName,
        // #3014 — was hard-coded `unknown`. When the caller passes the paired
        // name, infer the transport from the registry name matchers (the same
        // recovery the self-test uses) so the trace records `ble`/`classic`
        // instead of `unknown` for a scan-based pinned connect.
        requestedTransport:
            _inferTransport(registry.transportForName(adapterName)),
        body: () async {
          final stream = scan(timeout: timeout);
          ResolvedObd2Candidate? match;
          // #3168 — the latest accumulated ranked list, retained for the
          // UUID-rotation rematch when no exact deviceId match is found.
          var ranked = const <ResolvedObd2Candidate>[];
          try {
            await for (final batch in stream) {
              ranked = batch;
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
          if (match != null) return connect(match);
          // #3168 — exact id absent from a NON-empty scan: on iOS the
          // pinned CBPeripheral UUID may have ROTATED. Try the name-based
          // rematch (+ re-persist of the fresh id on success); a no-match
          // still returns null so the picker fallback is unchanged.
          return connectUuidRematched(
            pinnedId: mac,
            pinnedName: adapterName,
            ranked: ranked,
            connect: connect,
            onIdentityRotated: onAdapterIdentityRotated,
          );
        },
      ));

  /// Direct-connect-by-MAC, NO scan (#2242). See [_connectByMacDirect] for the
  /// full contract. A thin INSTANCE method (not an `extension`) so test fakes
  /// can `@override` it — the body lives in the `part` file to keep this file
  /// under the #1680 cap (#2190).
  ///
  /// #2969 — wrapped in a connect trace at this service entry point (the single
  /// virtual-dispatch chokepoint every by-MAC caller funnels through), so a
  /// failed FIRST connect / in-trip reconnect — even with developer mode off —
  /// leaves a non-empty trace. Records `requestedTransport: ble` (this IS the
  /// BLE direct path); the inner body stamps the channel-open outcome BEFORE
  /// any scan fallback (first-wins).
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    // #3113 — null ⇒ the platform-aware cold-connect budget computed in
    // [_connectByMacDirect] (iOS 7s / Android 4s). A caller may still pin an
    // explicit timeout.
    Duration? timeout,
    bool fallbackToScan = true,
    String? adapterName,
  }) =>
      _supervised('connectByMacDirect', () => _traced(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: mac,
        adapterName: adapterName, // #3014 — name the BLE by-MAC attempt
        requestedTransport: Obd2ConnectTransport.ble,
        body: () => _connectByMacDirect(this, mac,
            timeout: timeout, fallbackToScan: fallbackToScan),
      ));

  /// Direct-connect-by-MAC over Bluetooth **CLASSIC** SPP, NO scan (#2565).
  /// See [_connectByMacClassicDirect]. Thin overridable instance method.
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
          {String? adapterName}) =>
      _supervised('connectByMacClassicDirect', () => _traced(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: mac,
        adapterName: adapterName, // #3014 — name the Classic by-MAC attempt
        requestedTransport: Obd2ConnectTransport.classic,
        body: () => _connectByMacClassicDirect(this, mac),
      ));

  /// #3025 / Epic #3013 — TRANSPORT-AWARE direct-connect-by-MAC for the
  /// FIRST-connect / pinned-adapter path. The single entry the cold connect
  /// orchestrators (the trajets pre-warm, the picker's pinned fast path) thread
  /// through so a Classic adapter is NEVER reached on the doomed BLE GATT path.
  ///
  /// The bug this fixes: the pre-warm / pinned connect called the BLE
  /// [connectByMacDirect] UNCONDITIONALLY, so a Classic-SPP adapter (vLinker
  /// BM-Android) could only ever 4 s-timeout (`FlutterBluePlusException |
  /// connect | fbp-code:1 | Timed out after 4s`) — and that doomed BLE GATT to
  /// the same MAC then POISONED the subsequent RFCOMM socket (`read ret: -1` /
  /// "socket might closed"), so the Classic fallback ALSO failed. The in-trip
  /// reconnect (#2565), the trip-independent reconnect (#3016) and the self-test
  /// (#2969) were already transport-aware; this brings firstConnect in line.
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
      _supervised(
          'connectByMacTransportAware',
          () => _connectByMacTransportAware(this, mac,
              adapterName: adapterName, fallbackToScan: fallbackToScan));

  /// Passive autoConnect reconnect (#2261 concern 2). See
  /// [_connectByMacPassive]. Thin overridable instance method.
  ///
  /// #3185 — admitted as a PASSIVE attempt: the unbounded autoConnect wait
  /// SKIPS its cycle (returns null, the scanner keeps its cadence) when any
  /// other attempt is in flight, and while it holds the slot an arriving
  /// active requester preempts it via [_teardownLastDirectChannel] (closing
  /// the passive channel unwinds the wait) — so a parked-car wait can never
  /// starve a user-initiated connect.
  Future<Obd2Service?> connectByMacPassive(String mac, {String? adapterName}) =>
      supervisor.admitPassive(
        owner: 'connectByMacPassive',
        onPreempt: _teardownLastDirectChannel,
        attempt: () => _traced(
          origin: Obd2ConnectOrigin.liveReconnect,
          mac: mac,
          adapterName: adapterName, // #3014 — name the passive attempt
          requestedTransport: Obd2ConnectTransport.ble,
          body: () => _connectByMacPassive(this, mac),
        ),
      );

  /// #3185 — single-flight shell every ACTIVE public connect entry threads
  /// through (see [supervisor]). Kept as one helper so the entries stay
  /// thin and the admission policy lives in exactly one place.
  Future<Obd2Service?> _supervised(
    String owner,
    Future<Obd2Service?> Function() body,
  ) =>
      supervisor.admit(owner: owner, attempt: body);

  /// #3014 — map a nullable registry [BluetoothTransport] hint onto the trace's
  /// [Obd2ConnectTransport] (null ⇒ `unknown`, the honest no-hint state).
  static Obd2ConnectTransport _inferTransport(BluetoothTransport? t) =>
      switch (t) {
        BluetoothTransport.classic => Obd2ConnectTransport.classic,
        BluetoothTransport.ble => Obd2ConnectTransport.ble,
        null => Obd2ConnectTransport.unknown,
      };

  /// #2969 — open (or join) a connect trace around [body], stamp the terminal
  /// outcome (success when a service comes back; the inner-stamped outcome — or
  /// `scanEmpty` as the default — when null; the classified error on a throw),
  /// and finalise it into [Obd2ConnectTraceLog]. The single wrapper every
  /// public by-MAC connect entry threads through, so a failure at ANY phase
  /// (incl. the pre-session phases) is captured. Re-entrant safe: a nested
  /// connect (a fallback re-entering a public method) joins the same trace.
  Future<Obd2Service?> _traced({
    required Obd2ConnectOrigin origin,
    String? mac,
    String? adapterName,
    required Obd2ConnectTransport requestedTransport,
    required Future<Obd2Service?> Function() body,
  }) async {
    final trace = Obd2ConnectTraceLog.beginTrace(
      origin: origin,
      mac: mac,
      adapterName: adapterName,
      requestedTransport: requestedTransport,
    );
    try {
      final svc = await body();
      if (svc != null) {
        trace.setOutcome(Obd2ConnectOutcome.success);
      } else if (!trace.hasOutcome) {
        // A clean null with NO inner-stamped outcome means the scan/transport
        // path never matched the adapter — the scan-empty / not-in-range case.
        trace.setOutcome(Obd2ConnectOutcome.scanEmpty);
      }
      return svc;
      // rethrow preserves the stack; the (e) binding only classifies the trace.
      // ignore: catch_no_st
    } catch (e) {
      trace.setOutcomeFromError(e);
      rethrow;
    } finally {
      Obd2ConnectTraceLog.endTrace(trace);
    }
  }

  /// #2906 — stop the active BLE + Classic scan and pause [scanSettleDelay]
  /// so the radio quiesces before a `channel.open()` connect. Idempotent +
  /// best-effort. Body lives in `obd2_connect_by_mac` (a `part`) so this file
  /// stays under the #1680 cap; the thin instance method keeps it reachable
  /// from [connect] here and from the by-MAC direct/passive paths there.
  Future<void> stopScanBeforeConnect() => _stopScanBeforeConnect(this);

  Future<void> _teardownLastDirectChannel() async {
    final prior = _lastDirectChannel;
    _lastDirectChannel = null;
    if (prior == null) return;
    try {
      await prior.close();
    } catch (e, st) {
      // #2379 — OBD2/BLE, not local storage.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'Obd2ConnectionService: prior-direct-channel teardown',
      }));
    }
  }
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
    // start must drain the same bucket. (The default per-instance supervisor
    // is already process-wide here — this provider is a keepAlive singleton.)
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
