// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'last_good_adapter_store.dart';

/// Coarse lifecycle state of the trip-INDEPENDENT auto-reconnect
/// controller (#3019 / Epic #3013 phase 3).
///
/// Unlike the in-trip [DroppedSessionManager] (#2188) — whose recovery is
/// gated on an active recording — this state machine is driven purely by
/// the connection lifecycle, so a drop while idle / between trips still
/// re-establishes the link.
enum Obd2ReconnectState {
  /// No link, no reconnect in flight (fresh boot, or after a terminal
  /// failure was acknowledged).
  idle,

  /// A live, healthy link.
  connected,

  /// A drop fired and the bounded backoff loop is actively trying to
  /// re-establish — pinned fast path first, then re-scan fallback.
  reconnecting,

  /// The bounded attempts were exhausted. The auto-loop has STOPPED; the
  /// UI shows a "tap to retry" affordance whose action calls [retry].
  terminalFailed,
}

/// Outcome of one reconnect attempt the controller drives. The two
/// non-success cases stay distinct so the controller can keep its backoff
/// schedule (`failed`) vs. note that the pinned adapter simply wasn't
/// reachable this cycle (`notFound`) — both advance the attempt counter,
/// but the distinction is surfaced in tracing.
enum Obd2ReconnectAttemptResult { connected, notFound, failed }

/// "Try the pinned adapter on its known transport, no scan." Returns
/// [Obd2ReconnectAttemptResult.connected] once a session is established,
/// else `notFound` / `failed`. MUST NOT throw — the controller treats a
/// throw as `failed` defensively, but a well-behaved seam catches
/// internally (mirroring [ReconnectConnector]).
typedef PinnedConnectAttempt = Future<Obd2ReconnectAttemptResult> Function(
  LastGoodAdapter pinned,
);

/// "Re-scan and connect to a matching adapter." The bounded fallback when
/// the pinned fast path can't find / connect the adapter (changed or
/// duplicate dongle). [pinned] is the hint to match against; null when no
/// adapter was ever pinned (scan + best-match). MUST NOT throw.
typedef RescanConnectAttempt = Future<Obd2ReconnectAttemptResult> Function(
  LastGoodAdapter? pinned,
);

/// Trip-INDEPENDENT auto-reconnect controller (#3019 / Epic #3013 phase 3).
///
/// The maintainer's ask — *"when the connection gets lost, that it quickly
/// reconnect without troubles"* — generalised past a live trip. Phases 1+2
/// (#3016) made the FIRST connect reliable; this makes RE-connect reliable
/// and decoupled:
///
///  1. **Decoupled from a live trip.** [notifyDropped] starts the loop
///     regardless of whether a recording is active. The same drop signal
///     that the in-trip path reacts to (incl. the proactive Classic
///     socket-closed signal, #2671) also feeds here.
///  2. **Pinned fast path first.** Each attempt tries [pinnedConnect] for
///     the auto-pinned [LastGoodAdapter] (a transport-correct direct
///     connect, leveraging #3016 scan-before-connect) before any scan.
///  3. **Re-scan fallback.** When the pinned path returns `notFound` /
///     `failed`, the SAME attempt falls back to [rescanConnect] so a
///     changed / duplicate adapter still recovers.
///  4. **Bounded + backoff.** Up to [maxAttempts] attempts, the delay
///     between them doubling from [initialBackoff] (capped at
///     [maxBackoff]). No infinite tight loop, no battery drain.
///  5. **Terminal tap-to-retry.** After the bound is hit the loop STOPS in
///     [Obd2ReconnectState.terminalFailed]; [retry] resets the counter +
///     backoff and restarts, so the user is never stranded on a spinner
///     and the radio never spins forever.
///
/// Pure-Dart + fully injected (the clock, the two connect seams, the pin
/// store, the callbacks) so a unit test drives the real state machine
/// against a fake transport it can make DROP and FAIL-then-SUCCEED, with
/// no Bluetooth stack and no wall-clock waits.
class Obd2ReconnectController {
  final LastGoodAdapterStore _pinStore;
  final PinnedConnectAttempt _pinnedConnect;
  final RescanConnectAttempt _rescanConnect;

  /// Maximum bounded reconnect attempts before the loop gives up into
  /// [Obd2ReconnectState.terminalFailed]. Each attempt is one pinned-path
  /// try + (on miss) one re-scan-path try.
  final int _maxAttempts;

  final Duration _initialBackoff;
  final Duration _maxBackoff;

  /// Delay before the FIRST attempt after a drop (#1991 lineage). A fresh
  /// drop is most often a transient blip, so the first retry is near-
  /// immediate; subsequent misses use the exponential backoff.
  final Duration _firstAttemptDelay;

  /// Emitted on every state transition so a notifier / widget can react.
  void Function(Obd2ReconnectState state)? onState;

