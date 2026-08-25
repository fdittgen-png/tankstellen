// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// One per-sample GPS-cadence diagnostic record (#1458 phase 2).
///
/// Captured every time the trip recording provider receives a
/// `Geolocator.getPositionStream()` event while a recording is active.
/// Persisted as a sibling list on the trip history entry so the user
/// (or a future "diagnostics" sheet) can inspect the actual sampling
/// cadence after a trip — in particular: did Android keep delivering
/// position updates while the screen was unpinned and the phone went to
/// sleep, or did the OS throttle / pause the stream?
///
/// The recorder DOES NOT touch the user's persisted GPS path data — the
/// existing per-tick [TripSample.latitude]/[TripSample.longitude] keep
/// their semantics. This entity is a strictly additive observation
/// channel: timestamp + lifecycle state + a monotonically increasing
/// index, nothing else.
@immutable
class GpsSampleDiagnostic {
  /// Wall-clock timestamp at the moment the position fix arrived in
  /// the provider's stream listener. Uses the same `DateTime.now()`
  /// source as [TripSample.timestamp] so the two streams can be
  /// cross-referenced post-trip.
  final DateTime timestamp;

  /// Snapshot of the host app's lifecycle state at the time the fix
  /// arrived. Stored as a string (the [AppLifecycleState] enum's
  /// `name`) so the JSON round-trip is stable across SDK upgrades that
  /// might add new states. Known values today: `'resumed'`, `'inactive'`,
  /// `'paused'`, `'detached'`, `'hidden'` (Flutter 3.13+).
  final String lifecycleState;

  /// Monotonically increasing index assigned by the controller's
  /// per-trip counter — first diagnostic in a trip is index 0, second
  /// is index 1, etc. Lets a future diagnostics sheet detect gaps if
  /// the underlying stream skipped fixes (e.g. the OS killed and
  /// restarted the GPS service mid-trip).
  final int index;

  /// #3785 — the FIX clock: the instant the GNSS receiver stamped this
  /// position, as opposed to [timestamp]'s arrival instant.
  ///
  /// Both are needed to tell the two failure shapes apart, and until now
  /// only one was kept — differently on each pipeline, so a trip could
  /// not even be compared with itself:
  ///
  ///  * **the receiver produced nothing** (real signal loss) — fix and
  ///    arrival clocks advance together, both showing the hole;
  ///  * **fixes were produced but delivery stalled** (a saturated
  ///    looper; GMS then coalesces a batch and the platform layer keeps
  ///    only the last one) — the arrival clock jumps while the fix
  ///    clock shows an ordinary cadence, i.e. a SKEW.
  ///
  /// Null on entries recorded before this field existed.
  final DateTime? fixAt;

  const GpsSampleDiagnostic({
    required this.timestamp,
    required this.lifecycleState,
    required this.index,
    this.fixAt,
  });

  /// #3785 — how far this fix's delivery lagged its creation. Null when
  /// the fix clock was not recorded. A steadily-growing skew across a
  /// coverage gap is the positive signature of an app-side stall rather
  /// than lost reception.
  Duration? get deliverySkew =>
      fixAt == null ? null : timestamp.difference(fixAt!);

  /// Compact JSON encoding mirroring the [TripSample] convention
  /// already used by [TripHistoryEntry]: short keys keep per-trip
  /// payload bytes low ('t', 'ls', 'i'). Timestamp goes through
  /// `millisecondsSinceEpoch` for fast parse + lossless round-trip.
  Map<String, dynamic> toJson() => <String, dynamic>{
        't': timestamp.millisecondsSinceEpoch,
        'ls': lifecycleState,
        'i': index,
        // Elided when absent so legacy entries round-trip unchanged.
        if (fixAt != null) 'f': fixAt!.millisecondsSinceEpoch,
      };

  static GpsSampleDiagnostic fromJson(Map<String, dynamic> json) =>
      GpsSampleDiagnostic(
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['t'] as num).toInt(),
        ),
        lifecycleState: json['ls'] as String,
        index: (json['i'] as num).toInt(),
        fixAt: json['f'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((json['f'] as num).toInt()),
      );

  @override
  bool operator ==(Object other) =>
      other is GpsSampleDiagnostic &&
      other.timestamp == timestamp &&
      other.lifecycleState == lifecycleState &&
      other.index == index;

  @override
  int get hashCode => Object.hash(timestamp, lifecycleState, index);

  @override
  String toString() =>
      'GpsSampleDiagnostic(t=$timestamp, ls=$lifecycleState, i=$index)';
}
