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

  /// Forget the recorded long pole — test isolation only.
  @visibleForTesting
  static void reset() => _slowest = null;

  static Future<Box<T>> timed<T>(
      String name, Future<Box<T>> Function() open) async {
    final sw = Stopwatch()..start();
    try {
      return await open();
    } finally {
      sw.stop();
      final current = _slowest;
      if (current == null || sw.elapsedMilliseconds > current.$2) {
        _slowest = (name, sw.elapsedMilliseconds);
      }
    }
  }
}
