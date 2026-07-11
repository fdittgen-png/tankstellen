// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../core/domain/vehicle_profile.dart';
import 'adapter_capability.dart';
import 'auto_record_trace_log.dart';
import 'bluetooth_obd2_transport.dart';
import 'elm327_adapter.dart';
import 'elm327_precision_pids.dart';
import 'elm327_protocol.dart';
import 'fuel_rate_estimator.dart' as estimator;
import 'negotiated_protocol_cache.dart';
import 'obd2_atpc_teardown.dart';
import 'obd2_breadcrumb_collector.dart';
import 'obd2_can_frame_stream.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import 'obd2_read_telemetry.dart';
import 'obd2_service_session.dart';
import 'obd2_debug_session.dart';
import 'obd2_fuel_rate_reader.dart';
import 'obd2_odometer_reader.dart';
import 'obd2_transport.dart';
import 'oem_pid_table.dart';
import 'supported_pids_cache.dart';
import 'supported_pids_probe.dart' show kObd2ProtocolSearchTimeout;
import 'supported_pids_resolver.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/health_counters.dart';

// #3035 — re-export the tri-state `0100` probe outcome so the connection
// layer (which imports this service) gates `ignitionOff` on [busProbe]
// without reaching into the resolver directly.
export 'supported_pids_probe.dart' show Obd2BusProbeResult;

// Re-export the pure-math estimator + stoichiometric constants so
// callers that only need the math (e.g. [TripRecordingController]'s
// cached live sampler) can import one file instead of chasing statics
// on [Obd2Service]. New callers should import `fuel_rate_estimator.dart`
// directly; the static forwarders on [Obd2Service] stay for backwards
// compatibility with pre-#563 call sites.
export 'fuel_rate_estimator.dart'
    show
        kPetrolAfr,
        kDieselAfr,
        kPetrolDensityGPerL,
        kDieselDensityGPerL,
        kDefaultEngineDisplacementCc,
        kDefaultVolumetricEfficiency,
        resolveAfrDensity, // #2432 — fuel-type AFR/density lookup
        effectiveAfrForPhi, // #2456/#3426 — equivalence-ratio-φ effective AFR
        applyFuelTrimCorrection,
        estimateFuelRateLPerHourFromMap;

/// What the bounded wake window observed on the FIRST init command of a
/// fresh connect (#2268 concern 2). Drives the per-MAC observed-outcome
/// wake cache (#2268 concern 3): the connection service records
/// `wakeNeeded` only on a [wokeAfterNudge] outcome, and records
/// `never-needed` only on an [answeredImmediately] outcome.
enum WakeObservation {
  /// The wake window did not run — either no [WakePolicy] was active for
  /// this connect or it was suppressed by the cache. The connect path
  /// has no evidence either way, so the cache must NOT be updated.
  notRun,

  /// The wake window ran and the FIRST command answered on the first
  /// attempt — this adapter did not need waking on this connect. Strong
  /// evidence the MAC never needs the window.
  answeredImmediately,

  /// The wake window ran, the FIRST command timed out / threw, and a
  /// re-send after the longer settle then succeeded — observed proof the
  /// adapter was asleep and the window recovered it.
  wokeAfterNudge,

  /// The wake window ran and every attempt (original + all nudges)
  /// failed. No positive evidence — connect will fail downstream; the
  /// cache must NOT be updated on a failed connect.
  failed,
}

/// High-level OBD-II service for reading vehicle data.
///
/// Wraps [Obd2Transport] and [Elm327Protocol] to provide a clean API
/// for reading odometer, speed, and other vehicle parameters.
///
/// Also implements [Obd2RawCommandPort] (#1401 phase 3 / #1423 phase 2)
/// — the narrow facade OEM tables and the broken-MAP detector accept.
/// The [sendRaw] method delegates to [sendCommand]; production callers
/// pass the live service unchanged, tests pass a 5-line fake.
class Obd2Service implements Obd2RawCommandPort, Obd2FuelRateReads {
  final Obd2Transport _transport;

  /// Owns the #811 supported-PID concern — the persistent cache, the
  /// per-connection PID set, and the vehicle-key resolution that
  /// picks the cache slot. Extracted from this class in #1679; built
  /// in the constructor body so it can capture the [_send] tear-off.
  late final SupportedPidsResolver _pids;

  /// #3528 (Epic #3527) — the protocol session owning the classify-
  /// before-you-kill ladder, the staleness watchdog and the ATRV
  /// keepalive for this connection. Attached by [connect] once the rich
  /// init succeeded; detached by [disconnect]. Lifecycle + send routing
  /// live in [Obd2ServiceSession].
  final Obd2ServiceSession _session = Obd2ServiceSession();

  /// Stable adapter identifier (BLE remote-id / Classic MAC) for the
  /// device backing this session (#1312). Stamped by
  /// [Obd2ConnectionService] on connect so downstream consumers
  /// (the trip recorder) can attribute a recorded trip to a specific
  /// hardware adapter without reaching back into the connection
  /// service. Null when the service was constructed without going
  /// through the connection layer (test fakes / direct transport
  /// construction).
  String? adapterMac;

  /// Friendly device name advertised by the adapter (#1312). Falls
  /// back to the registry's display name when the BLE advertisement
  /// is empty. Stamped at the same moment as [adapterMac].
  String? adapterName;

  /// Transport flavour backing this session — `'ble'` / `'classic'`
  /// (#2465). Stamped by [Obd2ConnectionService] alongside [adapterMac]
  /// so [connect] can open the comm-diagnostics session with the link
  /// kind without the data layer reaching back into the registry. Null
  /// for test fakes / direct transport construction (the diagnostics
  /// session then records a null link kind, which is fine — it is gated
  /// off in production anyway).
  String? linkKind;

  /// ELM327 firmware string (whatever `ATI` returned during init), if
  /// the adapter reported one (#1312, #1401). Populated by [connect]
  /// after the init sequence completes — null only when the adapter
  /// returned an empty / NO-DATA response to `ATI`, or when the test
  /// fake didn't wire one in. Persisted/round-tripped by
  /// [TripHistoryEntry] so device-test reports can name the exact
  /// firmware variant.
  String? adapterFirmware;

  /// Runtime capability tier of the connected adapter (#1401 phase 1).
  /// Defaults to [Obd2AdapterCapability.standardOnly] before [connect]
  /// has read the firmware string, and is replaced with the parsed
  /// value after the init sequence runs. Phase 1 ships read-only —
  /// no production call site branches on this value yet.
  Obd2AdapterCapability _capability = Obd2AdapterCapability.standardOnly;

  /// Firmware-string-claimed tier, captured at connect (#2261 concern
  /// 6). The lazy multi-frame probe in [ensureCapabilityReconciled]
  /// reconciles [_capability] down from this if the adapter can't
  /// actually route a multi-frame request.
  Obd2AdapterCapability _claimedCapability =
      Obd2AdapterCapability.standardOnly;

  /// `true` once the multi-frame `0902` probe has reconciled (or was
  /// unnecessary because the claimed tier is already standardOnly). Lets
  /// [ensureCapabilityReconciled] run at most once per connect (#2261).
  bool _capabilityReconciled = true;

  /// Runtime capability tier of the connected adapter (#1401 phase 1).
  /// See [_capability] for semantics.
  Obd2AdapterCapability get capability => _capability;

