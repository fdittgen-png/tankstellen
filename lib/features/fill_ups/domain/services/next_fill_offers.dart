// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/next_fill_request.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/refuel_economics.dart';
import '../../../../core/domain/search_result_item.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/price_utils.dart';

/// Where the Fuel & Tank surface's next-fill prices come from (#4324).
enum NextFillOfferSource {
  /// The stations of the last search still held in memory: each carries
  /// its distance, so the decision prices the detour.
  nearbySearch,

  /// The favourite stations' cached prices: no distance, no detour.
  favourites,
}

/// Offers for [grades] from search results the app ALREADY holds (#4324):
/// one per station and grade with a price, each naming its station and
/// distance so `RefuelEconomics` prices the detour. Nothing is fetched.
/// EV results and rows without a finite, non-negative distance are
/// skipped — a detour cannot be priced from a missing distance.
List<FuelOffer> nearbySearchOffers(
    List<FuelGrade> grades, Iterable<SearchResultItem> results) {
  final offers = <FuelOffer>[];
  for (final item in results.whereType<FuelStationResult>()) {
    final km = item.dist;
    if (!km.isFinite || km < 0) continue;
    for (final grade in grades) {
      final price = _price(item.station, grade);
      if (price == null) continue;
      offers.add(FuelOffer(
        grade: grade,
        pricePerLitre: price,
        station: RefuelCandidate(
            stationId: item.station.id, oneWayKm: km, pricePerLitre: price),
      ));
    }
  }
  return offers;
}

/// One offer per grade in [grades]: the cheapest price among the favourite
/// [stations] (#4278). No station is attached — favourites carry no
/// distance, so no detour can be priced.
List<FuelOffer> favouriteOffers(
    List<FuelGrade> grades, Iterable<Station> stations) {
  final offers = <FuelOffer>[];
  for (final grade in grades) {
    double? best;
    for (final station in stations) {
      final price = _price(station, grade);
      if (price != null && (best == null || price < best)) best = price;
    }
    if (best != null) offers.add(FuelOffer(grade: grade, pricePerLitre: best));
  }
  return offers;
}

/// Which source a list of offers came from: any offer naming a station is
/// a nearby-search list.
NextFillOfferSource offerSourceOf(Iterable<FuelOffer> offers) =>
    offers.any((o) => o.station != null)
        ? NextFillOfferSource.nearbySearch
        : NextFillOfferSource.favourites;

double? _price(Station station, FuelGrade grade) {
  final price = priceForFuelType(station, FuelType.fromString(grade.key));
  return price == null || !price.isFinite || price <= 0 ? null : price;
}
