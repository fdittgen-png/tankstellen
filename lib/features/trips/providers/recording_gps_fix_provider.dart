// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/error_logger.dart';
import 'trip_recording_provider.dart';

/// The most recent GPS fix of the running recording, as the recording
/// screen's GPS status chip sees it (#3916, Epic #3914).
///
/// Both recording pipelines already receive every fix (the OBD2 trip's
/// `TripGpsStreamController` and the dongle-less
/// `GpsOnlyRecordingPipeline`) and persist its horizontal accuracy onto
/// the `TripSample` — but nothing surfaced it LIVE. This is the additive
/// seam: each pipeline tees the fix instant + accuracy in here, and the
/// derived `recordingLinkStatusProvider` turns it into the precise /
/// approximate / no-fix chip state and the coverage-so-far percentage.
@immutable
class RecordingGpsFix {
  const RecordingGpsFix({
    required this.fixAt,
    required this.firstFixAt,
    required this.fixCount,
    this.accuracyM,
  });

  /// The receiver's own timestamp of the latest fix (never the arrival
  /// clock — the #3253 lesson: Android batches deliveries).
  final DateTime fixAt;

  /// The first fix of this recording, for the coverage-so-far ratio.
  final DateTime firstFixAt;

  /// Fixes received since [firstFixAt] (inclusive).
  final int fixCount;

  /// Horizontal accuracy radius of the latest fix in metres, null when
  /// the platform reported none.
  final double? accuracyM;

  /// How long a recording must have run before the coverage ratio is
  /// shown — a one-fix trip would read "100 %" without meaning.
  static const Duration minCoverageSpan = Duration(seconds: 10);

  /// Coverage so far as a whole percentage: fixes received per elapsed
  /// second since the first fix (the recording asks for a 1 Hz cadence
  /// on both platforms), clamped to 0..100. Null until
  /// [minCoverageSpan] has elapsed.
  int? get coveragePercent {
    final span = fixAt.difference(firstFixAt);
    if (span < minCoverageSpan) return null;
    final seconds = span.inMilliseconds / 1000.0 + 1.0;
    return (fixCount / seconds * 100.0).clamp(0.0, 100.0).round();
  }

  @override
  bool operator ==(Object other) =>
      other is RecordingGpsFix &&
      other.fixAt == fixAt &&
      other.firstFixAt == firstFixAt &&
      other.fixCount == fixCount &&
      other.accuracyM == accuracyM;

  @override
  int get hashCode => Object.hash(fixAt, firstFixAt, fixCount, accuracyM);
}

/// Keeps the latest [RecordingGpsFix] of the running recording, fed on
/// every fix by both pipelines through [teeRecordingGpsFix]. Resets
/// itself when a recording starts (the phase leaves idle for connecting
/// / recording), so neither pipeline carries trip-start plumbing. Not
/// persisted; nothing to dispose.
class RecordingGpsFixTracker extends Notifier<RecordingGpsFix?> {
  @override
  RecordingGpsFix? build() {
    ref.listen<TripRecordingPhase>(
      tripRecordingProvider.select((s) => s.phase),
      (previous, next) {
        if (_isStarting(next) && !_isStarting(previous)) reset();
      },
    );
    return null;
  }

  static bool _isStarting(TripRecordingPhase? phase) =>
      phase == TripRecordingPhase.connecting ||
      phase == TripRecordingPhase.recording;

  /// Record one fix. [fixAt] is the receiver's own stamp; [accuracyM]
  /// the horizontal accuracy radius (already isFinite-guarded by the
  /// caller, like the persisted sample's `hAccuracyM`).
  void onFix({required DateTime fixAt, double? accuracyM}) {
    final prev = state;
    state = RecordingGpsFix(
      fixAt: fixAt,
      firstFixAt: prev?.firstFixAt ?? fixAt,
      fixCount: (prev?.fixCount ?? 0) + 1,
      accuracyM: accuracyM,
    );
  }

  /// Forget the previous trip's fixes. Called at trip start.
  void reset() => state = null;
}

/// The latest fix of the running recording, or null before the first
/// fix (and between trips).
final recordingGpsFixProvider =
    NotifierProvider<RecordingGpsFixTracker, RecordingGpsFix?>(
  RecordingGpsFixTracker.new,
);

/// Tee one fix into [recordingGpsFixProvider] from a position listener.
/// A failure (a test container without the provider graph, a disposed
/// ref) is caught and error-logged so the listener keeps recording;
/// [where] tags the log. [accuracyM] must already be isFinite-guarded,
/// like the persisted sample's `hAccuracyM`.
void teeRecordingGpsFix(
  Ref ref, {
  required DateTime fixAt,
  required double? accuracyM,
  required String where,
}) {
  try {
    ref
        .read(recordingGpsFixProvider.notifier)
        .onFix(fixAt: fixAt, accuracyM: accuracyM);
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st,
        context: {'where': where}));
  }
}
