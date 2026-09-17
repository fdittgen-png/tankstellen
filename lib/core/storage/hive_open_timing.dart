// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Which box open is the long pole at startup (#4110).
///
/// `HiveBoxes.init` was one `hive_init` phase in the startup trace, and a
/// field export showed it owning 8,855 ms of an 8,891 ms cold start. The
/// phase is split into sub-phases now, but the box opens inside
/// `hive_open` run in PARALLEL: their durations overlap and do not sum to
/// the phase, so the phase alone can never say which box is slow.
///
/// This answers the narrower, more useful question. The suspicion is
/// `cache`, whose eviction policy counts entries rather than bytes — so a
/// box can look small by entry count and be large on disk, and a large
/// file is what makes an open (and Hive's auto-compaction on it) expensive.
///
/// Its own library because `hive_boxes.dart` is at the 400-line cap, and
/// because "how long did that take" is not what a box registry is for.
abstract final class HiveOpenTiming {
  /// The single box whose open took longest during the last
  /// `HiveBoxes.init`, as `(name, milliseconds)` — null until it has run.
  ///
  /// The opens are parallel, so their durations overlap and do NOT sum to
  /// the `hive_open` phase. This answers a narrower and more useful
  /// question: WHICH box is the long pole. The suspicion is `cache`,
  /// whose eviction policy counts entries rather than bytes, so a box
  /// can look small and be large on disk.
  static (String, int)? get slowest => _slowest;
  static (String, int)? _slowest;

  /// Every box name this wrapper opened, in completion order (#4140).
  ///
  /// The first-frame box set is a startup budget, and #4116 is the
  /// standing proof that a test which reads the batch's SOURCE can pass
  /// while the batch does something else entirely. This makes the set
  /// OBSERVABLE: the gate compares what `openAll` actually opened, not
  /// what its text says it opens.
  static List<String> get openedBoxes => List.unmodifiable(_opened);
  static final List<String> _opened = [];

  /// The phase of an open in the first-frame batch.
  static const String firstFramePhase = 'first_frame';

  /// The phase of an open after the first frame (#4318).
  static const String deferredPhase = 'deferred';

  /// Every timed open, first-frame and deferred, in completion order —
  /// with its duration and the number of values it loaded (#4318).
  ///
  /// [slowest] names the long pole; this is what makes a box that is
  /// GROWING visible before it becomes one. `entries` is what `openBox`
  /// deserialized, and a count that climbs launch over launch is the
  /// #4110 regression announcing itself early. Null when the open failed.
  static List<BoxOpenRecord> get opens => List.unmodifiable(_records);
  static final List<BoxOpenRecord> _records = [];

  /// Forget the recorded long pole and the opened-box lists — test
  /// isolation only.
  @visibleForTesting
  static void reset() {
    _slowest = null;
    _opened.clear();
    _records.clear();
  }

  /// Times [open]. Only [firstFramePhase] opens feed [slowest] and
  /// [openedBoxes] — those answer questions about the batch the first
  /// frame waits for, and a deferred open must not change their meaning.
  static Future<Box<T>> timed<T>(String name, Future<Box<T>> Function() open,
      {String phase = firstFramePhase}) async {
    final sw = Stopwatch()..start();
    Box<T>? box;
    try {
      return box = await open();
    } finally {
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      _records.add((name: name, phase: phase, ms: ms, entries: box?.length));
      if (phase == firstFramePhase) {
        _opened.add(name);
        final current = _slowest;
        if (current == null || ms > current.$2) _slowest = (name, ms);
      }
    }
  }

  /// [opens] as export rows.
  static List<Map<String, Object?>> exportRows() => [
        for (final r in _records)
          {
            'box': r.name,
            'phase': r.phase,
            'durationMs': r.ms,
            if (r.entries != null) 'entries': r.entries,
          },
      ];
}

/// One timed box open (#4318).
typedef BoxOpenRecord = ({String name, String phase, int ms, int? entries});
