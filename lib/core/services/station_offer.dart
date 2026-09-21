// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// What a search result actually IS, and so what it may be used for
/// (#4348, follow-up to #4156).
///
/// `ProviderCapability` already said which sources publish real station
/// coordinates, which cover only part of a country and which are dead —
/// and nothing read it. Luxembourg's regulated national price arrives as
/// five city centroids, Greece's as one point per prefecture; both reach
/// the app as `Station` objects with a lat/lng and a distance, and every
/// surface treated them as forecourts: a Navigate button that drove the
/// user to a town square, a detour costed to a point nobody sells fuel
/// at, a "cheapest station" that is a national average.
///
/// A reference price is still worth showing — it is the exact regulated
/// price everywhere in Luxembourg. What it may not do is pose as a place.
/// This type is the ONE answer every surface asks, resolved per result's
/// own country (a cross-border result set mixes providers), so the rule
/// cannot be re-derived differently per widget.
///
/// ## Unregistered sources
///
/// A result whose country the registry does not know — an OpenChargeMap
/// charger, a demo station outside every bounding box — is treated as a
/// physical location. The capability contract governs the fuel providers
/// it declares; chargers from OCM are real points with real coordinates,
/// and refusing to navigate to them would break a working feature over
/// a lookup miss rather than over anything the source told us.
///
/// ## Consumers, and the ones still owed
///
/// Reading this contract today: the map sheet, the in-car sheet, the
/// station detail / deep-link FAB, favorites, the search list and route
/// list swipes, the trip radar card and the route "open in maps"
/// waypoints (all through `NavigationUtils.openStation`); the nearby
/// refuel decision (`refuel_decision_provider.dart`) and the route
/// refuel plan (`refuel_plan_provider.dart`); the travel-estimate
/// request budget (#4359).
///
/// Not yet reading it, each with its owner:
///  * background alert scans and their opportunity envelope — the
///    alerts/background surface is owned by S3a/S4 (#4331–#4335);
///  * the route corridor's per-segment "cheapest" best stops
///    (`best_stops.dart`) — the planner candidate graph, #4362;
///  * the selected-station comparison surfaces — #4363.
library;

import 'package:meta/meta.dart';

import 'country_service_registry.dart';
import 'provider_capability.dart';

/// Whether a result's coordinates are a place you can drive to.
enum StationLocationKind {
  /// A real forecourt at its published coordinates.
  physicalStation,

  /// A price stood in at a synthetic point (a city centroid, a prefecture
  /// seat). Useful as a price; never a destination.
  referencePoint,
}

/// The capability-derived contract for one search result.
@immutable
class StationOffer {
  const StationOffer({this.countryCode, this.capability});

  /// Resolve the offer for one result through its OWN country.
  ///
  /// [stationId] first (the #753 prefix is canonical), then the bounding
  /// box of [lat]/[lng] for an id that carries no prefix. The same lookup
  /// `station_open_state.dart` uses, so the two answers can never be
  /// attributed to different countries.
  factory StationOffer.forStation({
    required String? stationId,
    double? lat,
    double? lng,
  }) {
    final code = CountryServiceRegistry.countryForStationId(stationId) ??
        (lat == null || lng == null
            ? null
            : CountryServiceRegistry.countryForLatLng(lat, lng));
    return StationOffer(
      countryCode: code,
      capability:
          code == null ? null : CountryServiceRegistry.capabilityFor(code),
    );
  }

  /// The owning country, or null when the registry does not know it.
  final String? countryCode;

  /// That country's declared capability, or null (see the library doc).
  final ProviderCapability? capability;

  StationLocationKind get locationKind => capability?.coordinates == false
      ? StationLocationKind.referencePoint
      : StationLocationKind.physicalStation;

  bool get isReferencePoint =>
      locationKind == StationLocationKind.referencePoint;

  /// Whether a navigation app may be launched towards this result.
  bool get canNavigate => !isReferencePoint;

  /// Whether a road access leg, a detour or a route stop may be computed
  /// to this result. The same answer as [canNavigate] today, kept as its
  /// own name because the travel-estimate layer (#4359) asks this
  /// question, not the launcher's.
  bool get canRouteTo => !isReferencePoint;

  /// Whether this result may hold a station ranking ("cheapest",
  /// "closest", "best value") or a saving claimed against one.
  bool get canHoldStationRanking => !isReferencePoint;

  /// False when the source covers only some of the country's stations
  /// (DK's three brand feeds) or only some regions — a "cheapest" here
  /// speaks for the covered stations, not the country.
  bool get coverageComplete =>
      capability == null || capability!.coverage == ProviderCoverage.national;
}
