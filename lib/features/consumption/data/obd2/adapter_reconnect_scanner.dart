// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_read_telemetry.dart';
import 'reconnect_scanner_diagnostics.dart';

/// Callback signature: "is the pinned adapter MAC currently
/// discoverable?". Resolved by the scanner against the active
/// [BluetoothFacade]. Returns `true` when the last scan cycle saw
/// the pinned MAC, `false` otherwise. The scanner never asks the
/// caller whether a reconnect should happen — it decides by itself
/// based on the probe outcome.
typedef AdapterInRangeProbe = Future<bool> Function(String mac);

/// Callback signature: "connect to this MAC". Called exactly once
/// per successful probe cycle. Implementations should return `true`
/// when the Obd2Service is ready to resume polling, `false` when
/// the connect dance failed halfway (the scanner then keeps running
/// with the same backoff, giving the adapter another chance on the
/// next tick). Never throws — catch internally and return `false`.
typedef AdapterConnectAttempt = Future<bool> Function(String mac);

/// Auto-reconnect scanner for a pinned OBD2 adapter (#797 phase 3).
///
/// Boots a low-duty periodic probe: every [_currentBackoff] seconds
/// it asks [probe] whether the pinned MAC is in range. On a hit it
/// calls [connect]; if the connect succeeds, [onReconnect] fires
/// and the scanner self-stops — the caller is expected to cancel
/// the grace timer and resume the trip.
///
/// Backoff is exponential with a ceiling: every failed cycle
/// doubles [_currentBackoff] up to [maxBackoff], so the scanner
/// stays cheap even when the adapter is out of range for minutes
/// (toll-booth, parking garage). A successful probe + connect does
/// not need to reset anything because the scanner stops.
///
/// Battery discipline: the scanner runs a `Timer` with the current
/// backoff. It never polls continuously — each cycle delegates the
/// duty-cycled scan window to the [BluetoothFacade] implementation.
/// The production facade uses flutter_blue_plus' timed scan which
/// respects the OS scan window / interval.
///
/// Lifetime:
///   - Constructed by the controller when `_handleDrop` fires.
///   - [start] schedules the first probe after a short `firstProbeDelay`
///     (#1991) — a fresh drop is usually a transient BLE blip, so the
///     first reconnect must land inside the controller's silent-
///     reconnect grace window rather than after the full backoff.
///   - [stop] cancels the timer cleanly; safe to call more than
///     once.
///   - The scanner does not own the controller; the caller decides
///     what `onReconnect` means (typically "cancel grace, resume").
class AdapterReconnectScanner {
  final String _pinnedMac;
  final AdapterInRangeProbe _probe;
  final AdapterConnectAttempt _connect;

  /// Passive-wait connect callback used once the active-scan miss
  /// ceiling is reached (#2261 concern 2). Null ⇒ the scanner keeps
  /// active-scanning for the whole grace (pre-#2261 behaviour).
  final AdapterConnectAttempt? _passiveConnect;

  final VoidCallback _onReconnect;
  final Duration _maxBackoff;

  /// Number of consecutive active-scan misses after which the scanner
  /// switches from battery-burning active 8 s scans to a single passive
  /// autoConnect GATT wait for the remainder of the grace (#2261
  /// concern 2). On a parked car the adapter never comes back, so after
  /// ~5–6 fruitless active scans there is no point spinning the radio —
  /// a passive GATT wait costs nothing and still wakes the link the
  /// instant the adapter powers back up. Ignored when [_passiveConnect]
  /// is null.
  final int _missCeiling;

  /// #2767 — number of consecutive passive-wait cycles after which the
  /// scanner RE-ARMS one active scan (resets [_passiveMode] +
  /// [_consecutiveMisses]) instead of staying passive forever. The pre-#2767
  /// scanner latched passive-only at the ceiling and never re-escalated, so a
  /// late adapter power-cycle (dropped at min 10, back at min 25) could be
  /// missed: a passive autoConnect GATT wait can go stale on some stacks, and
  /// only a fresh active scan reliably re-discovers an adapter that toggled
  /// its advertising. Re-arming periodically keeps the radio mostly quiet
  /// (one active burst every [_passiveReArmEvery] long passive waits) while
  /// guaranteeing the link is re-probed. Ignored when [_passiveConnect] is
  /// null (the scanner never enters passive mode then).
  final int _passiveReArmEvery;