  /// `true` when the lazy multi-frame capability probe (#2261 concern 6)
  /// still needs to run — i.e. the firmware claimed a tier above
  /// standardOnly and [ensureCapabilityReconciled] hasn't confirmed it
  /// yet. Exposed for the recorder to know whether a deferred probe is
  /// still pending.
  bool get capabilityNeedsReconcile => !_capabilityReconciled;

  /// Per-adapter ELM327 quirks (#1330). Set by [connect] from the
  /// caller-supplied `adapter` parameter; defaults to the
  /// [GenericElm327Adapter] which mirrors today's hardcoded init
  /// sequence + 100 ms delays + identity preParse. Phase 2 will hand
  /// in vLinker / SmartOBD specialisations from the adapter registry.
  Elm327Adapter _adapter = const GenericElm327Adapter();

  /// Adapter snapshot used during the most recent [connect]. Exposed
  /// for tests + diagnostics; production callers should use the typed
  /// read* methods rather than reaching for the adapter directly.
  @visibleForTesting
  Elm327Adapter get adapter => _adapter;

  /// Optional fuel-rate diagnostic breadcrumb collector (#1395). When
  /// present, every PID 5E read + MAF read inside
  /// [readFuelRateLPerHour] is captured into a ring buffer the
  /// in-app diagnostic overlay can render. Null in production paths
  /// that don't need the trace (e.g. one-shot VIN reads); the trip
  /// recording controller wires it up at the start of each trip via
  /// the [breadcrumbCollector] setter. Typed as the
  /// [Obd2BreadcrumbRecorder] interface so production passes the
  /// Riverpod notifier (state-republishing) and unit tests pass the
  /// raw [Obd2BreadcrumbCollector].
  Obd2BreadcrumbRecorder? breadcrumbCollector;

  /// Persistent negotiated-protocol cache (#2261 concern 3). When
  /// present and [_protocolCacheKey] resolves, a warm connect replays
  /// `ATSP{n}` for the cached protocol instead of paying the multi-second
  /// `ATSP0` auto-search. Null in tests / configs that don't exercise it
  /// — connect then always runs the cold ATSP0 search, exactly as before.
  final NegotiatedProtocolCache? _protocolCache;

  /// Lookup key for [_protocolCache] — `adapterMac(:vin)`. Supplied by
  /// the owner so the data layer never resolves vehicle identity itself.
  final String? _protocolCacheKey;

  /// What the bounded wake window observed on the most recent [connect]
  /// (#2268 concern 2). [WakeObservation.notRun] until a connect with an
  /// active (non-suppressed) [WakePolicy] runs the window. The connection
  /// service reads this after connect to update the per-MAC wake cache
  /// (#2268 concern 3). Never updated on a connect that didn't run the
  /// window, so a generic-adapter connect leaves it [notRun].
  WakeObservation wakeObservation = WakeObservation.notRun;

  Obd2Service(
    this._transport, {
    SupportedPidsCache? pidsCache,
    String? vehicleFallbackKey,
    NegotiatedProtocolCache? protocolCache,
    String? protocolCacheKey,
    this.breadcrumbCollector,
  })  : _protocolCache = protocolCache,
        _protocolCacheKey = protocolCacheKey {
    // #1916 — the supported-PIDs prime + discovery run during connect,
    // when the BLE link is least settled. Wrap their `_send` callback
    // with the same one-shot retry the init handshake now uses, so a
    // single lost write at trip-start doesn't reach the user as a
    // connect failure. After prime returns, the resolver only serves
    // the cached set (no further `_send`), so no live-polling call
    // sites pick up the wrapper.
    _pids = SupportedPidsResolver(
      send: (cmd) => _withConnectRetry(cmd, _send),
      // #3037 — the first `0100` probe uses the GENEROUS protocol-search read
      // window (~15 s) so the ELM327 auto-search resolves within ONE read,
      // instead of re-sending mid-search (which restarts the search).
      // Deliberately NOT wrapped in [_withConnectRetry]: that wrapper re-sends
      // on ANY throw INCLUDING a read TimeoutException, which for `0100` would
      // restart the protocol search — the exact #3037 bug. The probe itself
      // owns the bounded re-send, and ONLY on a genuine transport throw (a
      // failed write, where the command never reached the adapter so the
      // search never started), never on a timeout.
      searchSend: _sendWithProtocolSearchWindow,
      isConnected: () => _transport.isConnected,
      cache: pidsCache,
      vehicleFallbackKey: vehicleFallbackKey,
    );
  }

  /// #1916 — settle delay between the first connect-time send and its
  /// single retry. Matches the polling-loop value
  /// [TripRecordingController._transportRetryDelay] so the same
  /// transient-blip window is absorbed in both phases. Exposed as
  /// `@visibleForTesting` so the connect-retry unit test runs in
  /// milliseconds instead of waiting a real 150 ms per case.
  @visibleForTesting
  static Duration connectRetryDelay = const Duration(milliseconds: 150);

  /// One-shot retry around a connect-time send. The init sequence,
  /// the `ATI` firmware probe, and the supported-PIDs prime all route
  /// through this — Bluetooth links hiccup briefly in the first few
  /// seconds of a fresh link (a lost write, an RF collision); the
  /// retry absorbs that common transient case so it never propagates
  /// up to `connect()` returning `false`. The same pattern lives in
  /// the polling loop as `TripRecordingController._runTransport`
  /// (#1904) — here we extend it to the connect / init phase the
  /// polling-loop guard doesn't cover.
  Future<String> _withConnectRetry(
    String command,
    Future<String> Function(String) inner,
  ) async {
    try {
      return await inner(command);
    } catch (e, st) {
      debugPrint('OBD2 connect-time send retry after $e\n$st');
      await Future<void>.delayed(connectRetryDelay);
      return inner(command);
    }
  }

  /// Hard ceiling on the per-nudge wake settle (#2268 concern 2) so a
  /// mis-seeded [WakePolicy.wakeSettle] can never stall trip-start
  /// indefinitely. The window the connect path actually applies is
  /// `min(wakeSettle, wakeSettleCap)`.
  static const Duration wakeSettleCap = Duration(seconds: 3);

  /// Hard ceiling on [WakePolicy.maxNudges] (#2268 concern 2). One nudge
  /// is the realistic value (a single re-send after the adapter has had
  /// time to wake); the cap guards against a runaway seeded value
  /// turning the wake batch into an unbounded retry loop.
  static const int maxNudgeCap = 2;

  /// Test hook to scale the real wake-settle down to milliseconds so the
  /// concern-2 unit tests don't wait real seconds. Production keeps it at
  /// `1.0`. Multiplies the (already-capped) settle just before sleeping.
  @visibleForTesting
  static double wakeSettleScale = 1.0;

