// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_service.dart';

/// #3915 (Epic #3914) — default bound on one [Obd2Service.probeLiveness]
/// round-trip. `ATRV` answers from the adapter itself (no bus traffic) in
/// tens of milliseconds; 1.5 s is generous for a slow clone and still far
/// below the 8 s post-rebind grace the field livelock burned per cycle.
const Duration kObd2LivenessProbeTimeout = Duration(milliseconds: 1500);

/// Link-side surface extracted from [Obd2Service] as a `part` mixin so it
/// keeps private-member access while `obd2_service.dart` stays under the
/// #1680 file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved): the protocol-session send funnel, the adapter
/// identity/capability fields, the supported-PID surface, and the BLE
/// link tuning hooks.
mixin _Obd2ServiceLink implements Obd2RawCommandPort, Obd2FuelRateReads {
  /// The transport backing this service — the class owns the field; the
  /// mixin chain reaches it through this library-private getter.
  Obd2Transport get _transport;

  /// The #811 supported-PID resolver — owned by the class constructor.
  SupportedPidsResolver get _pids;

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

  /// #3756 — completed non-AT commands of the current protocol session
  /// (the supervisor's trafficked-ready flap exemption reads this at
  /// drop time).
  int get sessionSuccessfulObdSends => _session.successfulObdSends;

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
  /// in vLinker / SmartOBD specialisations.
  Elm327Adapter _adapter = const GenericElm327Adapter();

  /// Adapter snapshot used during the most recent [connect]. Exposed
  /// for tests + diagnostics; production callers should use the typed
  /// read* methods rather than reaching for the adapter directly.
  @visibleForTesting
  Elm327Adapter get adapter => _adapter;

  /// What the bounded wake window observed on the most recent [connect]
  /// (#2268 concern 2). [WakeObservation.notRun] until a connect with an
  /// active (non-suppressed) [WakePolicy] runs the window. The connection
  /// service reads this after connect to update the per-MAC wake cache
  /// (#2268 concern 3). Never updated on a connect that didn't run the
  /// window, so a generic-adapter connect leaves it [notRun].
  WakeObservation wakeObservation = WakeObservation.notRun;

  /// `true` when the underlying [Obd2Transport] currently has an open
  /// connection to the vehicle's ELM327 adapter.
  ///
  /// #3915 — a FLAG, not liveness: a byte channel whose session was
  /// cleared by a write-time drop keeps this true while every command
  /// throws instantly. Anything that ADOPTS a service must prove it with
  /// [probeLiveness] instead of trusting this getter.
  bool get isConnected => _transport.isConnected;

  Future<bool>? _livenessProbe;

  /// #3915 — prove the link alive with ONE real round-trip: `ATRV`
  /// through the session ladder, bounded by [timeout]. `true` iff a
  /// reply arrived; `false` on a dead transport flag, an instant throw
  /// (the connected-but-mute corpse of the 2026-09-01 field trip) or
  /// silence past the bound. The probe swallows every fault into
  /// `false` — it is a verdict, not an I/O surface. Single-flight per
  /// instance: concurrent callers share the in-flight round-trip so a
  /// poke storm cannot queue a burst of ATRVs on the half-duplex link.
  Future<bool> probeLiveness(
      {Duration timeout = kObd2LivenessProbeTimeout}) {
    final inFlight = _livenessProbe;
    if (inFlight != null) return inFlight;
    final probe = _probeLivenessOnce(timeout)
        .whenComplete(() => _livenessProbe = null);
    _livenessProbe = probe;
    return probe;
  }

  Future<bool> _probeLivenessOnce(Duration timeout) async {
    if (!_transport.isConnected) return false;
    try {
      await _rawSend(Elm327Commands.readVoltageCommand).timeout(timeout);
      return true;
    } catch (e, st) {
      // An expected link condition (mute socket, adapter asleep) — the
      // caller's reaction (recycle through the owner) is the visible
      // outcome; a breadcrumb keeps the field export honest.
      BreadcrumbCollector.add(
        'OBD2 liveness probe failed (#3915)',
        detail: '${e.runtimeType} — connected flag but no reply',
      );
      debugPrint('Obd2Service.probeLiveness: $e\n$st');
      return false;
    }
  }

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
    // #3779 — this read bypasses the ElmSession (a re-send would restart
    // the ELM's auto-search), so it cannot refresh the liveness clock;
    // declare it so the watchdog holds for the window (+ a settle
    // margin) instead of stale-killing the socket mid-search (#3757 cut
    // staleAfter to 12 s while this window is 15 s).
    _session.holdLivenessFor(
        kObd2ProtocolSearchTimeout + const Duration(seconds: 2));
    final raw = transport is Obd2ProtocolSearchTransport
        ? await (transport as Obd2ProtocolSearchTransport)
            .sendCommandWithReadTimeout(command, kObd2ProtocolSearchTimeout)
        : await transport.sendCommand(command);
    _session.noteExternalReply();
    return _adapter.preParse(raw);
  }
}
