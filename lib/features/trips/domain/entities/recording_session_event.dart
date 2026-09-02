// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// One typed lifecycle moment of a recording session (#3797, Epic #3794).
///
/// The kinds are deliberately few and low-cardinality so a timeline reads
/// like a state trace rather than prose; the free-text
/// [RecordingSessionEvent.detail] carries the specifics.
enum RecordingSessionEventKind {
  /// The recording started (t = 0 anchor).
  started,

  /// The OBD2 link reached `ready`.
  linkReady,

  /// A drop verdict fired. Detail = the drop reason.
  linkDrop,

  /// The supervisor entered its reconnect ladder.
  linkReconnecting,

  /// The supervisor parked the link as engine-off.
  linkEngineOff,

  /// A quiet-window vehicle-protocol establishment/recovery began (#3783).
  protocolEstablish,

  /// Its verdict. Detail = `answered` / `silent`.
  protocolVerdict,

  /// The trip rebound onto a different `Obd2Service` instance.
  serviceRebound,

  /// PID dispatch was gated off. Detail = cause.
  schedulerPaused,

  /// PID dispatch re-opened.
  schedulerResumed,

  /// OBD2 gone, GPS alive — the trip kept recording GPS-only (#2565).
  degradedGpsOnly,

  /// OBD2 re-attached and full recording resumed.
  leftDegraded,

  /// #3915 — the same `Obd2Service` instance was rebound and dropped
  /// again twice within a minute: the trip refuses it for the rest of
  /// the session and waits for a different one. Detail = the cycle.
  adoptionRefused,

  /// Both sources gone — the visible pause banner with its grace timer.
  pausedDueToDrop,

  /// The #3602 staleness fence escalated (engine values went stale).
  staleEngineFence,

  /// The session ended. Detail = the [TripTerminationReason] name.
  ended,
}

/// A [RecordingSessionEventKind] stamped with its offset from the start
/// of the recording.
///
/// Time is stored as a RELATIVE millisecond offset, not a wall clock:
/// the timeline's whole job is "what happened, in what order, how far
/// into the drive", it stays readable in an export without timezone
/// gymnastics (the 2026-08-25 field debug lost an hour to decoding epoch
/// stamps), and it carries no absolute time that could locate the user.
@immutable
class RecordingSessionEvent {
  final RecordingSessionEventKind kind;

  /// Milliseconds since the recording started. Clamped at 0.
  final int tMs;

  /// Short supplementary context; null when the kind says everything.
  final String? detail;

  const RecordingSessionEvent({
    required this.kind,
    required this.tMs,
    this.detail,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'k': kind.name,
        't': tMs,
        if (detail != null && detail!.isNotEmpty) 'd': detail,
      };

  static RecordingSessionEvent fromJson(Map<String, dynamic> json) =>
      RecordingSessionEvent(
        kind: _parseKind(json['k'] as String?),
        tMs: (json['t'] as num?)?.toInt() ?? 0,
        detail: json['d'] as String?,
      );

  /// Unknown kinds (written by a newer build) degrade to [ended] rather
  /// than throwing — an unreadable timeline is worse than a coarse one.
  static RecordingSessionEventKind _parseKind(String? name) {
    for (final k in RecordingSessionEventKind.values) {
      if (k.name == name) return k;
    }
    return RecordingSessionEventKind.ended;
  }

  @override
  bool operator ==(Object other) =>
      other is RecordingSessionEvent &&
      other.kind == kind &&
      other.tMs == tMs &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, tMs, detail);

  @override
  String toString() =>
      'RecordingSessionEvent(+${tMs}ms ${kind.name}'
      '${detail == null ? '' : ' — $detail'})';
}
