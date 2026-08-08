// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_link_state.dart';
import 'obd2_reconnect_stand_down.dart';
import 'obd2_service.dart';

export 'obd2_link_state.dart';

part 'obd2_link_supervisor_actions.dart';

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
    Duration initialBackoff = const Duration(milliseconds: 500),
    Duration maxBackoff = const Duration(seconds: 30),
    Duration stormBackoff = const Duration(minutes: 5),
    Random? jitter,
    DateTime Function()? now,
  })  : _dial = dial,
        _standDown = ReconnectStandDown(now: now ?? DateTime.now),
        _backoff = ReconnectBackoff(
          initial: initialBackoff,
          max: maxBackoff,
          storm: stormBackoff,
          jitter: jitter ?? Random(),
        ) {
    _dropSubscription =
        (drops ?? Obd2LinkDropSignal.instance.drops).listen(_onDrop);
  }

  final Obd2LinkDialer _dial;
  final ReconnectStandDown _standDown;
  final ReconnectBackoff _backoff;

  final ValueNotifier<Obd2LinkState> _state =
      ValueNotifier<Obd2LinkState>(Obd2LinkState.idle);
  final StreamController<Obd2LinkState> _states =
      StreamController<Obd2LinkState>.broadcast();

  StreamSubscription<Obd2LinkDropEvent>? _dropSubscription;
  Obd2Service? _service;
  Future<Obd2Service?>? _attemptInFlight;
  Timer? _backoffTimer;
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

  int _attemptCount = 0;

  /// 1-based ordinal of the current reconnect attempt (telemetry /
  /// banner copy). Resets on success and on every parked state.
  int get attemptNumber => _attemptCount + 1;

  /// Current backoff in milliseconds (telemetry).
  int get currentBackoffMs => _backoff.currentMs;

  /// True once the backoff has grown to its cap — the loop is in its
  /// calm long-wait cadence (#2767's "passive waiting" banner copy).
  bool get backoffAtCap => _backoff.atCap;

  /// #3603 — true while the loop holds the storm cadence (telemetry /
  /// banner copy).
  bool get inStandDown => _standDown.active;

  /// User/policy-initiated connect. Clears the disconnect intent, exits
  /// any parked state, and dials now. Joins the in-flight attempt if
  /// one exists (single flight). Returns the live service, or null when
  /// the dial missed — in which case the backoff loop is already armed
  /// and will keep trying.
  Future<Obd2Service?> connect() {
    if (_disposed) return Future<Obd2Service?>.value();
    _userRequestedDisconnect = false;
    _standDown.reset(); // #3603 — user intent is a positive signal
    _cancelBackoffTimer();
    return _attempt(userInitiated: true);
  }

  /// Interactive connect with a ONE-SHOT dial policy override — the
  /// adapter picker / VIN reader / self-test dial a *specific* device
  /// rather than the supervisor's default pinned+rescan policy, but the
  /// attempt still runs through the same single-flight machinery
  /// (research rule 2: there is no second dial path). On success the
  /// dialed service becomes the supervised link; the backoff loop keeps
  /// using the DEFAULT dialer afterwards.
  /// #3642 — [automated] marks a machine-initiated arm (auto-record's
  /// proximity/resume dials). Automation is NOT user intent: it respects
  /// the user's park, never resets the #3603 stand-down, and during an
  /// active stand-down returns null without dialing (the supervisor's
  /// own timer keeps the cadence) — the 2026-07-29 field export's 36 ms
  /// automated redials against a parked car ended in an OS CPU kill.
  Future<Obd2Service?> connectWith(Obd2LinkDialer dialer,
      {bool automated = false}) {
    if (_disposed) return Future<Obd2Service?>.value();
    if (automated) {
      if (!_mayAutoDial) return Future<Obd2Service?>.value();
      if (_standDown.active) {
        // Keep the hold: make sure a timer exists, but never dial now.
        if (_attemptInFlight == null && _backoffTimer == null) {
          _armBackoffTimer();
        }
        return Future<Obd2Service?>.value();
      }
      return _attempt(userInitiated: false, dialer: dialer);
    }
    _userRequestedDisconnect = false;
    _standDown.reset(); // #3603 — user intent is a positive signal
    _cancelBackoffTimer();
    return _attempt(userInitiated: true, dialer: dialer);
  }

  /// User-initiated disconnect: park the loop, tear the link down. No
  /// automatic dial happens until the next [connect].
  Future<void> disconnect() async {
    _userRequestedDisconnect = true;
    _cancelBackoffTimer();
    _attemptCount = 0;
    _standDown.reset(); // #3603
    final dead = _service;
    _service = null;
    _setState(Obd2LinkState.userDisconnected);
    await _release(dead, 'disconnect');
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
    _standDown.noteDrop(); // #3603 — flap accounting
    // #3534 — the per-drop timeline starts here (detect → dial →
    // recovered); the field-validation checklist reads this chain out
    // of the breadcrumb export after an induced-drop drive.
    BreadcrumbCollector.add('OBD2 link drop', detail: reason);
    _setState(Obd2LinkState.reconnecting);
    // Dial immediately on the first drop; backoff grows only on misses.
    if (_attemptInFlight == null && _backoffTimer == null) {
      if (_standDown.active) {
        // #3603 — success-flap stand-down: the instant redial is what
        // burned 20 dial→adopt→drop cycles in the field. Hold the
        // storm cadence until a ready survives or the user acts.
        _armBackoffTimer();
        return;
      }
      _backoff.reset();
      unawaited(_attempt(userInitiated: false));
    }
  }


  /// The single intent gate (research rule 7): auto-dialing is allowed
  /// unless the user parked the link or the bus is classified off.
  bool get _mayAutoDial =>
      !_userRequestedDisconnect && _state.value != Obd2LinkState.engineOff;

  /// The single dial path. Every connect — user tap, drop reaction,
  /// backoff tick — funnels here; `_attemptInFlight` makes it single
  /// flight (a second caller joins the same future).
  ///
  /// #3553 — a caller carrying a [dialer] OVERRIDE must never have its
  /// dial policy silently swallowed by whatever attempt is already in
  /// flight: field evidence showed auto-record's dial for the ACTIVE
  /// vehicle's adapter joining the backoff loop's dial to the PREVIOUS
  /// (last-good) adapter, returning the wrong target's failure — and the
  /// requested device never being dialed at all. The override now joins
  /// for the result first (a live link satisfies everyone — one link
  /// only), and chains its own attempt strictly AFTER a missed in-flight
  /// completes. Still never two concurrent dials.
  Future<Obd2Service?> _attempt(
      {required bool userInitiated, Obd2LinkDialer? dialer}) {
    final inFlight = _attemptInFlight;
    if (inFlight != null) {
      if (dialer == null) return inFlight;
      return inFlight.then((svc) => svc != null || _disposed
          ? svc
          : _attempt(userInitiated: userInitiated, dialer: dialer));
    }
    final future = _attemptOnce(userInitiated: userInitiated, dialer: dialer);
    _attemptInFlight = future;
    return future.whenComplete(() {
      if (identical(_attemptInFlight, future)) _attemptInFlight = null;
    });
  }

  Future<Obd2Service?> _attemptOnce(
      {required bool userInitiated, Obd2LinkDialer? dialer}) async {
    _cancelBackoffTimer();
    // Tear down whatever half-dead service is still around so the
    // adapter's single RFCOMM channel is free before the fresh dial
    // (research rule 8: recovery = full close + fresh socket).
    final dead = _service;
    _service = null;
    await _release(dead, 'recycle');
    _setState(userInitiated
        ? Obd2LinkState.connecting
        : Obd2LinkState.reconnecting);
    Obd2Service? fresh;
    Object? failure;
    try {
      fresh = await (dialer ?? _dial)();
    } catch (e, st) {
      failure = e;
      // A dial fault is part of normal reconnect weather (adapter out
      // of range, socket refused) — breadcrumb-level, never an ERROR
      // surface. Real terminal faults reach the user via [connect]'s
      // returned null + the UI's link state.
      debugPrint('Obd2LinkSupervisor: dial failed: $e\n$st');
      BreadcrumbCollector.add(
        'OBD2 dial failed',
        detail: '${e.runtimeType} backoff=${_backoff.currentMs}ms',
      );
    }
    if (_disposed) {
      await _release(fresh, 'disposedDial');
      return null;
    }
    // The user may have hit disconnect while the dial was in flight —
    // intent wins over the race (checked at the ONE gate).
    if (fresh != null && !_mayAutoDial && !userInitiated) {
      await _release(fresh, 'parkedMidDial');
      return null;
    }
    if (fresh != null) {
      // #3534 — close the drop timeline: a recovery names how many dials
      // it took (attempt 1 = the immediate post-drop dial). A plain
      // user-initiated first connect is 0 prior misses.
      BreadcrumbCollector.add(
        'OBD2 link ready',
        detail: userInitiated && _attemptCount == 0
            ? 'first connect'
            : 'recovered after ${_attemptCount + 1} dial(s)',
      );
      _service = fresh;
      _backoff.reset();
      _attemptCount = 0;
      _standDown.noteReady(); // #3603 — clears misses, arms flap clock
      _setState(Obd2LinkState.ready);
      return fresh;
    }
    _attemptCount++;
    _standDown.noteMiss(failure); // #3603 — identical-signature streak
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

  /// Best-effort teardown of a dead or unwanted service — a throwing
  /// disconnect must never derail the loop (research rules 8 + 9); the
  /// fault is logged, not surfaced.
  Future<void> _release(Obd2Service? dead, String where) async {
    if (dead == null) return;
    try {
      await dead.disconnect();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: {'where': 'Obd2LinkSupervisor.$where'}));
    }
  }

  void _armBackoffTimer() {
    _cancelBackoffTimer();
    final wasStandDown = inStandDown;
    final wait = _backoff.advance(standDown: wasStandDown);
    if (wasStandDown) {
      // #3603 / #3642 — one breadcrumb per storm-cadence arm, with the
      // ACTUAL hold (the escalation lengthens it 5 → 15 → 60 min).
      BreadcrumbCollector.add(
        'OBD2 reconnect stand-down',
        detail: '${_standDown.detail} — '
            'holding ${wait.inSeconds}s',
      );
    }
    _backoffTimer = Timer(wait, () {
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
    await _release(dead, 'dispose');
    _state.dispose();
    await _states.close();
  }

  void _onDrop(Obd2LinkDropEvent event) =>
      notifyDrop('${event.transportKind}:${event.reason}');
}
