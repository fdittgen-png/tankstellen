// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'startup_timer.dart';

/// One slow frame kept by [JankFrameRecorder] (#4546).
@immutable
class JankFrame {
  const JankFrame({
    required this.totalMs,
    required this.buildMs,
    required this.rasterMs,
    required this.atMs,
  });

  /// Vsync start to raster finish — what the user waited for.
  final int totalMs;

  /// UI-thread build (+ layout/paint) time.
  final int buildMs;

  /// Raster-thread time.
  final int rasterMs;

  /// Milliseconds since launch when the frame was REPORTED. The engine
  /// batches timings (about every 100 ms in release, 1 s in debug), so
  /// this can trail the frame itself by up to one batch.
  final int atMs;

  Map<String, Object?> toJson() => {
        'totalMs': totalMs,
        'buildMs': buildMs,
        'rasterMs': rasterMs,
        'atMs': atMs,
      };
}

/// A bounded ring of the worst frames of the first minutes after launch
/// (#4546).
///
/// The maintainer reported repeated freezes at and after launch that no
/// export could show: nothing in the app observed `FrameTiming`. [arm]
/// registers a timings callback after the first frame, keeps the
/// [capacity] slowest frames by [JankFrame.totalMs], and unregisters
/// itself once [window] has elapsed — so the cost is bounded in both
/// memory and time. The rows travel in the startup-trace export as
/// `jankFrames`, and their `atMs` lines up with the trace's spans.
class JankFrameRecorder {
  JankFrameRecorder({
    required int Function() elapsedMs,
    this.capacity = 20,
    this.window = const Duration(minutes: 3),
  }) : _elapsedMs = elapsedMs; // ignore: prefer_initializing_formals

  /// The app-wide recorder, on the startup trace's clock.
  static final JankFrameRecorder instance =
      JankFrameRecorder(elapsedMs: StartupTimer.instance.elapsedMsNow);

  /// How many frames are kept.
  final int capacity;

  /// How long after [arm] frames are observed.
  final Duration window;

  final int Function() _elapsedMs;
  final List<JankFrame> _worst = [];
  SchedulerBinding? _binding;
  int? _armedAtMs;
  bool _done = false;

  /// The kept frames, worst first.
  List<JankFrame> get frames => List.unmodifiable(_worst);

  /// Whether the timings callback is currently registered.
  bool get isListening => _binding != null;

  /// [frames] as export rows.
  List<Map<String, Object?>> exportRows() =>
      [for (final f in _worst) f.toJson()];

  /// Starts observing frame timings. Idempotent; a recorder whose window
  /// has closed never re-arms.
  void arm([SchedulerBinding? binding]) {
    if (_done || _binding != null) return;
    final b = binding ?? SchedulerBinding.instance;
    _armedAtMs = _elapsedMs();
    _binding = b;
    b.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      record(
        totalMs: t.totalSpan.inMilliseconds,
        buildMs: t.buildDuration.inMilliseconds,
        rasterMs: t.rasterDuration.inMilliseconds,
      );
    }
  }

  /// Folds one frame into the ring — or, once [window] has elapsed since
  /// [arm], drops it and unregisters. Public for tests, which drive it
  /// without an engine.
  @visibleForTesting
  void record({
    required int totalMs,
    required int buildMs,
    required int rasterMs,
  }) {
    if (_done) return;
    final now = _elapsedMs();
    final armedAt = _armedAtMs;
    if (armedAt != null && now - armedAt >= window.inMilliseconds) {
      _stop();
      return;
    }
    final frame = JankFrame(
        totalMs: totalMs, buildMs: buildMs, rasterMs: rasterMs, atMs: now);
    if (_worst.length < capacity) {
      _worst.add(frame);
    } else if (totalMs > _worst.last.totalMs) {
      _worst[_worst.length - 1] = frame;
    }
    _worst.sort((a, b) => b.totalMs.compareTo(a.totalMs));
  }

  void _stop() {
    _done = true;
    _binding?.removeTimingsCallback(_onTimings);
    _binding = null;
  }

  /// Test isolation only.
  @visibleForTesting
  void reset() {
    _binding?.removeTimingsCallback(_onTimings);
    _binding = null;
    _armedAtMs = null;
    _done = false;
    _worst.clear();
  }
}
