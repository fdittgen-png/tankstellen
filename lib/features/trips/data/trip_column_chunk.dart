// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/trip_sample.dart';
import 'trip_sample_codec.dart';

/// #3882 — the columnar on-disk chunk of a trip's samples (trip detail v2).
///
/// A chunk holds up to [kTripChunkSamples] consecutive samples (5 min at
/// 1 Hz) as per-column arrays instead of one map per sample: the 34
/// compact keys of [sampleToJson] are written once per chunk, timestamps
/// are delta-encoded, and a column is present only when at least one
/// sample carries it. The per-sample codec stays the single source of
/// truth for keys and values — a chunk is exactly the transpose of
/// `samples.map(sampleToJson)`, so [decode] ∘ [encode] round-trips to the
/// same `sampleToJson` maps (pinned by test).
///
/// Wire shape:
/// ```json
/// {"v": 2, "n": 300, "t0": 1756456800000,
///  "t": [0, 1000, 1000, ...],            // ms deltas from the previous
///  "c": {"s": [..], "r": [.., null, ..]}} // one array per present column
/// ```
const int kTripChunkSamples = 300;

/// Column keys of the sample codec that carry a value in a sample set —
/// the same strings [sampleToJson] emits (`s`, `r`, `f`, `la`, …).
Set<String> presentSampleColumns(Iterable<TripSample> samples) {
  final cols = <String>{};
  for (final s in samples) {
    for (final k in sampleToJson(s).keys) {
      if (k != 't') cols.add(k);
    }
  }
  return cols;
}

/// Encode [samples] (any count ≤ [kTripChunkSamples]) into one chunk map.
Map<String, dynamic> encodeTripChunk(List<TripSample> samples) =>
    encodeTripChunkFromMaps(samples.map(sampleToJson).toList(growable: false));

/// Encode already-serialised sample maps (what [sampleToJson] emits).
Map<String, dynamic> encodeTripChunkFromMaps(List<Map<String, dynamic>> maps) {
  final n = maps.length;
  final cols = <String>{};
  for (final m in maps) {
    cols.addAll(m.keys);
  }
  cols.remove('t');
  final t0 = n == 0 ? 0 : (maps.first['t'] as int);
  final deltas = <int>[];
  var prev = t0;
  for (final m in maps) {
    final t = m['t'] as int;
    deltas.add(t - prev);
    prev = t;
  }
  final columns = <String, List<dynamic>>{
    for (final c in cols) c: [for (final m in maps) m[c]],
  };
  return {'v': 2, 'n': n, 't0': t0, 't': deltas, 'c': columns};
}

/// Decode one chunk map back into the per-sample codec maps (each map is
/// exactly what [sampleToJson] would have produced) — the cheap path for
/// readers that transpose columns themselves.
List<Map<String, dynamic>> decodeTripChunkMaps(Map<String, dynamic> chunk) {
  final n = chunk['n'] as int;
  final deltas = (chunk['t'] as List).cast<num>();
  final columns = (chunk['c'] as Map).cast<String, dynamic>();
  var t = (chunk['t0'] as num).toInt();
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < n; i++) {
    t += deltas[i].toInt();
    final m = <String, dynamic>{'t': t};
    for (final e in columns.entries) {
      final v = (e.value as List)[i];
      if (v != null) m[e.key] = v;
    }
    out.add(m);
  }
  return out;
}

/// Decode one chunk map into samples.
List<TripSample> decodeTripChunk(Map<String, dynamic> chunk) =>
    decodeTripChunkMaps(chunk).map(sampleFromJson).toList(growable: false);

/// A column-selective read of a chunk: timestamps plus only [keys].
/// Missing columns come back as all-null.
TripColumns decodeTripChunkColumns(
    Map<String, dynamic> chunk, Set<String> keys) {
  final n = chunk['n'] as int;
  final deltas = (chunk['t'] as List).cast<num>();
  final columns = (chunk['c'] as Map).cast<String, dynamic>();
  var t = (chunk['t0'] as num).toInt();
  final ts = List<int>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    t += deltas[i].toInt();
    ts[i] = t;
  }
  return TripColumns(
    timestampsMs: ts,
    values: {
      for (final k in keys)
        k: columns[k] == null
            ? List<double?>.filled(n, null)
            : (columns[k] as List)
                .map((v) => v is num ? v.toDouble() : null)
                .toList(growable: false),
    },
  );
}

/// Column-oriented sample data (#3882): parallel arrays, one per key.
class TripColumns {
  const TripColumns({required this.timestampsMs, required this.values});

  final List<int> timestampsMs;
  final Map<String, List<double?>> values;

  int get length => timestampsMs.length;

  /// Concatenate consecutive chunks' columns.
  TripColumns append(TripColumns other) => TripColumns(
        timestampsMs: [...timestampsMs, ...other.timestampsMs],
        values: {
          for (final k in {...values.keys, ...other.values.keys})
            k: [
              ...(values[k] ?? List<double?>.filled(length, null)),
              ...(other.values[k] ?? List<double?>.filled(other.length, null)),
            ],
        },
      );

  static const TripColumns empty = TripColumns(timestampsMs: [], values: {});
}
