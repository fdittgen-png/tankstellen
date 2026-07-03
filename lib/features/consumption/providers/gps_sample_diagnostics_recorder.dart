// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../domain/entities/gps_sample_diagnostic.dart';

/// Capped per-trip GPS cadence-diagnostics recorder for the dongle-less
/// pipeline (#3253).
///
/// The #1458 diagnostics tool was built precisely for GPS-throttling
/// forensics, but only the OBD2 path recorded it (the notifier's
/// `TripGpsStreamController` feeds `TripRecordingController`'s buffer);
/// [GpsOnlyRecordingPipeline] — the path MOST exposed to OS throttling,
/// since GPS is its only signal — persisted zero diagnostics, so the
/// trip-detail `GpsDiagnosticsCard` never rendered for a GPS-only trip
/// and a "my trace has holes" report was unanswerable. This recorder is
/// the pipeline-side twin of `TripSampleBuffer.recordGpsSampleDiagnostic`
/// (obd2/data — not reachable from here across the feature boundary
/// except through the wide `api.dart`, and it drags the whole sample
/// buffer along; this keeps the concern a ~1-field collaborator).
///
/// One instance per trip (constructed alongside the pipeline), appended
/// per fix, snapshotted into `saveToHistory(gpsSampleDiagnostics:)` at
/// stop, and cleared for the next trip.
class GpsSampleDiagnosticsRecorder {
  /// [lifecycleStateName] is a test seam; production reads the ambient
  /// [WidgetsBinding.instance.lifecycleState] — the same signal the
  /// notifier's `didChangeAppLifecycleState` mirror is fed from, so the
  /// two recording paths report identical foreground/paused labels.
  GpsSampleDiagnosticsRecorder({String Function()? lifecycleStateName})
      : _lifecycleStateName = lifecycleStateName ?? _bindingLifecycleName;

  /// Cap on the diagnostics buffer — mirrors `TripSampleBuffer`'s
  /// #1458 cap: ~33 h at 1 Hz, so it only bites on a forgotten
  /// overnight recording.
  static const int kCap = 120000;

  final String Function() _lifecycleStateName;
  final List<GpsSampleDiagnostic> _entries = <GpsSampleDiagnostic>[];

  /// Monotonic per-trip index. Deliberately NOT `_entries.length`: once
  /// the cap drops the oldest slice the length would re-issue indices,
  /// and the whole point of the `index` field is surfacing such gaps.
  int _nextIndex = 0;

  /// Ambient app lifecycle, resolved lazily per record call. Null before
  /// the first lifecycle event (early startup) — the app is foreground
  /// then, so `resumed` is truthful. A missing binding (a pure-Dart test
  /// driving the pipeline without `TestWidgetsFlutterBinding`) degrades
  /// to the same default rather than derailing the recording hot path —
  /// recording MUST record; the diagnostic label is best-effort.
  static String _bindingLifecycleName() {
    try {
      return (WidgetsBinding.instance.lifecycleState ??
              AppLifecycleState.resumed)
          .name;
    } on Object catch (_) {
      // Uninitialized binding — foreground default, per the doc above.
      return AppLifecycleState.resumed.name;
    }
  }

  /// Append one cadence record at [now] with the current app lifecycle
  /// state. Cheap (one allocation + one append, capped) — safe on the
  /// per-fix hot path.
  void record({required DateTime now}) {
    _entries.add(GpsSampleDiagnostic(
      timestamp: now,
      lifecycleState: _lifecycleStateName(),
      index: _nextIndex++,
    ));
    if (_entries.length > kCap) {
      // Drop the oldest slice — losing the early stretch is preferable
      // to letting a forgotten overnight recording eat unbounded memory.
      _entries.removeRange(0, _entries.length - kCap);
    }
  }

  /// Read-only snapshot for `saveToHistory(gpsSampleDiagnostics:)`.
  List<GpsSampleDiagnostic> get snapshot => List.unmodifiable(_entries);

  /// Reset between trips.
  void clear() {
    _entries.clear();
    _nextIndex = 0;
  }
}
