// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/logging/error_logger.dart';

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
  /// uses the cheap passive wait instead of an active scan (#2261).
  bool _passiveMode = false;

  AdapterReconnectScanner({
    required String pinnedMac,
    required AdapterInRangeProbe probe,
    required AdapterConnectAttempt connect,
    required VoidCallback onReconnect,
    AdapterConnectAttempt? passiveConnect,
    int missCeiling = 5,
    Duration initialBackoff = const Duration(seconds: 5),
    Duration maxBackoff = const Duration(seconds: 60),
    Duration firstProbeDelay = const Duration(seconds: 1),
  })  : _pinnedMac = pinnedMac,
        _probe = probe,
        _connect = connect,
        _passiveConnect = passiveConnect,
        _missCeiling = missCeiling,
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
  /// concern 2). Exposed for tests + diagnostics.
  @visibleForTesting
  bool get isPassiveWaiting => _passiveMode;

  /// Consecutive active-scan misses recorded this drop (#2261). Exposed
  /// for tests asserting the ceiling switch.
  @visibleForTesting
  int get consecutiveMisses => _consecutiveMisses;

  /// Schedule the first probe cycle. Safe to call repeatedly — a
  /// second call while already scanning is a no-op so the caller
  /// (typically [TripRecordingController._handleDrop]) doesn't have
  /// to defensively null-check.
  Future<void> start() async {
    if (_scanning) return;
    _scanning = true;
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
  /// timeout, reschedule another passive wait at the capped backoff.
  Future<void> _runPassiveCycle() async {
    final ok = await _connectSafely(passive: true);
    if (!_scanning) return; // stop() raced during the passive wait
    if (ok) {
      await stop();
      _onReconnect();
      return;
    }
    // Passive wait timed out within its window — schedule the next one.
    // Backoff is already pinned at maxBackoff (passive mode latched
    // there), so this just paces the re-arm.
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
      _currentBackoff = _maxBackoff;
      _timer?.cancel();
      _timer = Timer(_firstProbeDelay, _runCycle);
      return;
    }
    _scheduleNext();
    _doubleBackoff();
  }

  Future<bool> _probeSafely() async {
    try {
      return await _probe(_pinnedMac);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'AdapterReconnectScanner probe failed'}));
      return false;
    }
  }

  Future<bool> _connectSafely({bool passive = false}) async {
    final attempt = passive ? _passiveConnect : _connect;
    if (attempt == null) return false;
    try {
      return await attempt(_pinnedMac);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'AdapterReconnectScanner connect failed'}));
      return false;
    }
  }

  void _doubleBackoff() {
    final next = _currentBackoff * 2;
    _currentBackoff = next > _maxBackoff ? _maxBackoff : next;
  }
}
