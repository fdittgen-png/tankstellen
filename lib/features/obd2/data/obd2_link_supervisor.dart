// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_service.dart';

/// The link states one OBD2 adapter can be in, as seen by the ONE
/// reconnect owner (#3529, Epic #3527).
enum Obd2LinkState {
  /// No adapter configured / nothing to supervise.
  idle,

  /// A user- or policy-initiated dial is in flight.
  connecting,

  /// A live, initialized service is available via
  /// [Obd2LinkSupervisor.service].
  ready,

  /// The link dropped and the supervisor is running its backoff loop.
  /// It NEVER gives up on its own — the loop runs until success, a user
  /// disconnect, or an engine-off classification (the #3527 rewrite
  /// deliberately has no `terminalFailed` dead-end; the old six
  /// dead-end states are what stranded the 2026-07-08 trip).
  reconnecting,

  /// The user asked to disconnect. Nothing auto-reconnects until the
  /// next explicit [Obd2LinkSupervisor.connect] (research rule 7: ONE
  /// flag distinguishes intent from drop, checked in one place).
  userDisconnected,

  /// The bus was classified silent (engine off, #3035). The backoff
  /// loop parks — dialing a sleeping car burns adapter and phone
  /// battery — until [Obd2LinkSupervisor.wake] (movement, app resume)
  /// or an explicit connect.
  engineOff,
}

/// How the supervisor obtains a live, initialized [Obd2Service]. The
/// closure encapsulates *how* to dial (direct-by-MAC, scan fallback,
/// cross-transport policy — owned by the connection service); the
/// supervisor owns *when*. Returns null for a clean "not found /
/// adapter not in range" miss; throws for a real fault. Both count as
/// a failed attempt.
typedef Obd2LinkDialer = Future<Obd2Service?> Function();

/// THE one reconnect owner (#3529, Epic #3527).
///
/// Consensus rule 2 of the #3527 research (AndrOBD's upward-only
/// `connectionLost()`, WheelLog's service-owned reconnect): transports
/// and sessions report drops UP; exactly one component — this one —
/// decides whether and when to dial. It replaces the forked authorities
/// that raced each other over the adapter's single RFCOMM channel since
/// #3020 (Obd2ReconnectController, AdapterReconnectScanner /
/// ReconnectConnector, the arbiter's drop routing, the wedge/flap
/// latches — deletion tracked by #3533).
///
/// Invariants:
///  * **Single flight** — at most one dial attempt exists at any time,
///    whatever mixture of drops, user taps, and backoff ticks fires.
///  * **One intent flag** — [userRequestedDisconnect] is the only thing
///    that distinguishes "the user closed the link" from "the link
///    died"; it is set/cleared in exactly two methods and checked at
///    exactly one gate ([_mayAutoDial]).
///  * **No dead ends** — the backoff loop (0.5 → 1 → 2 → 4 → 8 → …,
///    capped at [maxBackoff], with jitter) never self-terminates. The
///    only parked states are the two the USER or the ENGINE put it in.
///  * **Recycle, don't resume** — every attempt dials a fresh service
///    through [Obd2LinkDialer]; the dead one is torn down best-effort
///    first (research rules 8 + 9).
class Obd2LinkSupervisor {
  Obd2LinkSupervisor({
    required Obd2LinkDialer dial,
    Stream<Obd2LinkDropEvent>? drops,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
    Random? jitter,
  })  : _dial = dial,
        _jitter = jitter ?? Random() {
    _dropSubscription =
        (drops ?? Obd2LinkDropSignal.instance.drops).listen(_onDrop);
  }

  final Obd2LinkDialer _dial;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final Random _jitter;

  final ValueNotifier<Obd2LinkState> _state =
      ValueNotifier<Obd2LinkState>(Obd2LinkState.idle);
  final StreamController<Obd2LinkState> _states =
      StreamController<Obd2LinkState>.broadcast();

  StreamSubscription<Obd2LinkDropEvent>? _dropSubscription;
  Obd2Service? _service;
  Future<Obd2Service?>? _attemptInFlight;
  Timer? _backoffTimer;
  Duration _backoff = Duration.zero;
  bool _userRequestedDisconnect = false;
  bool _disposed = false;