  /// Bounded extra-settle + first-command nudge for a sleeping adapter
  /// (#2268 concern 2).
  ///
  /// Runs ONLY when [policy.isActive] — i.e. a distinctive STN-/OBDLink-
  /// class adapter opted in (none paired today) and the cache did not
  /// suppress it. The first init command on a fresh open gets a
  /// purpose-built window: the original attempt, then up to
  /// `min(policy.maxNudges, maxNudgeCap)` RE-SENDS, each preceded by a
  /// settle of `min(policy.wakeSettle, wakeSettleCap)`. This is longer
  /// than the steady-state [_withConnectRetry] blip guard and is NOT an
  /// AT "wake byte" — a BLE client cannot wake an ATLP-sleeping ELM327
  /// with a magic byte; the lever is "wait, then ask again".
  ///
  /// Sets [wakeObservation] to the outcome so the connection service can
  /// feed the per-MAC wake cache (concern 3). Returns the successful
  /// response, or rethrows the LAST failure when every attempt failed so
  /// the surrounding connect still fails exactly as it would today.
  Future<String> _sendFirstCommandWithWake(
    String command,
    WakePolicy policy,
  ) async {
    final cappedSettleUs = policy.wakeSettle.inMicroseconds
        .clamp(0, wakeSettleCap.inMicroseconds);
    final settle = Duration(
      microseconds: (cappedSettleUs * wakeSettleScale).round(),
    );
    final nudges = policy.maxNudges.clamp(0, maxNudgeCap);

    // Attempt 0 — the original send. Immediate success ⇒ the adapter was
    // already awake; strong evidence the MAC never needs the window.
    try {
      final response = await _transport.sendCommand(command);
      wakeObservation = WakeObservation.answeredImmediately;
      return response;
    } catch (e, st) {
      debugPrint('OBD2 wake: first command "$command" failed ($e), '
          'entering bounded wake window\n$st');
    }

    // Nudges — settle, then re-send. A success here is observed proof the
    // adapter was asleep and the window recovered it.
    Object lastError = StateError('wake window had no nudges to try');
    StackTrace lastStack = StackTrace.current;
    for (var n = 0; n < nudges; n++) {
      await Future<void>.delayed(settle);
      try {
        final response = await _transport.sendCommand(command);
        wakeObservation = WakeObservation.wokeAfterNudge;
        return response;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        debugPrint('OBD2 wake: nudge ${n + 1}/$nudges for "$command" '
            'failed ($e)\n$st');
      }
    }

    // Every attempt failed — rethrow so connect fails as it would today.
    wakeObservation = WakeObservation.failed;
    Error.throwWithStackTrace(lastError, lastStack);
  }

  /// AT command that asks the ELM327 to identify itself. Returns a
  /// version string like `ELM327 v1.5` / `ELM327 v2.2` /
  /// `STN1110 v4.0.4` (#1401 phase 1).
  static const String _atiCommand = 'ATI\r';

  /// Strip the trailing ELM prompt (`>`) plus any CR/LF noise from a
  /// raw `ATI` response. Returns null when the response was a
  /// NO-DATA-style placeholder.
  static String? _parseFirmwareString(String raw) {
    var s = raw.replaceAll('\r', ' ').replaceAll('\n', ' ');
    s = s.replaceAll('>', '').trim();
    // Collapse runs of whitespace introduced by stripping CR/LF.
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return null;
    if (s.toUpperCase().contains('NO DATA')) return null;
    return s;
  }

