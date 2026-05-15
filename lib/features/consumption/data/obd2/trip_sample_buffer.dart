import '../../domain/entities/gps_sample_diagnostic.dart';
import '../../domain/trip_recorder.dart';

/// Owns the two per-trip ring buffers extracted from
/// [TripRecordingController] (#1679):
///
///  * the #1040 captured-sample buffer that feeds the trip-detail
///    charts, decimated to ~1 Hz;
///  * the #1458 GPS cadence-diagnostics buffer.
///
/// Both are append-only, capped, and exposed as unmodifiable lists.
/// The controller delegates capture + read here and clones the
/// snapshots into the persisted [TripHistoryEntry] at stop time.
class TripSampleBuffer {
  /// Cap on the captured-sample buffer (#1040). 120000 samples = 33 h
  /// at 1 Hz — comfortably above any plausible single trip — so this
  /// only kicks in if the user forgets to stop a recording overnight.
  static const int _capturedSampleCap = 120000;

  /// Cap on the GPS diagnostics buffer (#1458 phase 2). At ~1 Hz GPS
  /// fix cadence the cap covers ~33 hours — comfortably above any
  /// plausible single trip and well below the trip-detail JSON
  /// size budget.
  static const int _gpsSampleDiagnosticCap = 120000;

  /// Per-tick sample buffer used by the trip-detail charts (#1040).
  /// Decimated to ~1 Hz by [maybeCapture] — the user-facing charts
  /// don't need the 4 Hz emit cadence, and 1 Hz × 8 fields keeps a
  /// 39-min trip's payload well under 20 KB compressed.
  final List<TripSample> _capturedSamples = <TripSample>[];

  /// Timestamp of the most recently *captured* (decimated) sample.
  DateTime? _lastCapturedAt;

  /// Per-trip GPS cadence diagnostics buffer (#1458 phase 2).
  final List<GpsSampleDiagnostic> _gpsSampleDiagnostics =
      <GpsSampleDiagnostic>[];

  /// Read-only snapshot of the captured sample buffer (#1040). The
  /// list is unmodifiable so callers can't accidentally mutate the
  /// buffer's state.
  List<TripSample> get capturedSamples => List.unmodifiable(_capturedSamples);

  /// Read-only snapshot of the GPS cadence diagnostics buffer
  /// (#1458 phase 2). Unmodifiable for the same reason.
  List<GpsSampleDiagnostic> get capturedGpsSampleDiagnostics =>
      List.unmodifiable(_gpsSampleDiagnostics);

  /// Append [sample] to the captured-samples buffer when at least
  /// 1 second has elapsed since the previous capture. The 4 Hz emit
  /// loop drops 3 of every 4 candidate samples — the chart layer
  /// renders at 1 Hz and the storage budget is sized for that
  /// cadence (#1040).
  void maybeCapture(TripSample sample) {
    final last = _lastCapturedAt;
    if (last != null) {
      // Use 950 ms as the gate so a 1 Hz scheduler that's slightly
      // jittered (998 ms / 1003 ms) still captures every tick. Without
      // the slack a 998 ms gap would slip through the >=1000 check
      // and we'd silently halve the captured rate.
      if (sample.timestamp.difference(last).inMilliseconds < 950) return;
    }
    _capturedSamples.add(sample);
    _lastCapturedAt = sample.timestamp;
    if (_capturedSamples.length > _capturedSampleCap) {
      // Drop the oldest slice — losing the early stretch is preferable
      // to letting a forgotten overnight recording eat unbounded memory.
      _capturedSamples.removeRange(
        0,
        _capturedSamples.length - _capturedSampleCap,
      );
    }
  }

  /// Append a sample to the captured-samples buffer without the
  /// 950 ms decimation gate. Used by tests to populate a deterministic
  /// buffer (#1040).
  void debugCaptureSample(TripSample sample) {
    _capturedSamples.add(sample);
    _lastCapturedAt = sample.timestamp;
  }

  /// #1458 phase 2 — append one cadence-diagnostic record at [now]
  /// with the given app [lifecycleState].
  ///
  /// The index assigned to the diagnostic is the buffer's length at
  /// insertion time so it is monotonic per trip and stable across
  /// process restarts (a forgotten recording that bumps into
  /// [_gpsSampleDiagnosticCap] drops the OLDEST samples first — the
  /// `index` field surfaces those gaps).
  void recordGpsSampleDiagnostic({
    required DateTime now,
    required String lifecycleState,
  }) {
    final entry = GpsSampleDiagnostic(
      timestamp: now,
      lifecycleState: lifecycleState,
      index: _gpsSampleDiagnostics.length,
    );
    _gpsSampleDiagnostics.add(entry);
    if (_gpsSampleDiagnostics.length > _gpsSampleDiagnosticCap) {
      // Drop the oldest slice — losing the early stretch is preferable
      // to letting a forgotten overnight recording eat unbounded memory.
      _gpsSampleDiagnostics.removeRange(
        0,
        _gpsSampleDiagnostics.length - _gpsSampleDiagnosticCap,
      );
    }
  }

  /// Append a cadence diagnostic without going through
  /// [recordGpsSampleDiagnostic]. Used by tests to pre-seed a buffer.
  void debugCaptureGpsSampleDiagnostic(GpsSampleDiagnostic diagnostic) {
    _gpsSampleDiagnostics.add(diagnostic);
  }
}
