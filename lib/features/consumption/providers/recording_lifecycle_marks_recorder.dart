// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../domain/entities/recording_lifecycle_mark.dart';

/// Rolling recorder of foreground↔background transitions for the GPS
/// coverage report (#3465).
///
/// Owned by the [TripRecording] notifier — the single point BOTH recording
/// pipelines (OBD2 [Obd2RecordingPipeline] and dongle-less
/// [GpsOnlyRecordingPipeline]) save through, and the notifier already
/// receives EVERY lifecycle transition (paused AND resumed) via
/// `onAppLifecycleStateChanged` from `TankstellenApp`'s
/// [WidgetsBindingObserver] (#1458 phase 2). Recording here instead of
/// per-pipeline keeps the two at-cap pipeline files untouched and
/// guarantees the two paths can never diverge.
///
/// The buffer records CONTINUOUSLY (a lifecycle transition is rare and one
/// append is cheap) and is windowed to `[tripStart, tripEnd]` at
/// save time via [marksForWindow] — so no per-trip clear hook is needed on
/// any of the several trip-start paths (manual, GPS-only, auto-record).
///
/// Never throws: pure list bookkeeping, no I/O, no platform channels —
/// safe on the lifecycle hot path that must never take recording down.
class RecordingLifecycleMarksRecorder {
  /// Cap on the rolling transition buffer. 256 transitions is days of
  /// aggressive app-switching; the oldest half predates any trip that
  /// could still be saved, so dropping it is lossless in practice.
  static const int kCap = 256;

  final List<RecordingLifecycleMark> _marks = <RecordingLifecycleMark>[];

  /// Fold one lifecycle transition into the buffer.
  ///
  ///  * `paused` / `hidden` / `detached` → a BACKGROUNDED mark.
  ///  * `resumed` → a FOREGROUNDED mark.
  ///  * `inactive` → ignored: it fires on every transient interruption
  ///    (permission dialog, notification shade, app switcher peek) and
  ///    would spray meaningless flip-flops; the definitive `paused` or
  ///    `resumed` always follows.
  ///
  /// Consecutive same-direction transitions are deduped so the buffer
  /// holds real state CHANGES only. [at] is a test seam; production uses
  /// the wall clock.
  void onLifecycleState(AppLifecycleState state, {DateTime? at}) {
    final bool backgrounded;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        backgrounded = true;
      case AppLifecycleState.resumed:
        backgrounded = false;
      case AppLifecycleState.inactive:
        return;
    }
    if (_marks.isNotEmpty && _marks.last.backgrounded == backgrounded) {
      return;
    }
    _marks.add(RecordingLifecycleMark(
      at: at ?? DateTime.now(),
      backgrounded: backgrounded,
    ));
    if (_marks.length > kCap) {
      _marks.removeRange(0, _marks.length - kCap);
    }
  }

  /// The marks relevant to a trip recorded over `[start, end]`:
  ///
  ///  * a LEADING mark clamped to [start] carrying the state the trip
  ///    began in (the last transition at or before [start]; when no
  ///    transition was ever observed the app never left the foreground —
  ///    Flutter apps launch `resumed` — so the anchor is foregrounded);
  ///  * every transition strictly inside `(start, end]`.
  ///
  /// The leading anchor means a persisted trip ALWAYS carries ≥ 1 mark,
  /// which is how [GpsCoverageReport] distinguishes "provably foreground"
  /// (signalLoss is possible) from a legacy trip with no marks at all
  /// (unknown). Returns an unmodifiable list; never throws.
  List<RecordingLifecycleMark> marksForWindow(DateTime start, DateTime end) {
    var leadingBackgrounded = false;
    final inWindow = <RecordingLifecycleMark>[];
    for (final m in _marks) {
      if (!m.at.isAfter(start)) {
        leadingBackgrounded = m.backgrounded;
      } else if (!m.at.isAfter(end)) {
        inWindow.add(m);
      }
    }
    final result = <RecordingLifecycleMark>[
      RecordingLifecycleMark(at: start, backgrounded: leadingBackgrounded),
    ];
    for (final m in inWindow) {
      // The clamp can create a same-direction neighbour; keep changes only.
      if (m.backgrounded != result.last.backgrounded) result.add(m);
    }
    return List.unmodifiable(result);
  }

  /// Read-only view of the raw rolling buffer (tests).
  @visibleForTesting
  List<RecordingLifecycleMark> get debugMarks => List.unmodifiable(_marks);
}
