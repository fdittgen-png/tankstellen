// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'elm327_commands.dart';
import 'obd2_response_class.dart';
import '../transport/obd2_transport.dart';

/// Session states of one ELM327 link (#3528, Epic #3527).
///
/// Mirrors the state machines of the mature implementations (AndrOBD's
/// `ElmProt.STAT`, ELMduino's `nb_query_state`): the session is a pure
/// protocol layer — it never opens or closes sockets, and it never
/// reconnects. It reports trouble UPWARD (rule 2 of the #3527 research:
/// one reconnect owner, and it is not this class).
enum ElmSessionState {
  /// No link, or the session was disposed.
  idle,

  /// The init sequence (ATZ → ATE0 → … → ATSP0) is running.
  initializing,

  /// Init completed; commands flow.
  ready,

  /// A recoverable error class was seen and an ELM-level recovery
  /// (ATWS warm start / ATPC protocol close) is in progress. Commands
  /// still complete — recovery is transparent to callers.
  recovering,

  /// The session declared the link dead (consecutive timeouts or
  /// staleness). Only the link supervisor can act on this — the session
  /// itself stops its timers and waits to be disposed.
  dead,
}

/// Why a session declared itself [ElmSessionState.dead] (#3528). Stable,
/// low-cardinality tags for the supervisor's trace.
enum ElmSessionDeathCause { consecutiveTimeouts, stale, transportError }

/// One ELM327 protocol session over an [Obd2Transport] (#3528).
///
/// Owns exactly three responsibilities, per the #3527 consensus
/// architecture (AndrOBD / python-OBD / ELMduino):
///
///  1. **Init** — the ATZ→ATE0→ATL0→ATS0→ATH1→ATAT1→ATSP0 sequence with
///     clone tolerance: a `?` reply to an OPTIONAL command is non-fatal;
///     only echo-off and protocol-set hard-fail (research rule 12).
///  2. **Error-classification ladder** (rule 6 — classify before you
///     kill): `NO DATA` is a LIVE link (the ECU answered); repeated
///     `BUFFER FULL`/garbage → `ATWS` warm start; `CAN ERROR` → `ATPC`
///     + re-`ATSP`; only consecutive TIMEOUTS (total silence) declare
///     the link dead for the supervisor to recycle.
///  3. **Liveness** — a staleness watchdog (rule 10: `ready` but no
///     successful reply for [staleAfter] → dead, catching zombie
///     sockets the read loop never reports) and an `ATRV` keepalive
///     (rule 11: cheap adapters auto-sleep when the link idles).
///
/// The session NEVER dials, closes, or retries the socket. Death is
/// reported once via [states] / [deathCause] and the session goes
/// permanently quiet — the supervisor recycles the socket and builds a
/// **fresh** session (rule 9: reconnect ≠ resume; full re-init).
class ElmSession {
  ElmSession(
    this._transport, {
    List<String>? initSequence,
    // #3756 — reliability-first liveness cadence: the previous
    // 7 s-idle keepalive on a 2.5 s tick allowed up to ~9.5 s of link
    // silence, losing the race against cheap adapters' auto-sleep
    // timers; every sleep-kill then fed the #3603 flap counter. One
    // tiny ATRV per ~4 s idle is negligible traffic, and the tighter
    // stale bound turns a dead link around faster.
    this.staleAfter = const Duration(seconds: 12),
    this.keepaliveIdle = const Duration(seconds: 4),
    this.deadAfterConsecutiveTimeouts = 3,
    Duration watchdogTick = const Duration(seconds: 1, milliseconds: 500),
    DateTime Function()? now,
  })  : _initSequence = initSequence ?? defaultInitSequence,
        _watchdogTick = watchdogTick,
        _now = now ?? DateTime.now;

  /// The standard init burst — [Elm327Commands.initCommands] (ATZ →
  /// ATE0 → ATL0 → ATH0 → ATSP0 → ATAT1). Reset first, echo off
  /// immediately after so every later reply parses cleanly; ATAT1 last
  /// per the #1918 rationale on the constant.
  static const List<String> defaultInitSequence = Elm327Commands.initCommands;

  /// Commands whose failure aborts [initialize] (research rule 12): a
  /// clone that can't turn echo off breaks all parsing; one that can't
  /// set a protocol can't talk to the ECU. Everything else is optional.
  static const Set<String> _hardInitCommands = {
    Elm327Commands.echoOffCommand,
    Elm327Commands.autoProtocolCommand,
  };

  final Obd2Transport _transport;
  final List<String> _initSequence;
  final Duration staleAfter;
  final Duration keepaliveIdle;
  final int deadAfterConsecutiveTimeouts;
  final Duration _watchdogTick;
  final DateTime Function() _now;

  final StreamController<ElmSessionState> _states =
      StreamController<ElmSessionState>.broadcast();

  ElmSessionState _state = ElmSessionState.idle;
  ElmSessionDeathCause? _deathCause;
  Timer? _watchdog;
  DateTime? _lastAliveAt;
  DateTime? _longReadHoldUntil;
  int _consecutiveTimeouts = 0;
  int _consecutiveGarbage = 0;
  int _successfulObdSends = 0;

