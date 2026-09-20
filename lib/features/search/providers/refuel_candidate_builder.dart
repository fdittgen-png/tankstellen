// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One station → one [RefuelCandidate], the same way everywhere (#4090,
/// #4156, #4348, #4361; shared by #4363).
///
/// The nearby decision and the selected-station comparison must reduce a
/// station to the economics' input identically, or a station could hold
/// a ranking in one surface and be gated in the other. This is that one
/// reduction, moved out of `refuel_decision_provider.dart` when #4363
/// gave it a second caller.
library;

import '../../../core/country/country_config.dart';
import '../../../core/domain/data_value.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/refuel_economics.dart';
import '../../../core/domain/station.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/services/station_offer.dart';
import '../../../core/utils/station_extensions.dart';

/// Reduce [station] to what the economics needs.
///
/// #4156 — the gates are only as good as the provider behind them, and a
/// cross-border result set mixes providers, so the capability is resolved
/// PER STATION: the id prefix first (#753's `de-`/`uk-`/… scheme), then
/// the bounding box for an id that carries none. Both lookups are static
/// and storage-free on purpose — reading the active country would be the
/// wrong answer for a station across the border.
///
/// #4348 — the same resolution answers what the result IS: a reference
/// price holds no ranking, and a partial source qualifies every pick.
///
/// [distKm] is the crow-flies figure the surface already shows; a current
/// road quote in [road] replaces it (#4359).
RefuelCandidate buildRefuelCandidate(
  Station station, {
  required double distKm,
  required FuelType fuelType,
  required DateTime now,
  StationTravelEstimate? road,
}) {
  final offer = StationOffer.forStation(
    stationId: station.id,
    lat: station.lat,
    lng: station.lng,
  );
  final capability = offer.capability;
  final age = priceAgeOf(station.priceUpdatedAt, now);
  return RefuelCandidate(
    stationId: station.id,
    oneWayKm: road?.toStation.distanceKm ?? distKm,
    isRoadDistance: road != null,
    roadTravel: road,
    pricePerLitre: station.priceFor(fuelType),
    // The SELLING country's currency (#4361). A Danish forecourt on a
    // German list quotes DKK, and 13 is not less than 1.80.
    currencyCode: offer.countryCode == null
        ? null
        : Countries.byCode(offer.countryCode!)?.currency,
    isPhysicalStation: offer.canHoldStationRanking,
    coverageComplete: offer.coverageComplete,
    // An unregistered country gets the candidate's own defaults, which
    // block both gates. That is the honest answer: we do not know what
    // this source publishes, so we cannot stand a gate down over it.
    openState: capability?.openState(station.isOpen) ??
        const DataValue.unknown(
          reason: DataUnknownReason.notPublishedForThisItem,
        ),
    priceAge: capability?.priceAge(age) ??
        const DataValue.unknown(
          reason: DataUnknownReason.notPublishedForThisItem,
        ),
  );
}

/// How old the station's price is, or null when the provider published
/// no stamp — which lets `ProviderCapability` decide whether that is a
/// stand-down or a block, rather than deciding here.
///
/// #4189 — this read `Station.updatedAt`, which is a DISPLAY string
/// (`dd/MM HH:mm`). `DateTime.tryParse` returned null for it, so a
/// French, Danish or Portuguese price — from providers whose capability
/// declares `priceTimestamp: true` — became `notPublishedForThisItem`,
/// which the freshness gate treats as a block.
Duration? priceAgeOf(DateTime? stamp, DateTime now) {
  if (stamp == null) return null;
  final age = now.difference(stamp);
  // A stamp in the future is a broken feed, not a fresh price.
  return age.isNegative ? null : age;
}