  /// Look up the protocol digit cached for this adapter+vehicle, or null
  /// when no cache is wired / no key resolves / no entry exists (#2261
  /// concern 3). A non-null result drives a warm `ATSP{n}` init.
  String? _cachedProtocolDigit() {
    final cache = _protocolCache;
    final key = _protocolCacheKey;
    if (cache == null || key == null) return null;
    try {
      return cache.get(key);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'OBD2 negotiated-protocol cache read failed',
      }));
      return null;
    }
  }

  /// Read `ATDPN`, strip the auto-flag, and persist the negotiated
  /// protocol for next session (#2261 concern 3).
  ///
  /// When [warmConnect] is true (we pinned a cached `ATSP{n}`) and the
  /// adapter cannot describe a working protocol — `ATDPN` returns a
  /// NO-DATA / UNABLE / error placeholder — the cached protocol was
  /// wrong (different car on the same adapter, ECU swapped). We then
  /// invalidate the entry, fall back to the `ATSP0` auto-search, and
  /// re-read ATDPN to re-cache the freshly negotiated value.
  ///
  /// Best-effort throughout: any send failure is swallowed so the
  /// connect still succeeds with whatever protocol the init left active.
  Future<void> _resolveAndCacheProtocol({required bool warmConnect}) async {
    final cache = _protocolCache;
    final key = _protocolCacheKey;
    if (cache == null || key == null) return;
    try {
      var digit = Elm327Protocol.parseProtocolNumber(
        await _withConnectRetry(
          Elm327Protocol.describeProtocolNumberCommand,
          _transport.sendCommand,
        ),
      );
      if (digit == null && warmConnect) {
        // The pinned protocol can't talk to this bus — drop it and
        // re-run the cold ATSP0 auto-search, then re-read ATDPN.
        await cache.invalidate(key);
        await _transport.sendCommand(Elm327Protocol.autoProtocolCommand);
        digit = Elm327Protocol.parseProtocolNumber(
          await _transport.sendCommand(
            Elm327Protocol.describeProtocolNumberCommand,
          ),
        );
      }
      if (digit != null) {
        await cache.put(key, digit);
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'OBD2 negotiated-protocol resolve/cache failed',
      }));
    }
  }

  /// Whether [command] is a reset / wake command that needs a settle
  /// delay after it (#2261 concern 5) — ATZ (full reset) or ATWS (warm
  /// start). Every other AT echo / OBD request is serialised by the
  /// transport's prompt-wait and needs no extra sleep.
  static bool _isResetCommand(String command) {
    final c = command.trim().toUpperCase();
    return c == 'ATZ' || c == 'ATWS';
  }

  /// `true` when the underlying [Obd2Transport] currently has an open
  /// connection to the vehicle's ELM327 adapter.
  bool get isConnected => _transport.isConnected;

  /// `true` when the vehicle bus actually answered during the last connect —
  /// a protocol digit was cached (`ATDPN` returned a real protocol) OR PID
  /// discovery (`0100`) found ≥1 supported PID (#2892).
  ///
  /// A HEALTHY ELM chip on a SILENT bus (ignition off / ECU asleep) passes
  /// every AT command — [isConnected] and [connect] both report success — yet
  /// `ATDPN`→NO DATA caches no protocol and `0100`→NO DATA leaves
  /// [debugSupportedPids] empty, so a started trip is degraded GPS-only with
  /// no explanation. Callers gate on [busAnswered] after connect to surface
  /// the localized "turn the ignition on" condition ([Obd2AdapterUnresponsive])
  /// instead. Cheap (reads already-resolved fields, no I/O); gated STRICTLY on
  /// the no-answer signal so it never trips when discovery returned PIDs.
  bool get busAnswered =>
      _cachedProtocolDigit() != null || debugSupportedPids.isNotEmpty;

  /// Tri-state outcome of the last `0100` supported-PIDs probe (#3035).
  ///
  /// [busAnswered] is a boolean ("did the bus reply at all?"), which the
  /// false-engine-off bug (#3035) over-loaded: a `0100` that merely TIMED
  /// OUT during the ELM327 protocol search left it `false` and the connect
  /// path wrongly stamped `ignitionOff`. This getter is the finer signal the
  /// connection layer gates on instead:
  ///
  ///   - [Obd2BusProbeResult.answered] — the ECU returned a `41 00` bitmap;
  ///   - [Obd2BusProbeResult.probedSilent] — the ECU stayed silent through
  ///     every retry (genuine engine-off — the ONLY case that may classify
  ///     `ignitionOff`);
  ///   - [Obd2BusProbeResult.transient] — every retry hit a timeout / blip
  ///     (indeterminate, NOT engine-off — keep the session usable);
  ///   - [Obd2BusProbeResult.notProbed] — discovery didn't run (a warm
  ///     cache-hit connect, where [busAnswered] already trips on the cached
  ///     protocol / PID set).
  ///
  /// Cheap (reads the already-resolved resolver field, no I/O).
  Obd2BusProbeResult get busProbe => _pids.lastProbeResult;

  /// Send a raw command to the ELM327 adapter and return the raw
  /// response. Exposed for the [PidScheduler]-based trip recording
  /// loop (#814) — the scheduler dispatches individual PID commands
  /// directly and parses responses PID-by-PID, rather than going
  /// through the typed `readRpm` / `readSpeed` helpers. Keeping the
  /// escape hatch on the service lets the transport stay private.
  ///
  /// #3528 — routed through the live [ElmSession]'s classification
  /// ladder when one is attached, so the scheduler's polling traffic
  /// (the bulk of a trip's I/O) feeds the garbage/ATWS + CAN/ATPC
  /// recovery rungs and refreshes the staleness watchdog.
  Future<String> sendCommand(String command) => _rawSend(command);

  /// #3528 — the ONE raw-send funnel (see [Obd2ServiceSession.send]).
  Future<String> _rawSend(String command) =>
      _session.send(command, _transport);

  /// [Obd2RawCommandPort] facade — verbatim pass-through to
  /// [sendCommand]. Lets OEM tables (#1401 phase 3) and the
  /// broken-MAP detector (#1423 phase 2) accept the live service
  /// without depending on the full surface area.
  @override
  Future<String> sendRaw(String command) => sendCommand(command);

  /// Connect and initialize the ELM327 adapter.
  ///
  /// The init sequence + timing is sourced from [adapter] (#1330).
  /// Default is [GenericElm327Adapter] — same byte-for-byte init
  /// sequence and 100 ms delays the service has used since the
  /// feature shipped. Phases 2/3 will hand in vLinker / SmartOBD
  /// specialisations.
  ///
  /// After the init sequence, if a [SupportedPidsCache] was wired in
  /// via the constructor (#811) this also:
  ///   1. Reads the VIN from the car (Mode 09 PID 02). Falls back to
  ///      the optional `vehicleFallbackKey` when no VIN comes back.
  ///   2. Looks up the supported-PID set by that key. On cache hit,
  ///      populates the in-memory set and skips the scan entirely —
  ///      saves 8 × `01 XX` Bluetooth round-trips every session.
  ///   3. On cache miss, runs [discoverSupportedPids] and persists
  ///      the result under the chosen key for next time.
  /// [wakePolicyOverride] (#2268 concern 2/3) lets the connection service
  /// override the adapter's own [Elm327Adapter.wakePolicy] for THIS
  /// connect based on the per-MAC observed-outcome cache: pass
  /// [WakePolicy.noop] to suppress the bounded wake window for a MAC the
  /// cache recorded as never-needing it. Null ⇒ use the adapter's policy
  /// (a no-op for every generic adapter, so behaviour is unchanged).
  ///
  /// [logFailureAsError] (#2379) — `false` returns `false` silently (no
  /// error trace) for callers that immediately recover (direct-by-MAC +
  /// scan fallback, passive autoConnect); the final failure is logged by
  /// the orchestrator + breadcrumbs. Default `true` for the final attempt.
  Future<bool> connect({
    Elm327Adapter adapter = const GenericElm327Adapter(),
    WakePolicy? wakePolicyOverride,
    bool logFailureAsError = true,
  }) async {
    // #1920 — trace the connect attempt so a failed recording session
    // can be analysed from the exportable OBD2 diagnostic log.
    AutoRecordTraceLog.add(
      AutoRecordEventKind.connectStarted,
      mac: adapterMac,
    );
    // #3146 — always-on connect-rate tally (attempts vs successes), so a
    // slowly-failing adapter is visible in the error-log export even when
    // the debug-gated comm-diagnostics collector is off.
    healthCounters.increment('ble.connect.attempts');
    try {
      _adapter = adapter;
      // #2268 concern 2 — a fresh connect resets the wake observation;
      // it only moves off [WakeObservation.notRun] if the bounded wake
      // window actually runs (active policy, not cache-suppressed).
      wakeObservation = WakeObservation.notRun;

      // #2465 — open a gated comm-diagnostics session (no-op unless
      // Feature.debugMode armed the collector). #2466 — begin it BEFORE
      // `_transport.connect()` opens the channel so the channel's gated
      // connect-lifecycle counters attach to THIS session.
      Obd2CommDiagnostics.instance.beginSession(
        linkKind: linkKind,
        redactedMac: redactObd2Mac(adapterMac),
      );
      await _transport.connect();

      // Clear the per-connection supported-PIDs cache. A new session
      // may be a different car / different adapter firmware.
      _pids.resetForNewConnection();
      // #2261 concern 6 — a fresh connect re-arms the lazy capability
      // probe; it stays armed only when the ATI block below claims a
      // tier above standardOnly.
      _capabilityReconciled = true;

      // Adapter-driven init sequence (#1330). [GenericElm327Adapter]
      // matches the legacy hardcoded behaviour byte-for-byte: the
      // shared ELM init list followed by 100 ms after the first
      // command (ATZ) and 100 ms between each subsequent command.
      //
      // #2261 concern 3 — on a WARM connect, replay the protocol pinned
      // last session: swap the `ATSP0` auto-search for `ATSP{n}` so the
      // ELM327 skips the multi-second protocol probe. On a cold connect
      // (no cache hit) the sequence is untouched and ATSP0 runs as before.
      final warmProtocol = _cachedProtocolDigit();
      final sequence = <String>[
        ...adapter.initSequence,
        ...adapter.extraInitCommands,
      ];
      if (warmProtocol != null) {
        for (var i = 0; i < sequence.length; i++) {
          if (sequence[i] == Elm327Protocol.autoProtocolCommand) {
            sequence[i] = Elm327Protocol.setProtocolCommand(warmProtocol);
            break;
          }
        }
      }
      // #2268 concern 2 — resolve the effective wake policy for THIS
      // connect. The cache (concern 3) can suppress the window by passing
      // a no-op override; otherwise the adapter's own policy applies — a
      // no-op for every generic adapter, so the first command goes through
      // the unchanged [_withConnectRetry] path below.
      final wakePolicy = wakePolicyOverride ?? adapter.wakePolicy;
      for (var i = 0; i < sequence.length; i++) {
        // #1925 — time each handshake command for the opt-in OBD2
        // debug log (a no-op when debug logging is off).
        // #1916 — route through [_withConnectRetry] so a single
        // transient BLE blip during the init sequence is absorbed
        // rather than failing the whole connect attempt.
        final sw = Stopwatch()..start();
        // #2268 concern 2 — the FIRST command on a fresh open gets the
        // purpose-built bounded wake window when (and only when) an active
        // wake policy applies. Every other command — and every first
        // command for a generic adapter — runs the unchanged steady-state
        // retry path, so behaviour is byte-for-byte the same by default.
        final String response;
        if (i == 0 && wakePolicy.isActive) {
          response = await _sendFirstCommandWithWake(sequence[i], wakePolicy);
        } else {
          response = await _withConnectRetry(
            sequence[i],
            _transport.sendCommand,
          );
        }
        sw.stop();
        Obd2DebugSessionRecorder.recordHandshakeCommand(
          sequence[i],
          response,
          sw.elapsedMilliseconds,
        );
        // #2465 — tee the same timed handshake line into the comm-health
        // collector (gated; no-op unless Feature.debugMode is on).
        Obd2CommDiagnostics.instance.recordHandshakeLine(
          sequence[i],
          response,
          sw.elapsedMilliseconds,
        );
        // #2261 concern 5 — drop the fixed inter-command sleep for
        // trivial AT echoes: the prompt-wait in [BluetoothObd2Transport]
        // already serialises one command per `>` reply, so a blind
        // 100 ms sleep between ATE0/ATL0/ATH0/… is pure dead time on the
        // critical path. Keep a SHORT settle ONLY after the reset/wake
        // commands (ATZ/ATWS), where a slow clone re-enumerates and a
        // back-to-back command can race the reset. The adapter still
        // owns the actual settle duration via [postResetDelay].
        if (_isResetCommand(sequence[i])) {
          await Future<void>.delayed(adapter.postResetDelay);
        }
      }

      // Capture the firmware-version string and derive the runtime
      // capability tier (#1401 phase 1). Sent after the init sequence
      // so echo / line-feeds / headers are off and the response is
      // clean. Failures here are non-fatal — we keep the
      // [Obd2AdapterCapability.standardOnly] default and let the
      // connect succeed. No call site branches on `capability` yet.
      try {
        // #1916 — same retry guard as the init sequence; the ATI probe
        // is the first command after the init burst and a hiccup here
        // would skip firmware-tier detection entirely.
        final atiSw = Stopwatch()..start();
        final raw = await _withConnectRetry(
          _atiCommand,
          _transport.sendCommand,
        );
        atiSw.stop();
        Obd2DebugSessionRecorder.recordHandshakeCommand(
          _atiCommand,
          raw,
          atiSw.elapsedMilliseconds,
        );
        // #2465 — tee the ATI probe into the comm-health collector too.
        Obd2CommDiagnostics.instance.recordHandshakeLine(
          _atiCommand,
          raw,
          atiSw.elapsedMilliseconds,
        );
        final firmware = _parseFirmwareString(raw);
        if (firmware != null && firmware.isNotEmpty) {
          adapterFirmware = firmware;
        }
        _capability = detectCapabilityFromFirmwareString(firmware);
        // #2261 concern 6 — the multi-frame `0902` probe that downgrades
        // a lying clone (#1614) used to run HERE, blocking connect for up
        // to 4 s on the start critical path. It is now deferred to
        // [ensureCapabilityReconciled], run lazily after the first
        // samples, so perceived start is not delayed. The claimed tier
        // above is what gating sees until then — safe, because standard
        // PID collection never depends on it, and the lazy probe only
        // ever LOWERS the tier (never enables a feature prematurely).
        _claimedCapability = _capability;
        _capabilityReconciled =
            _capability == Obd2AdapterCapability.standardOnly;
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'OBD2 ATI firmware read failed'}));
      }

      // #2261 concern 3 — read ATDPN to learn the negotiated protocol
      // and persist it for next session's warm connect. When a warm
      // ATSP{n} was attempted but the protocol can't actually talk to
      // the bus, this re-runs ATSP0 + re-caches. Non-fatal: any failure
      // just leaves the cache as-is and the connect still succeeds.
      await _resolveAndCacheProtocol(warmConnect: warmProtocol != null);

      // #2465 — stamp the resolved adapter identity into the comm-health
      // session (gated; no-op unless Feature.debugMode is on). The
      // protocol digit is whatever the warm-replay pinned or the cold
      // ATSP0 search just negotiated + re-cached; `warmStart` records
      // whether this connect replayed a cached protocol. The capability
      // tier here is the firmware-CLAIMED value (Wave 1) — the lazy
      // multi-frame probe that reconciles it lands in Wave 2.
      Obd2CommDiagnostics.instance.recordAdapterIdentity(
        elmVersion: adapterFirmware,
        protocolDigit: _cachedProtocolDigit(),
        warmStart: warmProtocol != null,
        capabilityTier: _capability.name,
      );

      await _pids.prime();

      // #3528 — the link is initialized: attach the protocol session
      // (ladder + staleness watchdog + keepalive) over it.
      _session.start(_transport, linkKind: () => linkKind, mac: () => adapterMac);

      // #1920 — record the successful handshake with the firmware
      // string when the adapter reported one.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.connectSucceeded,
        mac: adapterMac,
        detail: adapterFirmware,
      );
      healthCounters.increment('ble.connect.successes'); // #3146
      return true;
    } catch (e, st) {
      // #3181 — a TYPED pairing failure from the channel's setNotify stage
      // must not be flattened invisibly into the generic `false` below:
      // stamp the active connect trace (first-wins; the FBP channel-open
      // catch usually stamped it already, but a fake/non-FBP channel
      // doesn't) so `_openAndInit` can rethrow the typed Obd2PairingRequired
      // and the UI shows the power-cycle guidance.
      if (e is Obd2PairingRequired) {
        Obd2ConnectTraceLog.active?.setOutcome(
          Obd2ConnectOutcome.pairingRequired,
          failureDetail: e.toString(),
        );
      }
      // #2379 final-failure log → #2933 (error-log #25): an EXPECTED engine-off
      // condition (Obd2AdapterUnresponsive et al.) de-noises to a breadcrumb
      // instead of an ERROR every retry (42/44 of that log); a GENUINE fault
      // (permission / counterfeit-clone init) still ERROR-logs on `other`.
      if (logFailureAsError) {
        recordObd2ConnectTransient(e, st,
            where: 'OBD2 connect failed', layer: ErrorLayer.other);
      }
      // #1920 — record the failure so the diagnostic log shows the
      // connect attempt that never produced a session.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.connectFailed,
        mac: adapterMac,
        detail: e.toString(),
      );
      healthCounters.increment('ble.connect.failures'); // #3146
      return false;
    }
  }

  /// Whether [pid] should be queried this connection (#811, rewritten by
  /// #3532). Delegates to [SupportedPidsResolver.isPidSupported]:
  /// OPTIMISTIC — the discovered bitmap no longer rejects (clones
  /// under-report it); only runtime probation (3× real `NO DATA`, fed by
  /// the read helpers) parks a PID for the rest of the connection.
  @override
  bool isPidSupported(int pid) => _pids.isPidSupported(pid);

  /// STRICT support check for the #3416 precision PIDs (wideband φ, 0x66,
  /// 0x9D/0xA2, 0x51/0x52): true only when the support set is RESOLVED and
  /// the BITMAP claims [pid] (#3532 — probation never widens this; rare
  /// modern PIDs must never be blind-subscribed — an unresolved clone would
  /// flood the round-robin with ~20 NO DATA reads and starve the dynamics
  /// tier, seen as RPM cadence collapse in the #726 scheduler tests).
  @override
  bool isPidKnownSupported(int pid) =>
      _pids.isResolved && _pids.isPidInBitmap(pid);

  /// Direct view of the supported-PID set for tests and diagnostics.
  /// Returns an unmodifiable empty set when discovery hasn't run —
  /// callers that want "is this supported?" should use [isPidSupported]
  /// instead to respect the "unknown ⇒ allow" semantics.
  @visibleForTesting
  Set<int> get debugSupportedPids => _pids.debugSupportedPids;

  /// Test seam (#3416) — see [SupportedPidsResolver.debugSetSupportedPids].
  @visibleForTesting
  void debugSetSupportedPids(Set<int> pids) =>
      // Seam-to-seam delegation: both ends are @visibleForTesting.
      // ignore: invalid_use_of_visible_for_testing_member
      _pids.debugSetSupportedPids(pids);

  /// Read the odometer value in km.
  ///
  /// #3540 — the fallback chain (standard A6 → PID 31 proxy →
  /// manufacturer Mode 22 catalog) lives in [Obd2OdometerReader]; this
  /// stays the public API and hands it the send/connectivity primitives.
  /// Returns null when every layer fails, so callers can surface
  /// "odometer not readable for your car" instead of a zero.
  Future<double?> readOdometerKm({
    ReferenceVehicle? referenceVehicle,
  }) =>
      Obd2OdometerReader(
        send: _send,
        isConnected: () => _transport.isConnected,
      ).read(odometerPidStrategy: referenceVehicle?.odometerPidStrategy);

  /// Read current vehicle speed in km/h.
  Future<int?> readSpeedKmh() async {
    if (!_transport.isConnected) return null;

    try {
      final response = await _send(Elm327Protocol.vehicleSpeedCommand);
      final value = Elm327Protocol.parseVehicleSpeed(response);
      _pids.noteMode01Reply(Elm327Protocol.vehicleSpeedCommand, response,
          parsed: value != null); // #3532
      return value;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readSpeed failed'); // #2855
      return null;
    }
  }

  /// Ask the adapter which Mode 01 PIDs the vehicle supports (#811).
  ///
  /// Walks the standard supported-PIDs chain: `01 00` returns a
  /// bitmap for PIDs 01–20, and bit-32 of that bitmap is set iff PIDs
  /// 21–40 are also addressable — querying `01 20` in turn returns
  /// that range, and so on up to `01 C0`. We stop as soon as a
  /// bitmap's "next-range supported" flag is clear or the query
  /// returns NO DATA.
  ///
  /// Returns the union of every PID the car implements. Callers can
  /// consult it before issuing individual PID requests — on an older
  /// car where most PIDs miss, this saves a full second of Bluetooth
  /// round-trips per polling tick.
  ///
  /// Returns an empty set when the adapter isn't connected or the
  /// first bitmap can't be read — the caller should fall back to
  /// blind querying.
  ///
  /// Also populates the internal per-connection cache, so subsequent
  /// [isPidSupported] calls short-circuit queries for PIDs the car
  /// doesn't implement. One walk per trip-recording session is
  /// enough.
  Future<Set<int>> discoverSupportedPids() => _pids.discoverSupportedPids();

  /// Read current engine RPM.
  @override
  Future<double?> readRpm() async {
    if (!_transport.isConnected) return null;

    try {
      final response = await _send(Elm327Protocol.engineRpmCommand);
      final value = Elm327Protocol.parseEngineRpm(response);
      _pids.noteMode01Reply(Elm327Protocol.engineRpmCommand, response,
          parsed: value != null); // #3532
      return value;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readRpm failed'); // #2855
      return null;
    }
  }

  /// Read calculated engine load, 0–100 %. (#717)
  Future<double?> readEngineLoad() => _readDouble(
        Elm327Protocol.engineLoadCommand,
        Elm327Protocol.parseEngineLoad,
        label: 'engineLoad',
      );

  /// Read absolute throttle position, 0–100 %. (#717)
  Future<double?> readThrottlePercent() => _readDouble(
        Elm327Protocol.throttlePositionCommand,
        Elm327Protocol.parseThrottlePercent,
        label: 'throttle',
      );

  /// Read engine fuel rate in L/h (#717, #800, #3428).
  ///
  /// #3540 — the full fallback chain (mass PIDs 9D/A2 → direct 5E → MAF →
  /// speed-density) plus the mixture/trim refinements live in
  /// [Obd2FuelRateReader]; this stays the public API and hands the reader
  /// the narrow [Obd2FuelRateReads] port this service implements. See the
  /// reader's class doc for the precedence rules and error bars.
  Future<double?> readFuelRateLPerHour({
    VehicleProfile? vehicle,
    ReferenceVehicle? referenceVehicle,
  }) =>
      Obd2FuelRateReader(reads: this, collector: breadcrumbCollector)
          .read(vehicle: vehicle, referenceVehicle: referenceVehicle);

  /// One direct PID 0x5E read (#3540 — the [Obd2FuelRateReads] port's
  /// step-1 primitive; already post-trim on the ECU side).
  @override
  Future<double?> readDirectFuelRatePid5E() => _readDouble(
        Elm327Protocol.engineFuelRateCommand,
        Elm327Protocol.parseFuelRateLPerHour,
        label: 'fuelRate',
      );

  /// Stoichiometric AFR for petrol / gasoline (#800). Approximately
  /// 14.7 kg of air per kg of fuel at perfect combustion.
  ///
  /// Backwards-compat forwarder for [kPetrolAfr] from
  /// `fuel_rate_estimator.dart` — kept so pre-#563 call sites
  /// (`Obd2Service.petrolAfr`) compile unchanged.
  static const double petrolAfr = estimator.kPetrolAfr;

  /// Stoichiometric AFR for diesel (#800). Slightly leaner burn than
  /// petrol — ~14.5 kg of air per kg of diesel.
  ///
  /// Backwards-compat forwarder for [kDieselAfr].
  static const double dieselAfr = estimator.kDieselAfr;

  /// Petrol density in g/L at ~15 °C (#800). Published range
  /// 720–775 g/L; 740 is the legacy Tankstellen constant.
  ///
  /// Backwards-compat forwarder for [kPetrolDensityGPerL].
  static const double petrolDensityGPerL = estimator.kPetrolDensityGPerL;

  /// Diesel density in g/L at ~15 °C (#800). Denser than petrol at
  /// ~820–845 g/L; 832 is the EN 590 reference point.
  ///
  /// Backwards-compat forwarder for [kDieselDensityGPerL].
  static const double dieselDensityGPerL = estimator.kDieselDensityGPerL;

  /// Pure-math fuel-trim correction factor (#813).
  ///
  /// Backwards-compat forwarder for
  /// [estimator.applyFuelTrimCorrection] from `fuel_rate_estimator.dart`.
  /// New call sites should import the top-level function directly.
  static double applyFuelTrimCorrection(
    double raw, {
    required double stft,
    required double ltft,
    double? stftBank2,
    double? ltftBank2,
  }) =>
      estimator.applyFuelTrimCorrection(
        raw,
        stft: stft,
        ltft: ltft,
        stftBank2: stftBank2,
        ltftBank2: ltftBank2,
      );

  /// Pure-math speed-density fuel-rate estimator (#800).
  ///
  /// Backwards-compat forwarder for
  /// [estimator.estimateFuelRateLPerHourFromMap] from
  /// `fuel_rate_estimator.dart`. New call sites should import the
  /// top-level function directly.
  static double? estimateFuelRateLPerHourFromMap({
    required double mapKpa,
    required double iatCelsius,
    required double rpm,
    required int engineDisplacementCc,
    required double volumetricEfficiency,
    double afr = estimator.kPetrolAfr,
    double fuelDensityGPerL = estimator.kPetrolDensityGPerL,
    List<EtaVCurvePoint> etaVCurve = const [],
    double? baroKpa,
    double? phi,
  }) =>
      estimator.estimateFuelRateLPerHourFromMap(
        mapKpa: mapKpa,
        iatCelsius: iatCelsius,
        rpm: rpm,
        engineDisplacementCc: engineDisplacementCc,
        volumetricEfficiency: volumetricEfficiency,
        afr: afr,
        fuelDensityGPerL: fuelDensityGPerL,
        etaVCurve: etaVCurve,
        baroKpa: baroKpa,
        phi: phi,
      );

  /// Read mass air flow in g/s. (#717)
  @override
  Future<double?> readMafGramsPerSecond() => _readDouble(
        Elm327Protocol.mafCommand,
        Elm327Protocol.parseMafGramsPerSecond,
        label: 'maf',
      );

  /// Read intake manifold absolute pressure (kPa). (#800)
  @override
  Future<double?> readManifoldPressureKpa() => _readDouble(
        Elm327Protocol.intakeManifoldPressureCommand,
        Elm327Protocol.parseManifoldPressureKpa,
        label: 'manifoldPressure',
      );

  /// Read intake air temperature (°C). (#800)
  @override
  Future<double?> readIntakeAirTempCelsius() => _readDouble(
        Elm327Protocol.intakeAirTempCommand,
        Elm327Protocol.parseIntakeAirTempCelsius,
        label: 'intakeAirTemp',
      );

  /// Read absolute barometric pressure (kPa) via Mode 01 PID 0x33
  /// (#2456). Feeds the speed-density air-density correction so altitude
  /// / weather scale the air charge. Returns null when unsupported.
  @override
  Future<double?> readBaroPressureKpa() => _readDouble(
        Elm327Protocol.baroPressureCommand,
        Elm327Protocol.parseBaroPressureKpa,
        label: 'baroPressure',
      );

  /// Read the commanded fuel–air equivalence ratio φ via Mode 01 PID
  /// 0x44 (#2456; SAE convention verified #3426: φ > 1 rich, φ < 1
  /// lean). φ ≈ 1.0 at stoich; replaces the assumed stoich AFR in the
  /// MAF / speed-density fuel math via `effectiveAfrForPhi`. Returns
  /// null when unsupported.
  @override
  Future<double?> readCommandedEquivalenceRatio() => _readDouble(
        Elm327Protocol.commandedEquivalenceRatioCommand,
        Elm327Protocol.parseCommandedEquivalenceRatio,
        label: 'commandedEquivalenceRatio',
      );

  /// Read total MAF from the dual-sensor Mode 01 PID 0x66 (#3428).
  /// Preferred over the legacy PID 0x10 when supported. Null when
  /// unsupported / NO DATA.
  @override
  Future<double?> readMafSensorGramsPerSecond() => _readDouble(
        Elm327PrecisionPids.mafSensorCommand,
        Elm327PrecisionPids.parseMafSensorGramsPerSecond,
        label: 'mafSensor',
      );

  /// Read the direct engine fuel rate in g/s via Mode 01 PID 0x9D
  /// (#3428) — the top-precision mass-based branch (engine channel A/B
  /// only; the C/D vehicle channel is ignored, see the parser).
  @override
  Future<double?> readEngineFuelRateGramsPerSecond() => _readDouble(
        Elm327PrecisionPids.engineFuelRateGramsCommand,
        Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond,
        label: 'engineFuelRateGrams',
      );

  /// Read the cylinder fuel rate in mg/stroke via Mode 01 PID 0xA2
  /// (#3428). Needs RPM + cylinder count to become a mass flow.
  @override
  Future<double?> readCylinderFuelRateMgPerStroke() => _readDouble(
        Elm327PrecisionPids.cylinderFuelRateCommand,
        Elm327PrecisionPids.parseCylinderFuelRateMgPerStroke,
        label: 'cylinderFuelRate',
      );

  /// Read the measured ethanol fuel percentage via Mode 01 PID 0x52
  /// (#3429). Drives the dynamic petrol↔E85 AFR/density blend.
  @override
  Future<double?> readEthanolPercent() => _readDouble(
        Elm327PrecisionPids.ethanolPercentCommand,
        Elm327PrecisionPids.parseEthanolPercent,
        label: 'ethanolPercent',
      );

  /// Read one MEASURED wideband equivalence ratio φ (#3427): the first
  /// SUPPORTED sensor in bank-1-sensor-1-first order (0x24 / 0x34 lead
  /// their families). At most one Bluetooth round-trip — only the first
  /// supported PID is read; null when no wideband PID is supported or
  /// the read returned NO DATA.
  @override
  Future<double?> readMeasuredPhi() async {
    for (final pid in Elm327PrecisionPids.allWidebandPids) {
      if (!isPidKnownSupported(pid)) continue;
      return _readDouble(
        Elm327PrecisionPids.widebandCommand(pid),
        (raw) => Elm327PrecisionPids.parseEquivalenceRatioPhi(raw, pid),
        label: 'measuredPhi',
      );
    }
    return null;
  }

  /// Read short-term fuel trim bank 1 (%) (#813). Fast-feedback loop
  /// correction; the ECU adjusts this constantly to hit stoich.
  @override
  Future<double?> readShortTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.shortTermFuelTrimCommand,
        Elm327Protocol.parseShortTermFuelTrim,
        label: 'shortTermFuelTrim',
      );

  /// Read long-term fuel trim bank 1 (%) (#813). Slow-drifting
  /// correction that captures persistent offsets — altitude, air
  /// filter state, injector wear.
  @override
  Future<double?> readLongTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.longTermFuelTrimCommand,
        Elm327Protocol.parseLongTermFuelTrim,
        label: 'longTermFuelTrim',
      );

  /// Read short-term fuel trim bank 2 (%) via Mode 01 PID 0x08 (#2458).
  /// Only dual-bank (V / boxer) engines answer; inline engines return
  /// null and the correction stays on bank 1 alone.
  @override
  Future<double?> readShortTermFuelTrimBank2Percent() => _readDouble(
        Elm327Protocol.shortTermFuelTrimBank2Command,
        Elm327Protocol.parseShortTermFuelTrimBank2,
        label: 'shortTermFuelTrimBank2',
      );

  /// Read long-term fuel trim bank 2 (%) via Mode 01 PID 0x09 (#2458).
  /// Same dual-bank semantics as [readShortTermFuelTrimBank2Percent].
  @override
  Future<double?> readLongTermFuelTrimBank2Percent() => _readDouble(
        Elm327Protocol.longTermFuelTrimBank2Command,
        Elm327Protocol.parseLongTermFuelTrimBank2,
        label: 'longTermFuelTrimBank2',
      );

  /// Read absolute load value (%) via Mode 01 PID 0x43 (#2458). Exceeds
  /// 100 % on boosted engines under positive manifold pressure — a clean
  /// high-load proxy. Returns null when unsupported.
  Future<double?> readAbsoluteLoadPercent() => _readDouble(
        Elm327Protocol.absoluteLoadCommand,
        Elm327Protocol.parseAbsoluteLoad,
        label: 'absoluteLoad',
      );

  /// Read fuel tank level, 0–100 %. (#717)
  Future<double?> readFuelLevelPercent() => _readDouble(
        Elm327Protocol.fuelTankLevelCommand,
        Elm327Protocol.parseFuelLevelPercent,
        label: 'fuelLevel',
      );

  /// Read fuel type via Mode 01 PID 0x51 (#1399). Returns one of the
  /// project's `preferredFuelType` enum keys ("petrol", "diesel",
  /// "lpg", "cng", "electric") or null when:
  ///   * the adapter isn't connected,
  ///   * the ECU returned NO DATA (PID unsupported),
  ///   * the response carried a reserved / unknown fuel-type code.
  ///
  /// Used during the VIN-driven adapter-pair auto-population flow as
  /// the highest-priority signal — when this method returns a value,
  /// it overrides both the offline WMI decoder and the online vPIC
  /// `Fuel Type - Primary` field because PID 0x51 reports what the ECU
  /// is actually configured for at runtime.
  Future<String?> readFuelType() async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _send(Elm327Protocol.fuelTypeCommand);
      return Elm327Protocol.parseFuelType(response);
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 readFuelType failed'); // #2855
      return null;
    }
  }

  /// Read the Vehicle Identification Number via Mode 09 PID 02 (#1399).
  ///
  /// Public wrapper around the same command path used internally by
  /// [_resolveVehicleCacheKey] (#811). Returns the parsed 17-character
  /// VIN, or null when the adapter isn't connected, the ECU returned
  /// NO DATA (most pre-2005 vehicles), or [Elm327Protocol.parseVin]
  /// could not extract 17 valid VIN characters from the response.
  ///
  /// The ELM327 typically auto-handles the multi-frame ISO-15765-2
  /// response — [Elm327Protocol.parseVin] strips the per-frame
  /// `49 02 NN` headers + padding and returns the trailing 17 ASCII
  /// chars.
  ///
  /// Errors are swallowed — every failure path returns null. The
  /// caller surfaces "couldn't read VIN" UX based on the null result;
  /// stack traces stay in the debug log via [debugPrint].
  Future<String?> readVin() async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _send(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(response);
      if (vin == null || vin.isEmpty) return null;
      return vin;
    } catch (e, st) {
      // #2763 — flaky readVin is expected: breadcrumb, not ERROR (see helper).
      recordObd2ReadFailure(e, st, where: 'OBD2 readVin');
      return null;
    }
  }

  /// Open a passive CAN-frame stream filtered to the PSA
  /// instrument-cluster broadcast frame `0x0E6` (#1418).
  ///
  /// #3540 — the listen-mode wiring (ATCRA/STMA/STMP, line parsing,
  /// broadcast-controller lifecycle) lives in `obd2_can_frame_stream.dart`;
  /// this stays the public API. Pre-conditions and non-goals are documented
  /// on [psaCanFrameStream].
  Stream<({int id, List<int> payload})> canFrameStream() =>
      psaCanFrameStream(_transport);

  /// Ask the underlying BLE link for high throughput while actively
  /// polling PIDs (#2261 concern 4) — high connection priority + a
  /// best-effort MTU bump. No-op when the transport / channel doesn't
  /// expose tuning (Classic SPP, fakes). Best-effort throughout.
  Future<void> tuneLinkForRecording() async {
    final t = _transport;
    if (t is BluetoothObd2Transport) await t.tuneForRecording();
  }

  /// Drop the BLE link to balanced priority when only the 1 Hz
  /// auto-record movement stream is live (#2261 concern 4).
  Future<void> tuneLinkForBackground() async {
    final t = _transport;
    if (t is BluetoothObd2Transport) await t.tuneForBackground();
  }

  /// Run the deferred multi-frame ISO 15765 capability probe (#2261
  /// concern 6) at most once per connect, reconciling [capability] down
  /// if the adapter can't actually route a multi-frame `0902` request.
  ///
  /// This is the work that #1614 used to do synchronously inside
  /// [connect]; it is now pulled OFF the start critical path so a fresh
  /// connect returns without waiting up to 1.5 s for the probe. The
  /// recorder calls this lazily after the first samples — by then the
  /// trip is already capturing standard PIDs, and the probe (which can
  /// only LOWER the tier) tightens OEM-PID gating a moment later.
  ///
  /// A no-op when the claimed tier is already standardOnly (nothing to
  /// downgrade) or when it has already run this connect. Never throws.
  Future<void> ensureCapabilityReconciled() async {
    if (_capabilityReconciled) return;
    _capabilityReconciled = true;
    if (_claimedCapability == Obd2AdapterCapability.standardOnly) return;
    try {
      final probe = await probeMultiFrameCapability(_transport.sendCommand);
      _capability = reconcileCapabilityWithProbe(_claimedCapability, probe);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'OBD2 deferred capability probe failed',
      }));
    }
  }

  /// Close the transport connection. Safe to call multiple times.
  Future<void> disconnect() async {
    // #3528 — stop the session FIRST: its keepalive must not race the
    // teardown, and a deliberate close is not a session death.
    _session.stop();
    // #3422 — wedge PREVENTION: ATPC parks the adapter's protocol session
    // before a DELIBERATE teardown (skipped when the link already dropped).
    await sendProtocolCloseBeforeTeardown(_transport);
    await _transport.disconnect();
  }

  Future<double?> _readDouble(
    String command,
    double? Function(String raw) parser, {
    required String label,
  }) async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _send(command);
      final value = parser(response);
      // #3532 — feed the probation state: a real NO DATA streak parks the
      // PID; any parsed value clears it. Transport faults (the catch
      // below) are link weather and deliberately count for nothing.
      _pids.noteMode01Reply(command, response, parsed: value != null);
      return value;
    } catch (e, st) {
      recordObd2ReadFailure(e, st, where: 'OBD2 read $label failed'); // #2855
      return null;
    }
  }

  /// Send [command] over the transport and apply the active adapter's
  /// [Elm327Adapter.preParse] hook before handing the string off to a
  /// parser (#1330). Phase 1: [GenericElm327Adapter.preParse] is the
  /// identity function so behaviour matches today's direct
  /// `_transport.sendCommand` exactly. Adapter-specific subclasses in
  /// later phases can strip stray prompts / echoes here.
  Future<String> _send(String command) async {
    // #3528 — through the session ladder when one is attached.
    final raw = await _rawSend(command);
    return _adapter.preParse(raw);
  }

  /// #3037 — send [command] (the first `0100` probe) with the GENEROUS
  /// protocol-search read window ([kObd2ProtocolSearchTimeout], ~15 s) when
  /// the transport supports a per-command timeout override
  /// ([Obd2ProtocolSearchTransport]); otherwise fall back to the plain
  /// [_send] (whose own first-command class still applies). This is the
  /// SINGLE long read that lets the ELM327 auto-search resolve to `41 00`
  /// without re-sending mid-search (which would restart the search) — the
  /// root fix for the false engine-off on a slow link. The adapter
  /// `preParse` hook is applied to the raw reply exactly as in [_send].
  Future<String> _sendWithProtocolSearchWindow(String command) async {
    final transport = _transport;
    final raw = transport is Obd2ProtocolSearchTransport
        ? await (transport as Obd2ProtocolSearchTransport)
            .sendCommandWithReadTimeout(command, kObd2ProtocolSearchTimeout)
        : await transport.sendCommand(command);
    return _adapter.preParse(raw);
  }
}
