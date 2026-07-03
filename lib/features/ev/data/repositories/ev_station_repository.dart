// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';


import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/domain/ev/charging_station.dart';
import '../../../../core/logging/error_logger.dart';

/// CRUD repository for [ChargingStation] entries.
///
/// Stored as a simple list under [StorageKeys.evStationsCache] in the
/// settings box. Acts as an in-memory + Hive-persistent cache of recently
/// fetched EV charging stations so the map can render instantly on reopen
/// even when the backing service is unreachable.
class EvStationRepository {
  final SettingsStorage _storage;

  EvStationRepository(this._storage);

  static const String _listKey = StorageKeys.evStationsCache;

  /// Returns all cached charging stations, in insertion order.
  List<ChargingStation> getAll() {
    final raw = _storage.getSetting(_listKey);
    if (raw is! List) return const [];

    final result = <ChargingStation>[];
    for (final item in raw) {
      final map = HiveBoxes.toStringDynamicMap(item);
      if (map == null) continue;
      try {
        result.add(ChargingStation.fromJson(map));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'EvStationRepository: skipping malformed entry'}));
      }
    }
    return result;
  }

  /// Returns the charging station matching [id] if present.
  ChargingStation? getById(String id) {
    for (final s in getAll()) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Add or update a charging station (matched by id).
  Future<void> save(ChargingStation station) async {
    final all = [...getAll()];
    final index = all.indexWhere((s) => s.id == station.id);
    if (index >= 0) {
      all[index] = station;
    } else {
      all.add(station);
    }
    await _writeAll(all);
  }

  /// Replace the entire cache with the given list.
  Future<void> saveAll(List<ChargingStation> stations) async {
    await _writeAll(stations);
  }

  /// Delete a charging station by id.
  Future<void> delete(String id) async {
    final all = [...getAll()]..removeWhere((s) => s.id == id);
    await _writeAll(all);
  }

  /// Remove every cached charging station.
  Future<void> clear() async {
    await _storage.putSetting(_listKey, <Map<String, dynamic>>[]);
  }

  Future<void> _writeAll(List<ChargingStation> list) async {
    final json = list.map((s) => s.toJson()).toList();
    await _storage.putSetting(_listKey, json);
  }
}

/// Hydrates the [ChargingStation] for an `ocm-*` id from local caches.
///
/// #1804 — checks the EV favorites store first, then falls back to the
/// recently-fetched EV station cache ([EvStationRepository]), so a
/// station the user has seen on the map — or that a home-screen widget
/// surfaced — resolves even when it is **not** a saved favorite. Returns
/// `null` only when the id is genuinely unknown to the device.
///
/// Shared by the `/ev-station/:id` deep-link route AND (#3455) the
/// `stationDetail` provider's ocm-id routing, so an EV id never reaches a
/// fuel-price chain — the caller serves this cached station instead.
ChargingStation? hydrateEvStationById(
  String id,
  EvFavoriteStorage favorites,
  EvStationRepository cache,
) {
  final raw = favorites.getEvFavoriteStationData(id);
  if (raw != null) {
    try {
      return ChargingStation.fromJson(raw);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'hydrateEvStationById: corrupt EV favorite payload'
      }));
      // A corrupt favorites payload shouldn't block a valid cache hit.
    }
  }
  return cache.getById(id);
}
