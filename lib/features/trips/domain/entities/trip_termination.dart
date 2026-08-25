// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// WHY a recording session ended (#3795, Epic #3794).
///
/// Until this landed a finished trip carried no record of how it ended:
/// a user tap, an auto-record disconnect, a #797 grace-window
/// auto-finalise and an OS process kill all produced the same silent
/// history row — so a field export could never explain a truncated or
/// missing trip.
///
/// Modelled on the OpenTelemetry error-recording convention: this enum
/// is the LOW-CARDINALITY class (the `error.type` role) and never
/// carries free text, while [TripTermination.detail] holds the
/// supplementary human-readable context (the status-description role)
/// and must not restate the class.
enum TripTerminationReason {
  /// The user tapped End on the recording screen.
  userStopped,

  /// Auto-record's disconnect debounce decided the drive was over.
  autoRecordDisconnect,

  /// #797 — the link never came back and the pause grace window elapsed,
  /// so the partial trip was auto-finalised into history.
  graceWindowExpiry,

  /// The trip-start watchdog aborted before the recording ever ran
  /// (`Obd2AdapterUnresponsive`) — no samples, no trip row.
  watchdogAbort,

  /// Stationary capture discarded at save time (#2509).
  noMovementDiscard,

  /// #3796 — the OS killed or the app crashed while recording; the trip
  /// was rehydrated from the WAL on the next launch. [detail] carries the
  /// `ApplicationExitInfo` reason (`low_memory_kill`, `anr`, `crash`, …)
  /// when the crash-forensics correlation found one.
  recoveredAfterProcessDeath,

  /// A paused-trip row outlived its grace and was swept into history by
  /// [PausedTripRecoveryService] on a later launch.
  recoveredStalePaused,

  /// A WAL snapshot was found but deliberately discarded (already
  /// finalised, or older than the 24 h recovery horizon).
  staleSnapshotDiscarded,

  /// The user discarded the trip from the summary screen.
  userDiscarded,

  /// Genuinely un-attributed. Reachable only for rows written before
  /// #3795 — a test pins that every OTHER value has a production writer.
  unknown,
}

/// The recorded end of a recording session: the low-cardinality
/// [reason] plus optional supplementary [detail].
@immutable
class TripTermination {
  final TripTerminationReason reason;

  /// Supplementary context that does NOT restate [reason] — e.g. the
  /// drop reason held when a grace window expired, or the OS exit reason
  /// behind a process death. Null when the class says everything.
  final String? detail;

  const TripTermination(this.reason, {this.detail});

  /// Compact JSON: the enum by NAME (stable across reorderings — never
  /// the index) plus the optional detail.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'r': reason.name,
        if (detail != null && detail!.isNotEmpty) 'd': detail,
      };

  static TripTermination fromJson(Map<String, dynamic> json) =>
      TripTermination(
        parseReason(json['r'] as String?),
        detail: json['d'] as String?,
      );

  /// Decode by name, degrading to [TripTerminationReason.unknown] for a
  /// value written by a NEWER build (forward compatibility — the same
  /// contract the trip codecs use for additive-optional fields).
  static TripTerminationReason parseReason(String? name) {
    if (name == null) return TripTerminationReason.unknown;
    for (final r in TripTerminationReason.values) {
      if (r.name == name) return r;
    }
    return TripTerminationReason.unknown;
  }

  @override
  bool operator ==(Object other) =>
      other is TripTermination &&
      other.reason == reason &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(reason, detail);

  @override
  String toString() =>
      'TripTermination(${reason.name}${detail == null ? '' : ', $detail'})';
}
