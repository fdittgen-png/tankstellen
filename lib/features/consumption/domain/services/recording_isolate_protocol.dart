// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3321 (Epic #3314) — the typed messages that cross the recording-isolate
/// `SendPort` boundary.
///
/// A `SendPort` only carries primitives / Maps / Lists, so every message
/// serialises to a `Map<String, Object?>` tagged with `_t`. This pure codec is
/// the testable heart of the isolate-hosted recording foundation: the UI
/// isolate sends [RecordingIsolateCommand]s down, and the background isolate
/// streams [RecordingFixMessage]s (GPS fixes) back. Keeping it primitive-only
/// (no `TripSample` / Dart object across the port) is what makes it safe to
/// send and trivial to unit-test without spawning an isolate.
library;

/// Control verbs sent UI-isolate → recording isolate.
enum RecordingIsolateCommand { start, stop }

/// A GPS fix streamed recording isolate → UI isolate, as the bare primitives
/// the recorder needs to fold a sample. Mirrors the GPS-only fix shape the
/// [GpsOnlyRecordingPipeline] already builds, but as a port-safe map.
class RecordingFixMessage {
  const RecordingFixMessage({
    required this.epochMs,
    required this.speedKmh,
    this.latitude,
    this.longitude,
    this.altitudeM,
    this.hAccuracyM,
    this.bearingDeg,
  });

  final int epochMs;
  final double speedKmh;
  final double? latitude;
  final double? longitude;
  final double? altitudeM;
  final double? hAccuracyM;
  final double? bearingDeg;

  static const String type = 'fix';

  Map<String, Object?> toMap() => <String, Object?>{
        '_t': type,
        'ts': epochMs,
        'spd': speedKmh,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (altitudeM != null) 'alt': altitudeM,
        if (hAccuracyM != null) 'hac': hAccuracyM,
        if (bearingDeg != null) 'brg': bearingDeg,
      };

  static RecordingFixMessage fromMap(Map<String, Object?> m) =>
      RecordingFixMessage(
        epochMs: (m['ts'] as num).toInt(),
        speedKmh: (m['spd'] as num).toDouble(),
        latitude: (m['lat'] as num?)?.toDouble(),
        longitude: (m['lng'] as num?)?.toDouble(),
        altitudeM: (m['alt'] as num?)?.toDouble(),
        hAccuracyM: (m['hac'] as num?)?.toDouble(),
        bearingDeg: (m['brg'] as num?)?.toDouble(),
      );
}

/// Encode a command as a port-safe map.
Map<String, Object?> encodeRecordingCommand(RecordingIsolateCommand cmd) =>
    <String, Object?>{'_t': 'cmd', 'cmd': cmd.name};

/// Decode a command map, or null if [raw] is not a command.
RecordingIsolateCommand? decodeRecordingCommand(Object? raw) {
  if (raw is! Map) return null;
  if (raw['_t'] != 'cmd') return null;
  final name = raw['cmd'];
  for (final c in RecordingIsolateCommand.values) {
    if (c.name == name) return c;
  }
  return null;
}

/// Decode a fix map, or null if [raw] is not a fix.
RecordingFixMessage? decodeRecordingFix(Object? raw) {
  if (raw is! Map) return null;
  if (raw['_t'] != RecordingFixMessage.type) return null;
  return RecordingFixMessage.fromMap(raw.cast<String, Object?>());
}
