// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'hive_box_mutation_epoch.dart';

/// Small, rebuildable metadata view over the encrypted lazy trip box (#4504).
/// Payload rows remain owned by Hive on the main isolate and are read only
/// when requested. No second file or migration marker can diverge from them.
class HiveTripHistoryIndex {
  HiveTripHistoryIndex._(this.box);

  final LazyBox<String> box;
  final Map<String, String> _metadata = {};
  HiveBoxMutationEpoch get epoch => HiveBoxMutationEpoch.of(box);
  static final _indices = Expando<HiveTripHistoryIndex>();
  static final _preparations = Expando<Future<void>>();
  static final _readiness = ValueNotifier<int>(0);
  static ValueListenable<int> get readiness => _readiness;

  static bool isReady(LazyBox<String> box) => _indices[box] != null;

  static HiveTripHistoryIndex of(LazyBox<String> box) =>
      _indices[box] ?? (throw StateError('Trip metadata is not ready'));

  /// Reads only main rows, one at a time; legacy JSON projection runs off
  /// the UI isolate. A failed open leaves the canonical encrypted file intact.
  static Future<void> prepare(LazyBox<String> box) =>
      _preparations[box] ??= _prepare(box);

  static Future<void> _prepare(LazyBox<String> box) async {
    final index = HiveTripHistoryIndex._(box);
    for (final key in box.keys.whereType<String>().toList()) {
      if (isMetadataKey(key)) {
        final raw = await box.get(key);
        if (raw != null) {
          index._metadata[key] = await compute(_compactMetadata, raw);
        }
      }
    }
    index._metadata.removeWhere((key, _) => !box.containsKey(key));
    _indices[box] = index;
    _readiness.value++;
  }

  static bool isMetadataKey(Object? key) =>
      key is String && !key.contains('::chunk::') && !key.endsWith('::gpsd');

  String? get(Object key) => _metadata[key];

  /// Update the index after the canonical write succeeds. Unknown/corrupt
  /// JSON stays readable by the repository's existing skip-and-log path.
  Future<void> putAll(Map<dynamic, String> rows) async {
    await epoch.mutate(() => box.putAll(rows));
    for (final key in rows.keys.whereType<String>().where(isMetadataKey)) {
      await _refresh(key);
    }
  }

  Future<void> _refresh(String key) async {
    for (
      var attempt = 0;
      attempt < HiveBoxMutationEpoch.maxSnapshotAttempts;
      attempt++
    ) {
      final generation = epoch.generation;
      final raw = await box.get(key);
      final projected = raw == null
          ? null
          : await compute(_compactMetadata, raw);
      if (generation != epoch.generation) continue;
      if (projected == null) {
        _metadata.remove(key);
      } else {
        _metadata[key] = projected;
      }
      return;
    }
    throw StateError('Trip metadata changed during projection');
  }

  Future<void> deleteAll(Iterable<dynamic> keys) async {
    final snapshot = keys.toList();
    await epoch.mutate(() => box.deleteAll(snapshot));
    for (final key in snapshot.whereType<String>().where(isMetadataKey)) {
      await _refresh(key);
    }
  }

  Future<void> clear() async {
    final keys = _metadata.keys.toSet();
    await epoch.mutate(() async {
      await box.clear();
    });
    keys.addAll(box.keys.whereType<String>().where(isMetadataKey));
    for (final key in keys) {
      await _refresh(key);
    }
  }
}

String _compactMetadata(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return raw;
    final json = decoded;
    final samples = json.remove('samples');
    if (samples is List) json['sc'] = samples.length;
    json.remove('gpsd');
    return jsonEncode(json);
  } on FormatException {
    return raw;
  }
}
