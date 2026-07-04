// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// One timestamped foreground/background transition observed while a trip
/// was recording (#3465).
///
/// Recorded by [RecordingLifecycleMarksRecorder] from the same
/// app-lifecycle wiring that feeds the #1458 GPS cadence diagnostics
/// (`TankstellenApp.didChangeAppLifecycleState` →
/// `TripRecording.onAppLifecycleStateChanged`), then windowed to the trip
/// and persisted on the [TripHistoryEntry] so the post-hoc
/// [GpsCoverageReport] can tell whether a GPS track gap fell inside a
/// backgrounded stretch — the discriminator between "the OS throttled the
/// backgrounded stream (no FGS build)" and "the sky went away".
///
/// A tiny list per trip: one entry per foreground↔background TRANSITION
/// (deduped, `inactive` flickers ignored), not per fix — no schema risk.
@immutable
class RecordingLifecycleMark {
  /// Wall-clock time of the transition (or of the trip start for the
  /// leading clamped mark that anchors the state the trip began in).
  final DateTime at;

  /// True when the app moved INTO the background at [at] (`paused` /
  /// `hidden` / `detached`); false when it returned to the foreground
  /// (`resumed`). Transient `inactive` blips (permission dialogs,
  /// notification shades) are never recorded as marks.
  final bool backgrounded;

  const RecordingLifecycleMark({required this.at, required this.backgrounded});

  /// Compact JSON encoding mirroring [GpsSampleDiagnostic]: short keys
  /// ('t', 'bg'), timestamp via `millisecondsSinceEpoch` for a lossless
  /// round-trip.
  Map<String, dynamic> toJson() => <String, dynamic>{
        't': at.millisecondsSinceEpoch,
        'bg': backgrounded,
      };

  static RecordingLifecycleMark fromJson(Map<String, dynamic> json) =>
      RecordingLifecycleMark(
        at: DateTime.fromMillisecondsSinceEpoch((json['t'] as num).toInt()),
        backgrounded: (json['bg'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is RecordingLifecycleMark &&
      other.at == at &&
      other.backgrounded == backgrounded;

  @override
  int get hashCode => Object.hash(at, backgrounded);

  @override
  String toString() => 'RecordingLifecycleMark(at=$at, bg=$backgrounded)';
}
