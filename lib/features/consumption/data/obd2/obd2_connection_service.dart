// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'adapter_registry.dart';
import 'bluetooth_facade.dart';
import 'classic_bluetooth_facade.dart';
import 'elm327_adapter.dart';
import 'elm_byte_channel.dart';
import 'negotiated_protocol_cache.dart';
import 'obd2_adapter_wake_cache.dart';
import 'obd2_cache_openers.dart';
import 'obd2_connect_classifier.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import 'obd2_permissions.dart';
import 'obd2_read_telemetry.dart';
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

  /// #2906 — settle pause after [_stopScanBeforeConnect] stops the radio and
  /// before a `channel.open()` fires. Android BLE is fragile if a `connect()`
  /// races an active scan still winding down on the radio — a stale scan can
  /// hold the controller long enough that the connect returns GATT_ERROR 133.
  /// A short settle lets `stopScan()` actually quiesce the radio. Injectable
  /// so tests run it as [Duration.zero] (no real wait); production keeps the
  /// observed-safe ~120 ms.
  final Duration scanSettleDelay;

  Obd2ConnectionService({
    required this.registry,
    required this.permissions,
    required this.bluetooth,
    this.classicBluetooth,
    this.supportedPidsCache,
    this.negotiatedProtocolCache,
    this.adapterWakeCache,
    this.activeVehicleKeyFields,
    this.scanSettleDelay = const Duration(milliseconds: 120),
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

    // #2969 — record each newly-seen ranked candidate into the active connect
    // trace so a failed connect's trace carries the scan list (device + RSSI +
    // matched profile + transport). Deduped by MAC so a repeating batch doesn't
    // spam the capped list. A no-op when no trace is active (the picker UI scan,
    // which has no connect attempt in flight).
    final tracedScanMacs = <String>{};
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
        }
      }
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
    // #2268 concern 3 — a no-op override suppresses the wake window for a
    // MAC observed never to need it; null ⇒ honour the adapter policy.
    final wakeOverride = await adapterWakeCache?.overrideFor(mac);
    // #1330 init. #2379 — recoverable attempts suppress the fail trace.
    final ok = await service.connect(adapter: adapter,
        wakePolicyOverride: wakeOverride, logFailureAsError: logFailureAsError);
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
      _traced(
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
        },
      );

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
    Duration timeout = const Duration(seconds: 4),
    bool fallbackToScan = true,
    String? adapterName,
  }) =>
      _traced(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: mac,
        adapterName: adapterName, // #3014 — name the BLE by-MAC attempt
        requestedTransport: Obd2ConnectTransport.ble,
        body: () => _connectByMacDirect(this, mac,
            timeout: timeout, fallbackToScan: fallbackToScan),
      );

  /// Direct-connect-by-MAC over Bluetooth **CLASSIC** SPP, NO scan (#2565).
  /// See [_connectByMacClassicDirect]. Thin overridable instance method.
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
          {String? adapterName}) =>
      _traced(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: mac,
        adapterName: adapterName, // #3014 — name the Classic by-MAC attempt
        requestedTransport: Obd2ConnectTransport.classic,
        body: () => _connectByMacClassicDirect(this, mac),
      );

  /// Passive autoConnect reconnect (#2261 concern 2). See
  /// [_connectByMacPassive]. Thin overridable instance method.
  Future<Obd2Service?> connectByMacPassive(String mac, {String? adapterName}) =>
      _traced(
        origin: Obd2ConnectOrigin.liveReconnect,
        mac: mac,
        adapterName: adapterName, // #3014 — name the passive reconnect attempt
        requestedTransport: Obd2ConnectTransport.ble,
        body: () => _connectByMacPassive(this, mac),
      );

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
