import 'obd2_connection_errors.dart';

/// Owns the connection-drop *detection* heuristics extracted from
/// [TripRecordingController] (#1679): the #797 transport-error sliding
/// window and the #1330 silent-failure null-parse counter.
///
/// This collaborator only *detects* — it counts, classifies, and
/// answers "should the controller drop now?". The *reaction* (pausing
/// the scheduler, persisting the paused snapshot, the grace timer, the
/// reconnect scanner) stays on the controller, which is ordering-
/// sensitive lifecycle that doesn't belong here.
class TripDropDetector {
  TripDropDetector({
    required DateTime Function() now,
    Duration dropWindow = const Duration(seconds: 5),
    int dropThreshold = 3,
    int silentFailureThreshold = 50,
  })  : _now = now,
        _dropWindow = dropWindow,
        _dropThreshold = dropThreshold,
        _silentFailureThreshold = silentFailureThreshold;

  final DateTime Function() _now;

  /// Sliding window used for the "3 consecutive transport errors"
  /// heuristic (#797 phase 1).
  final Duration _dropWindow;
  final int _dropThreshold;

  /// Threshold for the "adapter connected but every PID parse returns
  /// null" silent-failure heuristic (#1330 phase 3).
  final int _silentFailureThreshold;

  /// Consecutive-error bookkeeping for the drop heuristic. First entry
  /// is the oldest. Reset on a successful transport read.
  final List<DateTime> _recentErrors = <DateTime>[];

  /// Consecutive-null-parse counter for the silent-failure heuristic
  /// (#1330 phase 3). Incremented from every high-priority PID parse
  /// that returns null; reset to zero the moment any high-priority PID
  /// parses a non-null value. Distinct from [_recentErrors] which
  /// counts *transport-level* failures — silent-failure is the case
  /// where the transport is healthy but the ECU never speaks.
  int _consecutiveNullReads = 0;

  /// Sticky flag so the silent-failure handler only fires once per
  /// recording session. Cleared by [reset] on stop / resume.
  bool _silentFailureFired = false;

  /// Current consecutive-null count. Lets the silent-failure tests
  /// assert "49 nulls did NOT trigger" before the 50th lands.
  int get consecutiveNullReads => _consecutiveNullReads;

  /// Whether the silent-failure threshold has been crossed for this
  /// recording session. Cleared by [reset].
  bool get silentFailureFired => _silentFailureFired;

  /// Record a clean transport read — the only signal strong enough to
  /// clear the error window. ELM327 NO DATA responses come back via
  /// the response string, not an exception, so they don't reach here.
  void registerSuccess() => _recentErrors.clear();

  /// Clear the transport-error window without recording a success.
  /// Called by the controller's drop handler.
  void clearErrorWindow() => _recentErrors.clear();

  /// Register a transport [error] and report whether the controller
  /// should now drop into the paused-due-to-drop state — either
  /// because a typed disconnect was seen, or because
  /// [_dropThreshold] errors landed inside [_dropWindow].
  bool registerTransportError(Object error) {
    final now = _now();
    _recentErrors.add(now);
    // Keep only errors inside the window so the heuristic doesn't
    // count a ten-minute-old blip.
    _recentErrors.removeWhere(
      (ts) => now.difference(ts) > _dropWindow,
    );
    return _isTypedDisconnect(error) ||
        _recentErrors.length >= _dropThreshold;
  }

  /// Observe a high-priority PID parse outcome and report whether the
  /// silent-failure threshold was crossed *for the first time* by this
  /// call. A non-null [parsedValue] resets the counter (we're
  /// detecting "ECU is dead", not "this PID is unsupported") and
  /// returns false. A null value increments the counter; the first
  /// time it reaches [_silentFailureThreshold] this latches
  /// [silentFailureFired] and returns true. Subsequent nulls return
  /// false so the controller doesn't re-fire.
  bool observeHighPriorityParse(Object? parsedValue) {
    if (parsedValue != null) {
      _consecutiveNullReads = 0;
      return false;
    }
    if (_silentFailureFired) return false;
    _consecutiveNullReads++;
    if (_consecutiveNullReads >= _silentFailureThreshold) {
      _silentFailureFired = true;
      return true;
    }
    return false;
  }

  /// Reset the silent-failure latch + counter so a subsequent
  /// recording (or a manual resume followed by another silent
  /// stretch) can fire again. Called on stop / resume.
  void reset() {
    _consecutiveNullReads = 0;
    _silentFailureFired = false;
  }

  bool _isTypedDisconnect(Object error) {
    if (error is Obd2DisconnectedException) return true;
    // The live Bluetooth transport throws `StateError('Transport
    // closed')` once its channel is shut down by the OS / user.
    // Match by message so the controller works against the real
    // implementation without reaching into platform-specific
    // exception types.
    if (error is StateError) {
      final msg = error.message.toLowerCase();
      if (msg.contains('transport closed')) return true;
      if (msg.contains('not connected')) return true;
    }
    return false;
  }
}
