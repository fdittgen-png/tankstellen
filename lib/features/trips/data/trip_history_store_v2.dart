// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'trip_column_chunk.dart';
import 'trip_history_entry.dart';
import 'trip_history_entry_columns.dart';

/// #3882 — the v2 on-disk layout of a trip inside `obd2_trip_history`.
///
/// One trip = a **meta row** under `<id>` (everything `toJson` emits except
/// `samples` / `gpsd`, plus `v: 2`, `sc` = sample count and `cols` = the
/// sample columns that carry a value) + **chunk rows** under
/// `<id>::chunk::<n>` (columnar, ≤ 300 samples each) + one diagnostics row
/// under `<id>::gpsd`. The summary list decodes meta rows only; the detail
/// screen decodes chunks in an isolate; column-selective readers decode
/// only the arrays they need. `TripHistoryEntry.toJson()` — the export /
/// TankSync wire shape — is untouched: v2 is purely how the box stores it.
///
/// Every function here is top-level and pure (no Hive, no plugins) so it
/// can run under `compute()`.
const int kTripRowVersion = 2;

const String _chunkMarker = '::chunk::';
const String _gpsdMarker = '::gpsd';

String tripChunkKey(String id, int index) => '$id$_chunkMarker$index';
String tripGpsdKey(String id) => '$id$_gpsdMarker';

/// True for a chunk / diagnostics sidecar key (never for a trip id —
/// ids are ISO timestamps, optionally `#`-suffixed by the ghost de-dupe).
bool isTripSidecarKey(Object? key) =>
    key is String && (key.contains(_chunkMarker) || key.endsWith(_gpsdMarker));

/// The trip id a sidecar key belongs to (or the key itself for a meta row).
String tripIdOfKey(String key) {
  final c = key.indexOf(_chunkMarker);
  if (c >= 0) return key.substring(0, c);
  if (key.endsWith(_gpsdMarker)) {
    return key.substring(0, key.length - _gpsdMarker.length);
  }
  return key;
}

/// Split one `toJson()` map into the v2 rows: `{key: encodedJson}`.
Map<String, String> encodeTripRowsV2(Map<String, dynamic> json) {
  final id = json['id'] as String;
  final meta = Map<String, dynamic>.of(json);
  final samples =
      (meta.remove('samples') as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
  final gpsd = meta.remove('gpsd') as List?;
  final cols = <String>{};
  for (final m in samples) {
    cols.addAll(m.keys);
  }
  cols.remove('t');
  meta['v'] = kTripRowVersion;
  meta['sc'] = samples.length;
  meta['cols'] = cols.toList(growable: false)..sort();
  final rows = <String, String>{id: jsonEncode(meta)};
  for (var i = 0, n = 0; i < samples.length; i += kTripChunkSamples, n++) {
    final end = i + kTripChunkSamples;
    rows[tripChunkKey(id, n)] = jsonEncode(encodeTripChunkFromMaps(
        samples.sublist(i, end > samples.length ? samples.length : end)));
  }
  if (gpsd != null && gpsd.isNotEmpty) {
    rows[tripGpsdKey(id)] = jsonEncode(gpsd);
  }
  return rows;
}

/// The raw strings of one v2 trip, read from the box by the repository.
class TripRowsV2 {
  const TripRowsV2({required this.meta, required this.chunks, this.gpsd});
  final String meta;
  final List<String> chunks;
  final String? gpsd;
}

/// Re-assemble the full `toJson()`-shaped map from v2 rows.
Map<String, dynamic> decodeTripRowsV2(TripRowsV2 rows) {
  final json = (jsonDecode(rows.meta) as Map).cast<String, dynamic>();
  json
    ..remove('v')
    ..remove('sc')
    ..remove('cols');
  final samples = <Map<String, dynamic>>[];
  for (final c in rows.chunks) {
    samples.addAll(
        decodeTripChunkMaps((jsonDecode(c) as Map).cast<String, dynamic>()));
  }
  if (samples.isNotEmpty) json['samples'] = samples;
  final gpsd = rows.gpsd;
  if (gpsd != null) json['gpsd'] = jsonDecode(gpsd);
  return json;
}

/// Full entry from v2 rows — `compute()` entry point (objects cross the
/// isolate boundary, the JSON strings never come back).
TripHistoryEntry decodeTripRowsV2ToEntry(TripRowsV2 rows) {
  final cols = (jsonDecode(rows.meta) as Map)['cols'];
  return TripHistoryEntry.fromJson(decodeTripRowsV2(rows)).withColumnsPresent(
      (cols as List?)?.cast<String>().toSet());
}

/// Full entry from a legacy v1 row — `compute()` entry point.
TripHistoryEntry decodeLegacyRowToEntry(String raw) =>
    TripHistoryEntry.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());

/// Column-selective read over v2 chunk strings.
TripColumns decodeTripColumnsV2(List<String> chunks, Set<String> keys) {
  var out = TripColumns.empty;
  for (final c in chunks) {
    out = out.append(decodeTripChunkColumns(
        (jsonDecode(c) as Map).cast<String, dynamic>(), keys));
  }
  return out;
}
