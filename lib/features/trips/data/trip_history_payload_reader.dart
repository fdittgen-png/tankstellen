// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../core/storage/hive_box_mutation_epoch.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';

import '../domain/trip_sample.dart';
import 'trip_history_column_source.dart';
import 'trip_column_chunk.dart';
import 'trip_history_entry.dart';
import 'trip_history_store_v2.dart';

/// On-demand detail I/O; Hive stays on its owning isolate, JSON runs on a worker.
class TripHistoryPayloadReader {
  TripHistoryPayloadReader(this.box);
  final BoxBase<String> box;

  String? readSync(Object key) => (box as Box<String>).get(key);

  List<String> chunksSync(String id) {
    final out = <String>[];
    for (var i = 0; ; i++) {
      final raw = readSync(tripChunkKey(id, i));
      if (raw == null) break;
      out.add(raw);
    }
    return out;
  }

  TripRowsV2 rowsSync(String id, String meta) => TripRowsV2(
    meta: meta,
    chunks: chunksSync(id),
    gpsd: readSync(tripGpsdKey(id)),
  );

  List<TripColumnSource> sourcesSync(Iterable<String> ids) => [
    for (final id in ids)
      if (readSync(id) case final raw? when raw.isNotEmpty)
        (row: raw, chunks: chunksSync(id)),
  ];

  TripColumns columnsSync(String id, Set<String> keys) {
    final raw = readSync(id);
    if (raw == null || raw.isEmpty) return TripColumns.empty;
    return decodeTripColumnSource((row: raw, chunks: chunksSync(id)), keys);
  }

  TripColumns safeColumnsSync(String id, Set<String> keys) {
    try {
      return columnsSync(id, keys);
    } catch (e, st) {
      log.error(
        e,
        st,
        layer: ErrorLayer.storage,
        context: {
          'where': 'TripHistoryRepository.loadColumns $id',
          'entity': id,
        },
      );
      return TripColumns.empty;
    }
  }

  Future<String?> read(Object key) async => box is LazyBox<String>
      ? await (box as LazyBox<String>).get(key)
      : (box as Box<String>).get(key);

  Future<List<String>> chunks(String id) async {
    final out = <String>[];
    for (var i = 0; ; i++) {
      final raw = await read(tripChunkKey(id, i));
      if (raw == null) break;
      out.add(raw);
    }
    return out;
  }

  Future<({TripHistoryEntry entry, bool legacy})?> decode(String id) async {
    final rows = await HiveBoxMutationEpoch.of(box).snapshot(() async {
      final raw = await read(id);
      if (raw == null || raw.isEmpty) return null;
      return TripRowsV2(
        meta: raw,
        chunks: await chunks(id),
        gpsd: await read(tripGpsdKey(id)),
      );
    });
    return rows == null ? null : compute(decodeStoredTripRows, rows);
  }

  Future<List<TripColumnSource>> sources(Iterable<String> ids) =>
      HiveBoxMutationEpoch.of(box).snapshot(() => _sources(ids.toList()));

  Future<List<TripColumnSource>> _sources(List<String> ids) async {
    final out = <TripColumnSource>[];
    for (final id in ids) {
      final raw = await read(id);
      if (raw != null && raw.isNotEmpty) {
        out.add((row: raw, chunks: await chunks(id)));
      }
    }
    return out;
  }

  Future<List<TripSample>> samples(String id, Set<String> keys) async {
    final rows = await sources([id]);
    if (rows.isEmpty) return const [];
    return compute(decodeTripSamples, (source: rows.single, keys: keys));
  }
}

/// Hydrate sequentially so a sync heal does not spawn one worker per trip.
Future<List<TripHistoryEntry>> hydrateTripEntries(
  List<TripHistoryEntry> entries,
  FutureOr<TripHistoryEntry?> Function(String)? loadFull,
) async {
  if (loadFull == null) return entries;
  final result = <TripHistoryEntry>[];
  for (final entry in entries) {
    result.add(await loadFull(entry.id) ?? entry);
  }
  return result;
}
