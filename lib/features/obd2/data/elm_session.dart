// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'elm327_commands.dart';
import 'obd2_response_class.dart';
import 'obd2_transport.dart';

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
    this.staleAfter = const Duration(seconds: 15),
    this.keepaliveIdle = const Duration(seconds: 7),
    this.deadAfterConsecutiveTimeouts = 3,
    Duration watchdogTick = const Duration(seconds: 2, milliseconds: 500),
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
  int _consecutiveTimeouts = 0;
  int _consecutiveGarbage = 0;
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
    _consecutiveTimeouts = 0;
    // AT/ST replies are conversational ('OK', '12.4V') — the OBD
    // classifier reads them as garbage, so they must bypass the ladder
    // entirely or every keepalive reply would feed the ATWS trigger.
    if (_isAtCommand(command)) {
      _consecutiveGarbage = 0;
      return reply;
    }
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
    _setState(ElmSessionState.recovering);
    try {
      await _transport.sendCommand(recoveryCommand);
      _noteAlive();
    } on Object catch (e) {
      debugPrint('ElmSession: recovery "$recoveryCommand" failed: $e');
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
