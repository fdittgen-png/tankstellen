// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../search/domain/entities/station.dart';

/// Builds the [Station] for a DGEG `GetDadosPostoMapa` detail response.
///
/// DGEG splits a station across two endpoints: `PesquisarPostos` (search)
/// carries coordinates + prices but no opening hours, while
/// `GetDadosPostoMapa` (detail) carries the `HorarioPosto` schedule + a nested
/// `Morada` address but **no** coordinates. So the detail station is built by
/// overlaying the detail payload's name/brand/address onto the cached search
/// row's coordinates + merged prices when that row is available, and falls
/// back to a coordinate-less station from the detail payload alone otherwise
/// (Epic #2707 C7, #2714).
abstract final class PortugalDetailParser {
  /// Merges the [resultado] detail payload onto [cachedSearchRow] (preferred,
  /// geo-complete) or builds a coordinate-less station when no search row is
  /// cached. Never throws on a malformed `Morada` — missing fields fall back to
  /// the empty string / the cached value.
  static Station stationFromDetail({
    required String stationId,
    required String numericId,
    required Map<dynamic, dynamic> resultado,
    required Station? cachedSearchRow,
  }) {
    final morada = resultado['Morada'];
    final street =
        (morada is Map ? morada['Morada'] : morada)?.toString() ?? '';
    final postCode =
        (morada is Map ? morada['CodPostal'] : null)?.toString() ?? '';
    final place =
        (morada is Map ? morada['Localidade'] : null)?.toString() ?? '';
    final name = resultado['Nome']?.toString() ?? cachedSearchRow?.name ?? '';
    final brand = resultado['Marca']?.toString() ?? cachedSearchRow?.brand ?? '';

    if (cachedSearchRow != null) {
      return cachedSearchRow.copyWith(
        name: name.isNotEmpty ? name : cachedSearchRow.name,
        brand: brand.isNotEmpty ? brand : cachedSearchRow.brand,
        street: street.isNotEmpty ? street : cachedSearchRow.street,
        postCode: postCode.isNotEmpty ? postCode : cachedSearchRow.postCode,
        place: place.isNotEmpty ? place : cachedSearchRow.place,
      );
    }

    return Station(
      id: stationId,
      name: name,
      brand: brand,
      street: street,
      postCode: postCode,
      place: place,
      lat: 0,
      lng: 0,
      isOpen: true,
    );
  }

  /// Finds the cached search row for [numericId] (matched by DGEG `Id`) inside
  /// [cachedResultado] and rebuilds it into a geo-complete [Station] via the
  /// caller's [parseAndFilter] (price merge + fuel dispatch), or `null` when no
  /// fresh dataset is cached. Reusing the search row keeps the detail screen's
  /// map + prices intact when the station is still in the cached dataset.
  static Station? cachedSearchRow(
    String numericId,
    List<dynamic>? cachedResultado,
    List<Station> Function(
      List<dynamic> resultado, {
      required double lat,
      required double lng,
      required double radiusKm,
    }) parseAndFilter,
  ) {
    final id = int.tryParse(numericId);
    if (id == null || cachedResultado == null) return null;
    double? lat;
    double? lng;
    for (final item in cachedResultado) {
      if (item is Map && (item['Id'] as num?)?.toInt() == id) {
        lat = (item['Latitude'] as num?)?.toDouble();
        lng = (item['Longitude'] as num?)?.toDouble();
        break;
      }
    }
    if (lat == null || lng == null) return null;
    // Filter the dataset around the station's own coordinates so the single
    // matching row is rebuilt with merged prices.
    final rows =
        parseAndFilter(cachedResultado, lat: lat, lng: lng, radiusKm: 0.1);
    for (final s in rows) {
      if (s.id == 'pt-$id') return s;
    }
    return null;
  }
}
