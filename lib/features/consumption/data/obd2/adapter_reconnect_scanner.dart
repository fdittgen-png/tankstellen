import 'dart:async';

import 'package:flutter/foundation.dart';

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
///   - [start] schedules the first timer at [initialBackoff].
///   - [stop] cancels the timer cleanly; safe to call more than
///     once.
///   - The scanner does not own the controller; the caller decides
///     what `onReconnect` means (typically "cancel grace, resume").
class AdapterReconnectScanner {
  final String _pinnedMac;
  final AdapterInRangeProbe _probe;
  final AdapterConnectAttempt _connect;
  final VoidCallback _onReconnect;
  final Duration _maxBackoff;

  Duration _currentBackoff;
  Timer? _timer;
  bool _scanning = false;
  bool _cycleInFlight = false;

  AdapterReconnectScanner({
    required String pinnedMac,
    required AdapterInRangeProbe probe,
    required AdapterConnectAttempt connect,
    required VoidCallback onReconnect,
    Duration initialBackoff = const Duration(seconds: 5),
    Duration maxBackoff = const Duration(seconds: 60),
  })  : _pinnedMac = pinnedMac,
        _probe = probe,
        _connect = connect,
        _onReconnect = onReconnect,
        _maxBackoff = maxBackoff,
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

  /// Schedule the first probe cycle. Safe to call repeatedly — a
  /// second call while already scanning is a no-op so the caller
  /// (typically [TripRecordingController._handleDrop]) doesn't have
  /// to defensively null-check.
  Future<void> start() async {
    if (_scanning) return;
    _scanning = true;
    _scheduleNext();
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
  Future<void> _runCycle() async {
    // Overlapping ticks would let two connects race each other,
    // which the transport is not designed to handle. Cheap guard.
    if (_cycleInFlight || !_scanning) return;
    _cycleInFlight = true;
    try {
      final inRange = await _probeSafely();
      if (!_scanning) return; // stop() raced — honour it
      if (!inRange) {
        _doubleBackoff();
        _scheduleNext();
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
      // dance interrupted). Treat as a miss — double the backoff
      // so we don't hammer the adapter.
      _doubleBackoff();
      _scheduleNext();
    } finally {
      _cycleInFlight = false;
    }
  }

  Future<bool> _probeSafely() async {
    try {
      return await _probe(_pinnedMac);
    } catch (e, st) {
      debugPrint('AdapterReconnectScanner probe failed: $e\n$st');
      return false;
    }
  }

  Future<bool> _connectSafely() async {
    try {
      return await _connect(_pinnedMac);
    } catch (e, st) {
      debugPrint('AdapterReconnectScanner connect failed: $e\n$st');
      return false;
    }
  }

  void _doubleBackoff() {
    final next = _currentBackoff * 2;
    _currentBackoff = next > _maxBackoff ? _maxBackoff : next;
  }
}
