// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../domain/entities/fill_up.dart';
import '../widgets/known_station_lookup.dart';

/// #3906 — one row of the station picker: an id + title the fill-up form
/// needs, plus what the row can show (address, distance, the last
/// fill-up's date) and the full [Station] when the app knows it (price
/// pre-fill). A last-station row built from a fill-up whose station is
/// no longer cached has [station] == null — still pickable by name.
class PickStationEntry {
  const PickStationEntry({
    required this.id,
    required this.title,
    this.station,
    this.address,
    this.distanceKm,
    this.lastFillUpDate,
  });

  final String id;
  final String title;
  final Station? station;
  final String? address;
  final double? distanceKm;
  final DateTime? lastFillUpDate;

  /// Cached price for [fuel] at this station, null when unknown or when
  /// the fuel has no price column (EV). Falls back through the common
  /// petrol/diesel columns when no fuel is set.
  double? priceFor(FuelType? fuel) {
    final s = station;
    if (s == null) return null;
    return switch (fuel?.apiValue.toLowerCase()) {
      'e5' => s.e5,
      'e10' => s.e10,
      'e98' => s.e98,
      'diesel' => s.diesel,
      'diesel_premium' => s.dieselPremium,
      'e85' => s.e85,
      'lpg' => s.lpg,
      'cng' => s.cng,
      _ => s.e10 ?? s.e5 ?? s.diesel,
    };
  }
}

/// The three sections of the picker (#3906).
class PickStationCandidates {
  const PickStationCandidates({
    required this.last,
    required this.favorites,
    required this.nearby,
  });

  /// Station of the most recent fill-up (pinned on top), null without one.
  final PickStationEntry? last;
  final List<PickStationEntry> favorites;

  /// Nearest stations from the last search result, closest first,
  /// capped at [kPickStationNearbyLimit]; empty when nothing is cached.
  final List<PickStationEntry> nearby;
}

const int kPickStationNearbyLimit = 10;

/// Assemble the picker's sections from what the app already holds — no
/// network call. [vehicleId] scopes the last station to the active
/// vehicle (null = any vehicle). [position] (lat, lng) orders the
/// nearby list; without it the search result's own `dist` is used.
/// The last station is not repeated under Favorites / Nearby, and a
/// favorite is not repeated under Nearby.
PickStationCandidates buildPickStationCandidates({
  required List<FillUp> fillUps,
  required String? vehicleId,
  required List<Station> favorites,
  required List<Station> searchResults,
  required ({double lat, double lng})? position,
}) {
  final last = _lastStation(fillUps, vehicleId, favorites, searchResults);
  final favoriteEntries = [
    for (final s in favorites)
      if (s.id != last?.id)
        PickStationEntry(
          id: s.id,
          title: stationTitle(s),
          station: s,
          address: stationAddressLine(s),
          distanceKm: _distanceTo(s, position),
        ),
  ];
  final favoriteIds = {for (final s in favorites) s.id};
  final nearbyAll = [
    for (final s in searchResults)
      if (s.id != last?.id && !favoriteIds.contains(s.id))
        PickStationEntry(
          id: s.id,
          title: stationTitle(s),
          station: s,
          address: stationAddressLine(s),
          distanceKm: _distanceTo(s, position),
        ),
  ]..sort(_byDistance);
  return PickStationCandidates(
    last: last,
    favorites: favoriteEntries,
    nearby: nearbyAll.take(kPickStationNearbyLimit).toList(growable: false),
  );
}

PickStationEntry? _lastStation(
  List<FillUp> fillUps,
  String? vehicleId,
  List<Station> favorites,
  List<Station> searchResults,
) {
  FillUp? best;
  for (final f in fillUps) {
    if (f.isCorrection || f.stationId == null) continue;
    if (vehicleId != null && f.vehicleId != vehicleId) continue;
    if (best == null || f.date.isAfter(best.date)) best = f;
  }
  if (best == null) return null;
  final id = best.stationId!;
  Station? known;
  for (final s in favorites) {
    if (s.id == id) known = s;
  }
  if (known == null) {
    for (final s in searchResults) {
      if (s.id == id) known = s;
    }
  }
  final fallbackTitle = best.stationName;
  return PickStationEntry(
    id: id,
    title: known != null
        ? stationTitle(known)
        : (fallbackTitle != null && fallbackTitle.isNotEmpty
            ? fallbackTitle
            : id),
    station: known,
    address: known == null ? null : stationAddressLine(known),
    lastFillUpDate: best.date,
  );
}

double? _distanceTo(Station s, ({double lat, double lng})? position) {
  if (position != null && isUsableCoord(s.lat, s.lng)) {
    return distanceKm(position.lat, position.lng, s.lat, s.lng);
  }
  return s.dist > 0 ? s.dist : null;
}

int _byDistance(PickStationEntry a, PickStationEntry b) {
  final da = a.distanceKm;
  final db = b.distanceKm;
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}