  /// Current state, listenable for UI (status dot, banners).
  ValueListenable<Obd2LinkState> get state => _state;

  /// State transitions as a stream, for non-widget consumers (the trip
  /// layer's LinkState subscription, #3531).
  Stream<Obd2LinkState> get states => _states.stream;

  /// The live service while [state] is [Obd2LinkState.ready]; null
  /// otherwise.
  Obd2Service? get service =>
      _state.value == Obd2LinkState.ready ? _service : null;

  /// Research rule 7 — the ONE flag distinguishing user intent from a
  /// drop. Read-only outside; mutated only by [connect] / [disconnect].
  bool get userRequestedDisconnect => _userRequestedDisconnect;

  /// User/policy-initiated connect. Clears the disconnect intent, exits
  /// any parked state, and dials now. Joins the in-flight attempt if
  /// one exists (single flight). Returns the live service, or null when
  /// the dial missed — in which case the backoff loop is already armed
  /// and will keep trying.
  Future<Obd2Service?> connect() {
    if (_disposed) return Future<Obd2Service?>.value();
    _userRequestedDisconnect = false;
    _cancelBackoffTimer();
    return _attempt(userInitiated: true);
  }

  /// User-initiated disconnect: park the loop, tear the link down. No
  /// automatic dial happens until the next [connect].
  Future<void> disconnect() async {
    _userRequestedDisconnect = true;
    _cancelBackoffTimer();
    final dead = _service;
    _service = null;
    _setState(Obd2LinkState.userDisconnected);
    if (dead != null) {
      try {
        await dead.disconnect();
      } catch (e, st) {
        // Best-effort — the intent is recorded either way; a throwing
        // teardown of a half-dead link must not surface to the user.
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'Obd2LinkSupervisor.disconnect'}));
      }
    }
  }

  /// A drop or session death reported from below (channels via
  /// [Obd2LinkDropSignal], the ElmSession dead event via the provider
  /// wiring). Starts the reconnect loop unless the user or the engine
  /// parked the supervisor.
  void notifyDrop(String reason) {
    if (_disposed) return;
    _service = null;
    if (!_mayAutoDial) {
      debugPrint('Obd2LinkSupervisor: drop ($reason) while parked '
          '(${_state.value}) — not dialing');
      return;
    }
    _setState(Obd2LinkState.reconnecting);
    // Dial immediately on the first drop; backoff grows only on misses.
    if (_attemptInFlight == null && _backoffTimer == null) {
      _backoff = Duration.zero;
      unawaited(_attempt(userInitiated: false));
    }
  }

  /// Park the loop for a classified-silent bus (#3035). The next
  /// [wake] or [connect] re-arms.
  void noteEngineOff() {
    if (_disposed || _state.value == Obd2LinkState.userDisconnected) return;
    _cancelBackoffTimer();
    _service = null;
    _setState(Obd2LinkState.engineOff);
  }

  /// Exit [Obd2LinkState.engineOff] (movement detected / app resumed)
  /// and dial. A no-op in every other state — waking a user-parked or
  /// already-live link must do nothing.
  void wake() {
    if (_disposed || _state.value != Obd2LinkState.engineOff) return;
    _backoff = Duration.zero;
    _setState(Obd2LinkState.reconnecting);
    unawaited(_attempt(userInitiated: false));
  }

  /// The single intent gate (research rule 7): auto-dialing is allowed
  /// unless the user parked the link or the bus is classified off.
  bool get _mayAutoDial =>
      !_userRequestedDisconnect && _state.value != Obd2LinkState.engineOff;

  /// The single dial path. Every connect — user tap, drop reaction,
  /// backoff tick — funnels here; `_attemptInFlight` makes it single
  /// flight (a second caller joins the same future).
  Future<Obd2Service?> _attempt({required bool userInitiated}) {
    final inFlight = _attemptInFlight;
    if (inFlight != null) return inFlight;
    final future = _attemptOnce(userInitiated: userInitiated);
    _attemptInFlight = future;
    return future.whenComplete(() {
      if (identical(_attemptInFlight, future)) _attemptInFlight = null;
    });
  }

  Future<Obd2Service?> _attemptOnce({required bool userInitiated}) async {
    _cancelBackoffTimer();
    // Tear down whatever half-dead service is still around so the
    // adapter's single RFCOMM channel is free before the fresh dial
    // (research rule 8: recovery = full close + fresh socket).
    final dead = _service;
    _service = null;
    if (dead != null) {
      try {
        await dead.disconnect();
      } catch (_) {
        // ignore: silent_catch — releasing a dead link; the fresh dial is the recovery
      }
    }
    _setState(userInitiated
        ? Obd2LinkState.connecting
        : Obd2LinkState.reconnecting);
    Obd2Service? fresh;
    Object? failure;
    try {
      fresh = await _dial();
    } catch (e) {
      failure = e;
      // A dial fault is part of normal reconnect weather (adapter out
      // of range, socket refused) — breadcrumb-level, never an ERROR
      // surface. Real terminal faults reach the user via [connect]'s
      // returned null + the UI's link state.
      debugPrint('Obd2LinkSupervisor: dial failed: $e');
      BreadcrumbCollector.add(
        'OBD2 dial failed',
        detail: '${e.runtimeType} backoff=${_backoff.inMilliseconds}ms',
      );
    }
    if (_disposed) {
      if (fresh != null) {
        try {
          await fresh.disconnect();
        } catch (_) {
          // ignore: silent_catch — supervisor is gone; nothing owns the link anymore
        }
      }
      return null;
    }
    // The user may have hit disconnect while the dial was in flight —
    // intent wins over the race (checked at the ONE gate).
    if (fresh != null && !_mayAutoDial && !userInitiated) {
      try {
        await fresh.disconnect();
      } catch (_) {
        // ignore: silent_catch — user parked the link mid-dial; releasing the unwanted socket
      }
      return null;
    }
    if (fresh != null) {
      _service = fresh;
      _backoff = Duration.zero;
      _setState(Obd2LinkState.ready);
      return fresh;
    }
    // Miss (null or fault): grow the backoff and re-arm — but only when
    // auto-dialing is still allowed. There is deliberately NO attempt
    // cap and NO terminal-failed state.
    if (_mayAutoDial) {
      _setState(Obd2LinkState.reconnecting);
      _armBackoffTimer();
    }
    if (userInitiated && failure != null) {
      // The user asked and it faulted — let the caller see why.
      Error.throwWithStackTrace(failure, StackTrace.current);
    }
    return null;
  }

  void _armBackoffTimer() {
    _cancelBackoffTimer();
    _backoff = _backoff == Duration.zero
        ? initialBackoff
        : _backoff * 2 > maxBackoff
            ? maxBackoff
            : _backoff * 2;
    // 0–12.5% jitter de-syncs the retry cadence from the adapter's own
    // advertising/settling rhythm (same rationale as #3014's jitter).
    final jitterMs = _jitter.nextInt(1 + _backoff.inMilliseconds ~/ 8);
    _backoffTimer = Timer(_backoff + Duration(milliseconds: jitterMs), () {
      _backoffTimer = null;
      if (_disposed || !_mayAutoDial) return;
      unawaited(_attempt(userInitiated: false));
    });
  }

  void _cancelBackoffTimer() {
    _backoffTimer?.cancel();
    _backoffTimer = null;
  }

  void _setState(Obd2LinkState next) {
    if (_disposed || _state.value == next) return;
    _state.value = next;
    if (!_states.isClosed) _states.add(next);
  }

  /// Detach from the drop signal and stop all timers. The current
  /// service (if any) is torn down best-effort.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cancelBackoffTimer();
    await _dropSubscription?.cancel();
    _dropSubscription = null;
    final dead = _service;
    _service = null;
    if (dead != null) {
      try {
        await dead.disconnect();
      } catch (_) {
        // ignore: silent_catch — teardown on dispose; no owner remains to care
      }
    }
    _state.dispose();
    await _states.close();
  }

  void _onDrop(Obd2LinkDropEvent event) =>
      notifyDrop('${event.transportKind}:${event.reason}');
}