  /// #3756 — completed non-AT commands over this session's lifetime.
  int get successfulObdSends => _successfulObdSends;
  bool _recoveryInFlight = false;
  bool _keepaliveInFlight = false;
  bool _disposed = false;

  /// Current state. Transitions are also emitted on [states].
  ElmSessionState get state => _state;

  /// Why the session died — set exactly once, when [state] becomes
  /// [ElmSessionState.dead].
  ElmSessionDeathCause? get deathCause => _deathCause;

  /// State transitions, for the link supervisor (a dead event is its
  /// signal to recycle the socket) and diagnostics.
  Stream<ElmSessionState> get states => _states.stream;

  /// Instant of the last reply that proved the link alive (any framed
  /// reply — including `NO DATA`, which means the ECU answered).
  DateTime? get lastAliveAt => _lastAliveAt;

  /// #3779 (Epic #3775) — declare a LONG read in flight for [window]:
  /// the ELM protocol-search `0100` is a single deliberately-long read
  /// (up to ~15 s) that BYPASSES [send] (a re-send would restart the
  /// search), so it can never refresh the liveness clock — and #3757's
  /// 12 s [staleAfter] then declared the session dead mid-search,
  /// tearing down the very socket the search was running on. While the
  /// hold is armed the watchdog neither stale-kills nor keepalives
  /// (nothing can land on the half-duplex queue anyway). Cleared by the
  /// next reply ([noteExternalReply] / any [send]) or by expiry — an
  /// expired hold restarts the staleness window instead of instantly
  /// killing a link whose search just resolved.
  void holdLivenessFor(Duration window) {
    if (_disposed || _state == ElmSessionState.dead) return;
    _longReadHoldUntil = _now().add(window);
  }

  /// #3779 — a reply arrived on a path that bypasses [send] (the
  /// protocol-search long read): clear the hold and refresh liveness.
  void noteExternalReply() {
    _longReadHoldUntil = null;
    _consecutiveTimeouts = 0;
    _noteAlive();
  }

  /// Adopt a link the caller ALREADY initialized (#3528 integration —
  /// `Obd2Service.connect` runs a richer init than [initialize]: wake
  /// policy, warm-protocol replay, handshake tracing, per-command
  /// transient retry). Skips the init burst and goes straight to
  /// [ElmSessionState.ready] with the ladder + liveness watchdog armed.
  void adoptReady() {
    if (_disposed || _state == ElmSessionState.dead) return;
    _consecutiveTimeouts = 0;
    _consecutiveGarbage = 0;
    _noteAlive();
    _setState(ElmSessionState.ready);
    _armWatchdog();
  }

  /// Run the init burst. Throws on a hard-command failure (echo-off /
  /// protocol-set) or a transport error; `?` replies to optional
  /// commands are tolerated per research rule 12.
  Future<void> initialize() async {
    _setState(ElmSessionState.initializing);
    for (final command in _initSequence) {
      final String reply;
      try {
        reply = await _transport.sendCommand(command);
      } on Object {
        _declareDead(ElmSessionDeathCause.transportError);
        rethrow;
      }
      _noteAlive();
      // AT replies ('OK', a version banner, '12.4V') are conversational,
      // not OBD frames — the shared classifier has no vocabulary for
      // them. The ELM's explicit command-error marker is '?'; that is
      // the ONLY init failure signal (research rule 12).
      final failed = reply.contains('?');
      if (failed && _hardInitCommands.contains(command)) {
        _declareDead(ElmSessionDeathCause.transportError);
        throw StateError(
          'ELM327 init failed: "$command" answered "$reply"',
        );
      }
    }
    _consecutiveTimeouts = 0;
    _consecutiveGarbage = 0;
    _setState(ElmSessionState.ready);
    _armWatchdog();
  }