  /// Fired ONCE per drop the instant the scanner latches passive mode at the
  /// active-scan miss ceiling (#2767). Settable (not a constructor arg) so
  /// the manager can wire it after the injected factory builds the scanner,
  /// without rippling the factory's `(mac, onReconnect)` signature into every
  /// test. Null ⇒ the caller doesn't surface the active-vs-passive
  /// distinction (behaviour unchanged from before #2767).
  VoidCallback? onPassiveWait;

  /// Delay before the FIRST probe after a drop (#1991). A fresh drop is
  /// most often a transient BLE blip; probing near-immediately — rather
  /// than after the full [_currentBackoff] — lets the reconnect land
  /// inside the controller's 6 s silent-reconnect grace window, so the
  /// user never sees the "connection lost" banner. Only the first
  /// attempt is fast; subsequent misses use exponential backoff.
  final Duration _firstProbeDelay;

  Duration _currentBackoff;
  Timer? _timer;
  bool _scanning = false;
  bool _cycleInFlight = false;

  /// Consecutive active-scan misses so far this drop (#2261 concern 2).
  int _consecutiveMisses = 0;

  /// Latches `true` once [_missCeiling] is reached, so every later cycle
  /// uses the cheap passive wait instead of an active scan (#2261). #2767 —
  /// no longer a permanent latch: it is reset to `false` every
  /// [_passiveReArmEvery] passive cycles to re-arm one active scan.
  bool _passiveMode = false;

  /// #2767 — consecutive passive-wait cycles since passive mode was last
  /// (re-)entered. Reset to 0 each time the scanner re-arms an active scan.
  int _passiveCycles = 0;

  /// #2767 — guards the one-shot [onPassiveWait] callback so it fires only
  /// on the FIRST transition into passive mode this drop, not on every
  /// re-arm → passive flip. The UI banner copy only needs to flip once.
  bool _notifiedPassiveWait = false;

  /// #2466 — measures elapsed time from [start] to the successful
  /// reconnect, fed into the gated comm-diagnostics time-to-reconnect
  /// reservoir. Null until [start] (and only allocated when the collector
  /// is armed, so production pays nothing).
  Stopwatch? _sinceStart;

  /// #2466 — whether the backoff has escalated past its initial value
  /// during this drop episode. Drives the silent-vs-visible reconnect
  /// classification: a reconnect that lands before the first escalation
  /// (the fast `firstProbeDelay` probe / first attempt) is SILENT — it
  /// healed inside the controller's grace window and the user never saw a
  /// banner; one that lands after any escalation (or in passive mode) is
  /// VISIBLE.
  bool _backoffEscalated = false;

  AdapterReconnectScanner({
    required String pinnedMac,
    required AdapterInRangeProbe probe,
    required AdapterConnectAttempt connect,
    required VoidCallback onReconnect,
    AdapterConnectAttempt? passiveConnect,
    this.onPassiveWait,
    int missCeiling = 5,
    int passiveReArmEvery = 4,
    Duration initialBackoff = const Duration(seconds: 5),
    Duration maxBackoff = const Duration(seconds: 60),
    Duration firstProbeDelay = const Duration(seconds: 1),
  })  : _pinnedMac = pinnedMac,
        _probe = probe,
        _connect = connect,
        _passiveConnect = passiveConnect,
        _missCeiling = missCeiling,
        _passiveReArmEvery = passiveReArmEvery,
        _onReconnect = onReconnect,
        _maxBackoff = maxBackoff,
        _firstProbeDelay = firstProbeDelay,
        _currentBackoff = initialBackoff;

  /// `true` while the scanner is active (a probe timer is scheduled
  /// or a cycle is currently in flight). Flips to `false` after the
  /// scanner self-stops on a successful reconnect, or after [stop].
  bool get isScanning => _scanning;

  /// MAC the scanner is looking for. Exposed for debugging + tests.
  @visibleForTesting
  String get pinnedMac => _pinnedMac;

  /// Current backoff delay used for the next scheduled cycle.
  /// Exposed for tests that want to assert the doubling behaviour
  /// directly rather than timing successive fake-async advances.
  @visibleForTesting
  Duration get currentBackoff => _currentBackoff;

  /// `true` once the active-scan miss ceiling was reached and the
  /// scanner switched to the passive autoConnect GATT wait (#2261
  /// concern 2). #2767 — read in production by the [DroppedSessionManager]
  /// to drive the calmer "passive-waiting" banner copy, so this is a public
  /// signal, not a test-only one. Note it can flip back to `false` when the
  /// scanner periodically re-arms an active scan from passive mode.
  bool get isPassiveWaiting => _passiveMode;