  Obd2ReconnectController({
    required LastGoodAdapterStore pinStore,
    required PinnedConnectAttempt pinnedConnect,
    required RescanConnectAttempt rescanConnect,
    this.onState,
    int maxAttempts = 6,
    Duration initialBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 60),
    Duration firstAttemptDelay = const Duration(seconds: 1),
  })  : assert(maxAttempts > 0, 'maxAttempts must be positive'),
        _pinStore = pinStore,
        _pinnedConnect = pinnedConnect,
        _rescanConnect = rescanConnect,
        _maxAttempts = maxAttempts,
        _initialBackoff = initialBackoff,
        _maxBackoff = maxBackoff,
        _firstAttemptDelay = firstAttemptDelay,
        _currentBackoff = initialBackoff;

  Obd2ReconnectState _state = Obd2ReconnectState.idle;
  Duration _currentBackoff;
  Timer? _timer;
  int _attempts = 0;
  bool _cycleInFlight = false;

  /// Current lifecycle state.
  Obd2ReconnectState get state => _state;

  /// `true` while the bounded backoff loop is actively trying.
  bool get isReconnecting => _state == Obd2ReconnectState.reconnecting;

  /// `true` once the bound was exhausted — the UI shows "tap to retry".
  bool get hasFailedTerminally => _state == Obd2ReconnectState.terminalFailed;

  /// Attempts made so far in the CURRENT episode (reset by [retry] and by a
  /// fresh [notifyDropped]). Exposed for tests + diagnostics.
  @visibleForTesting
  int get attempts => _attempts;

  /// Backoff that will pace the NEXT scheduled attempt. Exposed for tests
  /// asserting the doubling.
  @visibleForTesting
  Duration get currentBackoff => _currentBackoff;

  /// Mark the link healthy (after a first connect / a successful
  /// reconnect). Cancels any in-flight loop and clears the counters so the
  /// next drop starts a clean episode.
  void notifyConnected() {
    _timer?.cancel();
    _timer = null;
    _attempts = 0;
    _currentBackoff = _initialBackoff;
    _cycleInFlight = false;
    _transition(Obd2ReconnectState.connected);
  }

  /// React to a detected connection drop — the trip-INDEPENDENT entry
  /// point. Starts the bounded backoff loop. Idempotent: a second call
  /// while already reconnecting is a no-op so the (possibly multiple) drop
  /// signals a single physical disconnect raises don't stack loops.
  void notifyDropped() {
    if (_state == Obd2ReconnectState.reconnecting) return;
    _attempts = 0;
    _currentBackoff = _initialBackoff;
    _transition(Obd2ReconnectState.reconnecting);
    _scheduleNext(_firstAttemptDelay);
  }

  /// User tapped "retry" on the terminal-failure affordance. Resets the
  /// attempt counter + backoff and restarts the bounded loop. A no-op
  /// unless the controller is in [Obd2ReconnectState.terminalFailed] (a
  /// retry while a loop is still running would just double-schedule).
  void retry() {
    if (_state != Obd2ReconnectState.terminalFailed) return;
    _attempts = 0;
    _currentBackoff = _initialBackoff;
    _transition(Obd2ReconnectState.reconnecting);
    _scheduleNext(_firstAttemptDelay);
  }

  /// Stop the loop entirely (the user navigated away / disabled OBD2, or
  /// the owner is disposing). Safe to call repeatedly.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _cycleInFlight = false;
    _transition(Obd2ReconnectState.idle);
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _runCycle);
  }

  /// One bounded reconnect cycle: pinned fast path first, re-scan fallback
  /// on a miss. On success → [Obd2ReconnectState.connected] + self-stop;
  /// on a miss/fail → bump the counter, and either schedule the next
  /// (backed-off) attempt or, at the bound, go terminal.
  Future<void> _runCycle() async {
    // Overlapping cycles would race two connects through the transport,
    // which it isn't built for. Cheap guard (mirrors the in-trip scanner).
    if (_cycleInFlight || _state != Obd2ReconnectState.reconnecting) return;
    _cycleInFlight = true;
    try {
      final pinned = _pinStore.recall();
      // 1) PINNED FAST PATH (transport-correct direct connect, no scan).
      var result = pinned == null
          ? Obd2ReconnectAttemptResult.notFound
          : await _safely(() => _pinnedConnect(pinned));
      if (_state != Obd2ReconnectState.reconnecting) return; // stop() raced
      // 2) RE-SCAN FALLBACK — only when the pinned path didn't land.
      if (result != Obd2ReconnectAttemptResult.connected) {
        result = await _safely(() => _rescanConnect(pinned));
        if (_state != Obd2ReconnectState.reconnecting) return;
      }
      if (result == Obd2ReconnectAttemptResult.connected) {
        notifyConnected();
        return;
      }
      _onAttemptFailed();
    } finally {
      _cycleInFlight = false;
    }
  }

  /// Bump the attempt counter; either schedule the next backed-off attempt
  /// or, at [_maxAttempts], stop the loop into the terminal state.
  void _onAttemptFailed() {
    _attempts++;
    if (_attempts >= _maxAttempts) {
      _timer?.cancel();
      _timer = null;
      _transition(Obd2ReconnectState.terminalFailed);
      return;
    }
    _scheduleNext(_currentBackoff);
    _doubleBackoff();
  }

  void _doubleBackoff() {
    final next = _currentBackoff * 2;
    _currentBackoff = next > _maxBackoff ? _maxBackoff : next;
  }

  /// Run a connect seam defensively: a well-behaved seam never throws, but
  /// a throw is treated as [Obd2ReconnectAttemptResult.failed] so a buggy
  /// transport can never wedge the loop.
  Future<Obd2ReconnectAttemptResult> _safely(
    Future<Obd2ReconnectAttemptResult> Function() attempt,
  ) async {
    try {
      return await attempt();
    } catch (e, st) {
      debugPrint('Obd2ReconnectController: connect seam threw '
          '(treated as failed) — $e\n$st');
      return Obd2ReconnectAttemptResult.failed;
    }
  }

  void _transition(Obd2ReconnectState next) {
    if (_state == next) return;
    _state = next;
    onState?.call(next);
  }

  /// Tear down for good — cancels the timer and detaches the listener.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    onState = null;
  }
}
