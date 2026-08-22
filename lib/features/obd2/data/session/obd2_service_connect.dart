// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_service.dart';

/// The connect / disconnect lifecycle extracted from [Obd2Service] as a
/// `part` mixin so it keeps private-member access while
/// `obd2_service.dart` stays under the #1680 file-length cap (sanctioned
/// #3760 decomposition — move-only, behaviour preserved): the adapter
/// init handshake, the firmware/capability probe and the teardown.
mixin _Obd2ServiceConnect on _Obd2ServiceInit {
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

  /// Whether [command] is a reset / wake command that needs a settle
  /// delay after it (#2261 concern 5) — ATZ (full reset) or ATWS (warm
  /// start). Every other AT echo / OBD request is serialised by the
  /// transport's prompt-wait and needs no extra sleep.
  static bool _isResetCommand(String command) {
    final c = command.trim().toUpperCase();
    return c == 'ATZ' || c == 'ATWS';
  }

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
}