  /// Consecutive active-scan misses recorded this drop (#2261). Exposed
  /// for tests asserting the ceiling switch.
  @visibleForTesting
  int get consecutiveMisses => _consecutiveMisses;

  /// #2905 — 1-based ordinal + current backoff (ms) of the attempt the
  /// scanner is ABOUT to make, read by the [ReconnectConnector] so each
  /// per-attempt telemetry row carries its episode ordinal + backoff.
  int get currentAttemptNumber => _consecutiveMisses + 1;

  /// See [currentAttemptNumber].
  int get currentBackoffMs => _currentBackoff.inMilliseconds;

  /// Schedule the first probe cycle. Safe to call repeatedly — a
  /// second call while already scanning is a no-op so the caller
  /// (typically [TripRecordingController._handleDrop]) doesn't have
  /// to defensively null-check.
  Future<void> start() async {
    if (_scanning) return;
    _scanning = true;
    // #2466 — start the time-to-reconnect clock (gated; only allocate the
    // Stopwatch when the collector is armed). The episode begins now: the
    // controller constructs + starts the scanner the moment a drop fires.
    _backoffEscalated = false;
    // #2767 — a fresh drop episode starts in active mode; clear the passive
    // latch + re-arm bookkeeping so a reused scanner instance doesn't inherit
    // a stale passive state.
    _consecutiveMisses = 0;
    _passiveMode = false;
    _passiveCycles = 0;
    _notifiedPassiveWait = false;
    _sinceStart =
        Obd2CommDiagnostics.instance.enabled ? (Stopwatch()..start()) : null;
    // #2905 — mark the episode entering the active reconnecting state.
    recordReconnectingStarted();
    // #1991 — first probe fast (a transient drop recovers quickest with
    // a near-immediate retry); subsequent misses fall back to the
    // exponential backoff via `_scheduleNext`.
    _timer = Timer(_firstProbeDelay, _runCycle);
  }