  /// Send [command] through the classification ladder. Returns the raw
  /// reply exactly like [Obd2Transport.sendCommand]; recoverable error
  /// classes trigger transparent ELM-level recovery, and only repeated
  /// total silence kills the session.
  Future<String> send(String command) async {
    if (_state == ElmSessionState.dead || _disposed) {
      throw StateError('ElmSession is dead');
    }
    final String reply;
    try {
      reply = await _transport.sendCommand(command);
    } on TimeoutException {
      _consecutiveTimeouts++;
      if (_consecutiveTimeouts >= deadAfterConsecutiveTimeouts &&
          _state != ElmSessionState.dead) {
        _declareDead(ElmSessionDeathCause.consecutiveTimeouts);
      }
      rethrow;
    }
    // Any framed reply proves the link + adapter alive — including error
    // vocabulary. Timeouts are the only silence.
    _noteAlive();
    _longReadHoldUntil = null; // #3779 — live traffic ends any hold
    _consecutiveTimeouts = 0;
    // AT/ST replies are conversational ('OK', '12.4V') — the OBD
    // classifier reads them as garbage, so they must bypass the ladder
    // entirely or every keepalive reply would feed the ATWS trigger.
    if (_isAtCommand(command)) {
      _consecutiveGarbage = 0;
      return reply;
    }
    // #3756 — count completed OBD (non-AT) commands: the supervisor
    // reads this at drop time to tell a trafficked link (real proof it
    // worked) from the zero-traffic corpse-adopt flap shape. Keepalive
    // ATRVs are AT commands and deliberately never count.
    _successfulObdSends++;
    switch (classifyObd2Response(reply)) {
      case ResponseClass.ok:
      case ResponseClass.noData:
        // NO DATA = the ECU answered but had nothing — a LIVE link
        // (research rule 6). Never recovery fuel.
        _consecutiveGarbage = 0;
      case ResponseClass.bufferFull:
      case ResponseClass.garbage:
        _consecutiveGarbage++;
        if (_consecutiveGarbage >= 2) {
          _consecutiveGarbage = 0;
          unawaited(_recover(Elm327Commands.warmStartCommand));
        }
      case ResponseClass.canError:
        _consecutiveGarbage = 0;
        unawaited(_recover(Elm327Commands.protocolCloseCommand));
      case ResponseClass.unrecognized:
      case ResponseClass.timeout:
        // `?` / STOPPED / UNABLE TO CONNECT — the adapter is alive and
        // said so; the caller interprets the reply. Nothing to recover.
        _consecutiveGarbage = 0;
    }
    return reply;
  }

  /// ELM-level recovery (research rule 6): [recoveryCommand] is `ATWS`
  /// (warm start — garbage/buffer trouble) or `ATPC` (protocol close —
  /// CAN/bus trouble; the next OBD request re-opens via the sticky
  /// ATSP). Transparent to callers; single-flight; a recovery failure
  /// escalates to dead via the normal timeout path of a later command.
  Future<void> _recover(String recoveryCommand) async {
    if (_recoveryInFlight ||
        _state == ElmSessionState.dead ||
        _disposed) {
      return;
    }
    _recoveryInFlight = true;
    // #3534 — the classify→recover rung of the drop timeline: names which
    // ladder command fired (ATWS = garbage, ATPC = bus error) so a field
    // trace shows WHY the session recovered (or went on to die).
    BreadcrumbCollector.add('ELM recovery', detail: recoveryCommand);
    _setState(ElmSessionState.recovering);
    try {
      await _transport.sendCommand(recoveryCommand);
      _noteAlive();
    } on Object catch (e, st) {
      debugPrint('ElmSession: recovery "$recoveryCommand" failed: $e\n$st');
    } finally {
      _recoveryInFlight = false;
      if (_state == ElmSessionState.recovering) {
        _setState(ElmSessionState.ready);
      }
    }
  }

  /// Liveness timer (research rules 10 + 11): staleness declares the
  /// link dead even though the socket "looks" open; keepalive stops a
  /// cheap adapter from auto-sleeping when nothing polls.
  void _armWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogTick, (_) {
      if (_state != ElmSessionState.ready &&
          _state != ElmSessionState.recovering) {
        return;
      }
      // #3779 — a declared long read (protocol search) is in flight:
      // its silence is legitimate, so neither staleness nor keepalive
      // may fire. On expiry the staleness window restarts from now —
      // the search path owns its own timeout verdict, and an instant
      // stale-kill here would punish a search that resolved at second
      // 13 with a death at second 13.1.
      final hold = _longReadHoldUntil;
      if (hold != null) {
        if (_now().isBefore(hold)) return;
        _longReadHoldUntil = null;
        _noteAlive();
      }
      final last = _lastAliveAt;
      if (last == null) return;
      final idle = _now().difference(last);
      if (idle >= staleAfter) {
        _declareDead(ElmSessionDeathCause.stale);
        return;
      }
      if (idle >= keepaliveIdle && !_keepaliveInFlight) {
        _keepaliveInFlight = true;
        // ATRV answers instantly from the adapter itself (no CAN
        // traffic) — the canonical keepalive. Its reply refreshes
        // [_lastAliveAt] via the ladder; its timeout feeds the same
        // consecutive-timeout death counter as any command.
        unawaited(send(Elm327Commands.readVoltageCommand)
            .catchError((Object _) => '')
            .whenComplete(() => _keepaliveInFlight = false));
      }
    });
  }

  /// Whether [command] is an AT/ST configuration command (vs an OBD
  /// request). Mirrors the transport's early-init detection.
  static bool _isAtCommand(String command) {
    final c = command.trim().toUpperCase();
    return c.startsWith('AT') || c.startsWith('ST');
  }

  void _noteAlive() => _lastAliveAt = _now();

  void _declareDead(ElmSessionDeathCause cause) {
    if (_state == ElmSessionState.dead) return;
    _deathCause = cause;
    _watchdog?.cancel();
    _watchdog = null;
    _setState(ElmSessionState.dead);
  }

  void _setState(ElmSessionState next) {
    if (_disposed || _state == next) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  /// Stop timers and close the state stream. Idempotent. Never touches
  /// the transport — socket lifecycle belongs to the supervisor.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _watchdog?.cancel();
    _watchdog = null;
    _state = ElmSessionState.idle;
    unawaited(_states.close());
  }
}
