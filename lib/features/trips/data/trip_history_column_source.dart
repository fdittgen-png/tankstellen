// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'trip_column_chunk.dart';
import 'trip_history_store_v2.dart';
import 'trip_sample_codec.dart';
import '../domain/trip_sample.dart';

/// One trip's raw rows: its main row (v2 meta or a legacy v1 blob) and its
/// v2 chunk rows. Plain strings, so it crosses an isolate boundary.
typedef TripColumnSource = ({String row, List<String> chunks});

List<TripSample> decodeTripSamples(
  ({TripColumnSource source, Set<String> keys}) input,
) => samplesFromColumns(
  decodeTripColumnSource(input.source, input.keys),
  input.keys,
);

/// The [keys] columns of one trip from its raw rows. A legacy row decodes
/// fully and is projected. Pure — safe on a worker isolate.
TripColumns decodeTripColumnSource(TripColumnSource src, Set<String> keys) {
  final json = (jsonDecode(src.row) as Map).cast<String, dynamic>();
  if (json['v'] == kTripRowVersion) {
    return decodeTripColumnsV2(src.chunks, keys);
  }
  final samples =
      (json['samples'] as List?)
          ?.map((e) => (e as Map).cast<String, dynamic>())
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];
  return decodeTripChunkColumns(encodeTripChunkFromMaps(samples), keys);
}

/// Light samples carrying only [keys] (plus timestamps) from [cols].
List<TripSample> samplesFromColumns(TripColumns cols, Set<String> keys) => [
  for (var i = 0; i < cols.length; i++)
    sampleFromJson({
      't': cols.timestampsMs[i],
      's': cols.values['s']?[i] ?? 0.0,
      for (final k in keys)
        if (k != 's' && cols.values[k]?[i] != null) k: cols.values[k]![i],
    }),
];
