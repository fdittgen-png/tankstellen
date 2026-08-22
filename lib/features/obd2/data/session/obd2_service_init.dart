// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_service.dart';

/// Connect-time init support extracted from [Obd2Service] as a `part`
/// mixin so it keeps private-member access while `obd2_service.dart`
/// stays under the #1680 file-length cap (sanctioned #3760
/// decomposition — move-only, behaviour preserved): the connect-time
/// send retry, the bounded wake window, the negotiated-protocol cache,
/// the bus-probe signals and the in-session protocol recovery.
mixin _Obd2ServiceInit on _Obd2ServiceLink {
  /// Persistent negotiated-protocol cache (#2261 concern 3) — the class
  /// owns the field; the mixin reaches it through this getter.
  NegotiatedProtocolCache? get _protocolCache;

  /// Lookup key for [_protocolCache] — owned by the class.
  String? get _protocolCacheKey;

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
      await Future<void>.delayed(Obd2Service.connectRetryDelay);
      return inner(command);
    }
  }

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
        .clamp(0, Obd2Service.wakeSettleCap.inMicroseconds);
    final settle = Duration(
      microseconds: (cappedSettleUs * Obd2Service.wakeSettleScale).round(),
    );
    final nudges = policy.maxNudges.clamp(0, Obd2Service.maxNudgeCap);

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

  /// #3575 — in-session vehicle-protocol recovery for the ELM
  /// UNABLE-TO-CONNECT livelock. When the adapter connected before the
  /// ignition was on, the first auto protocol search fails and the chip
  /// answers every later command instantly with UNABLE TO CONNECT /
  /// STOPPED — and the polling cadence keeps interrupting any restarted
  /// search, so it can never converge. Recovery: reset to the auto
  /// search (`ATSP0`), clear the per-connection PID state, and re-run
  /// the resilient first-`0100` discovery (which owns the #3035/#3037
  /// search window) with NO other traffic in flight — the caller must
  /// pause its poll scheduler around this call. On an answering bus the
  /// negotiated protocol is re-read and re-cached (#2261).
  ///
  /// Returns true when the bus answered (protocol re-established);
  /// false on a still-silent bus or any transport fault. Never throws.
  Future<bool> recoverVehicleProtocol() async {
    if (!_transport.isConnected) return false;
    try {
      await _send(Elm327Protocol.autoProtocolCommand);
      _pids.resetForNewConnection();
      await discoverSupportedPids();
      final answered = busProbe == Obd2BusProbeResult.answered;
      if (answered) {
        await _resolveAndCacheProtocol(warmConnect: false);
      }
      BreadcrumbCollector.add(
        'OBD2 protocol recovery (#3575)',
        detail: answered ? 'bus answered — protocol re-established' : 'bus still silent',
      );
      return answered;
    } catch (e, st) {
      // An expected link condition mid-recovery (adapter asleep, socket
      // died) — breadcrumb, not an ERROR trace; the scheduler episode
      // will re-signal if the link is actually alive.
      BreadcrumbCollector.add(
        'OBD2 protocol recovery failed (#3575)',
        detail: '${e.runtimeType}',
      );
      debugPrint('Obd2Service.recoverVehicleProtocol: $e\n$st');
      return false;
    }
  }
}