  /// Cancel any pending timer and mark the scanner stopped. Safe to
  /// call more than once and safe to call before [start].
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _scanning = false;
  }

  void _scheduleNext() {
    if (!_scanning) return;
    _timer?.cancel();
    _timer = Timer(_currentBackoff, _runCycle);
  }

  /// One probe + optional connect round. Doubles backoff on miss /
  /// connect failure, fires [onReconnect] + self-stops on success.
  ///
  /// #2261 concern 2 — once [_consecutiveMisses] reaches [_missCeiling]
  /// (and a [_passiveConnect] callback was supplied) the cycle switches
  /// to passive mode: it skips the active in-range probe entirely and
  /// instead does a single long-lived passive autoConnect GATT wait,
  /// rescheduling at the capped backoff if that wait times out. This
  /// stops the radio from burning battery on a parked car while still
  /// waking the link the instant the adapter powers back up.
  Future<void> _runCycle() async {
    // Overlapping ticks would let two connects race each other,
    // which the transport is not designed to handle. Cheap guard.
    if (_cycleInFlight || !_scanning) return;
    _cycleInFlight = true;
    try {
      if (_passiveMode) {
        await _runPassiveCycle();
        return;
      }
      final inRange = await _probeSafely();
      if (!_scanning) return; // stop() raced — honour it
      if (!inRange) {
        _registerMiss();
        return;
      }
      final ok = await _connectSafely();
      if (!_scanning) return; // stop() raced during connect
      if (ok) {
        // Self-stop before firing the callback so the callback can
        // re-enter the scanner (e.g. start a new one on the next
        // drop) without clashing with a stale timer.
        await stop();
        _noteReconnectDiagnostics();
        _onReconnect();
        return;
      }
      // Probe said "in range" but connect failed (adapter busy,
      // dance interrupted). Treat as a miss.
      _registerMiss();
    } finally {
      _cycleInFlight = false;
    }
  }

  /// A passive-mode cycle: wait on a passive autoConnect GATT connect
  /// (no active scan). On success, fire [onReconnect] + self-stop; on a
  /// timeout, either re-arm an active scan (every [_passiveReArmEvery]
  /// passive cycles, #2767) or reschedule another passive wait.
  Future<void> _runPassiveCycle() async {
    final ok = await _connectSafely(passive: true);
    if (!_scanning) return; // stop() raced during the passive wait
    if (ok) {
      await stop();
      // A passive-mode reconnect is by definition VISIBLE — it only
      // happens past the active-scan miss ceiling, long after the
      // silent-reconnect grace window closed.
      _noteReconnectDiagnostics();
      _onReconnect();
      return;
    }
    // Passive wait timed out within its window.
    _passiveCycles++;
    // #2767 — never stay passive forever: every [_passiveReArmEvery] timed-out
    // passive waits, drop back to a single active scan so a late adapter
    // power-cycle (which may have stale/dead passive autoConnect state) is
    // re-discovered. Reset the miss counter so the active path runs the full
    // [_missCeiling] attempts again before it re-enters passive mode.
    if (_passiveReArmEvery > 0 && _passiveCycles >= _passiveReArmEvery) {
      _passiveMode = false;
      _passiveCycles = 0;
      _consecutiveMisses = 0;
      // Probe promptly so the re-armed active scan lands quickly rather than
      // after another capped-backoff wait. Backoff stays pinned at maxBackoff
      // so the active retries that follow stay paced.
      _timer?.cancel();
      _timer = Timer(_firstProbeDelay, _runCycle);
      return;
    }
    // Otherwise reschedule another passive wait. Backoff is already pinned at
    // maxBackoff (passive mode latched there), so this just paces the re-arm.
    _scheduleNext();
  }

  /// Record an active-scan miss: schedule the next retry at the current
  /// backoff (THEN double it — so the first retry after a fast first
  /// probe uses `initialBackoff`, not `initialBackoff × 2`, #1991), and
  /// flip into passive mode once the miss ceiling is reached (#2261).
  void _registerMiss() {
    _consecutiveMisses++;
    if (_passiveConnect != null && _consecutiveMisses >= _missCeiling) {
      // Ceiling reached — stop burning the radio. Pin the backoff at the
      // ceiling so the passive-wait re-arm is paced, and run the first
      // passive wait promptly.
      _passiveMode = true;
      _passiveCycles = 0; // #2767 — fresh re-arm window
      _backoffEscalated = true; // #2466 — past the ceiling ⇒ visible
      _currentBackoff = _maxBackoff;
      // #2767 — tell the caller the scanner gave up active scanning and is
      // now passive-waiting, so the UI can surface a calmer banner. Fired
      // once per drop (not on every active→passive re-arm flip).
      if (!_notifiedPassiveWait) {
        _notifiedPassiveWait = true;
        onPassiveWait?.call();
      }
      _timer?.cancel();
      _timer = Timer(_firstProbeDelay, _runCycle);
      return;
    }
    _scheduleNext();
    _doubleBackoff();
  }

  // #2953 — _probeSafely / _connectSafely route their catch through this: an
  // EXPECTED engine-off transient (parked car) becomes a breadcrumb, not an
  // ERROR every backoff cycle (#2892/#2935/#2945 never reached this site). A
  // genuine fault still ERROR-logs (storage layer, the default).
  bool _denoise(Object e, StackTrace st, String where) {
    recordObd2ConnectTransient(e, st, where: where);
    return false;
  }

  Future<bool> _probeSafely() async {
    try {
      return await _probe(_pinnedMac);
    } catch (e, st) {
      return _denoise(e, st, 'AdapterReconnectScanner probe failed');
    }
  }

  Future<bool> _connectSafely({bool passive = false}) async {
    final attempt = passive ? _passiveConnect : _connect;
    if (attempt == null) return false;
    try {
      return await attempt(_pinnedMac);
    } catch (e, st) {
      return _denoise(e, st, 'AdapterReconnectScanner connect failed');
    }
  }

  void _doubleBackoff() {
    final next = _currentBackoff * 2;
    _currentBackoff = next > _maxBackoff ? _maxBackoff : next;
    // #2466 — the episode has now lasted past at least one missed cycle,
    // so a reconnect from here on is VISIBLE (it landed after the fast
    // first probe failed and the backoff grew).
    _backoffEscalated = true;
  }

  /// #2466 + #2905 — record one successful reconnect via the gated
  /// comm-health helper: the silent-vs-visible tally + time-to-reconnect
  /// sample (from [start]) PLUS the `reconnected` transition marker. A
  /// no-op unless `Feature.debugMode` armed the collector. The per-attempt
  /// `succeeded:true` row is recorded by the [ReconnectConnector], the
  /// single owner of per-attempt path/reason/rssi detail.
  void _noteReconnectDiagnostics() {
    final elapsed = _sinceStart?.elapsedMilliseconds;
    _sinceStart = null;
    recordReconnectSuccess(silent: !_backoffEscalated, elapsedMs: elapsed);
  }
}
