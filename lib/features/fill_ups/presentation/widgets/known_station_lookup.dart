// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/search_result_item.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../search/api.dart';

/// #3899 / #3906 — the stations the app already knows WITHOUT a network
/// call: the favorites store and the last search result still held by
/// the search provider. The fill-up form uses them to show the chosen
/// station's address; the station picker builds its "Nearby" section
/// from them. Every read is guarded — a bare test container without
/// storage degrades to an empty list, never a throw.
///
/// Favorite stations decoded from storage. Malformed entries are logged
/// and skipped so one corrupt favorite cannot blank the whole list.
List<Station> favoriteStations(WidgetRef ref) {
  return guard(
    () {
      final storage = ref.watch(storageRepositoryProvider);
      final stations = <Station>[];
      for (final id in storage.getFavoriteIds()) {
        final raw = storage.getFavoriteStationData(id);
        if (raw == null) continue;
        try {
          stations.add(Station.fromJson(raw));
        } catch (e, st) {
          logFailure(e, st,
              where: 'knownStations: skipping malformed favorite $id');
        }
      }
      return stations;
    },
    where: 'knownStations: favorites unavailable',
    fallback: const <Station>[],
  );
}

/// Fuel stations of the most recent search result (the search tab's
/// cache) — empty until the user has searched at least once this
/// session. EV results are not fuel stations and are skipped.
List<Station> cachedSearchStations(WidgetRef ref) {
  return guard(
    () {
      final items = ref.watch(searchStateProvider).value?.data;
      if (items == null) return const <Station>[];
      return [
        for (final item in items)
          if (item is FuelStationResult) item.station,
      ];
    },
    where: 'knownStations: search cache unavailable',
    fallback: const <Station>[],
  );
}

/// The station with [id] if the app knows it (favorites first, then the
/// last search result), else null.
Station? findKnownStation(WidgetRef ref, String id) {
  for (final s in favoriteStations(ref)) {
    if (s.id == id) return s;
  }
  for (final s in cachedSearchStations(ref)) {
    if (s.id == id) return s;
  }
  return null;
}

/// Display title of a station: the brand when it has one, else the name.
String stationTitle(Station s) => s.brand.isNotEmpty ? s.brand : s.name;

/// One-line address (`street • place`) — empty when the station carries
/// neither.
String stationAddressLine(Station s) => [
      if (s.street.isNotEmpty) s.street,
      if (s.place.isNotEmpty) s.place,
    ].join(' • ');
