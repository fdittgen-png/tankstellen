// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The station side of the refuel economics (#4089), split from
/// `refuel_economics.dart` when #4359 gave it a road-travel estimate and
/// the calculator needed the room for #4360's trip ledger.
library;

import 'package:meta/meta.dart';

import 'data_value.dart';
import 'travel_estimate.dart';

/// One station, reduced to what the economics needs.
@immutable
class RefuelCandidate {
  const RefuelCandidate({
    required this.stationId,
    required this.oneWayKm,
    this.pricePerLitre,
    this.currencyCode,
    this.isRoadDistance = false,
    this.roadTravel,
    this.isPhysicalStation = true,
    this.coverageComplete = true,
    this.openState = const DataValue.unknown(
      reason: DataUnknownReason.notPublishedForThisItem,
    ),
    this.priceAge = const DataValue.unknown(
      reason: DataUnknownReason.notPublishedForThisItem,
    ),
  });

  final String stationId;

  /// Distance to the station, one way. Crow-flies unless
  /// [isRoadDistance]; see [kCrowFliesRoadFactor].
  final double oneWayKm;

  /// Price of the SELECTED fuel, or null when this station does not
  /// publish one. A candidate without a price can still be the closest;
  /// it can never hold an economic ranking (spec §4.3).
  final double? pricePerLitre;

  /// ISO 4217 currency [pricePerLitre] is quoted in — the SELLING
  /// country's, not the driver's (#4361).
  ///
  /// Null means nobody stated one. A null currency never joins a money
  /// ranking against a stated one: on a DE→DK list, 13 (DKK) sorts below
  /// 1.80 (EUR) as a bare number and recommends the dearer station with
  /// total confidence. Every candidate in one comparison must be in one
  /// currency, or be converted at a stated, fresh rate.
  final String? currencyCode;

  /// True when [oneWayKm] is a real road distance, so no correction
  /// factor applies.
  final bool isRoadDistance;

  /// The whole road drive this refuel implies — outbound AND return legs,
  /// routed from the driver's own origin (#4359). When present it
  /// replaces `tripFactor × oneWayKm × roadFactor` in the cost: a 3 km
  /// outbound and 7 km return errand is 10 km, not 6, and two stations
  /// at the same crow-flies distance stop costing the same.
  ///
  /// Null means no current road-verified estimate; the candidate then
  /// stays on the explicitly approximate crow-flies figure.
  final StationTravelEstimate? roadTravel;

  /// False for a reference price stood in at a synthetic point — LU's
  /// decree at a city centroid, GR's prefecture average (#4348,
  /// `ProviderCapability.coordinates`).
  ///
  /// Such a candidate stays in [RefuelDecision.quotes] (its price is
  /// real) but has no cost — nobody drives to a town square to buy fuel
  /// — and holds no ranking, so no saving can be claimed against it.
  final bool isPhysicalStation;

  /// False when this candidate's source covers only part of its
  /// country's stations (#4348, DK's three brand feeds). A pick drawn
  /// from such a set is the best among the stations listed, and
  /// [RefuelDecision.coverageIncomplete] makes the UI say so.
  final bool coverageComplete;

  /// Whether the station is open right now (#4139), as far as the
  /// country's provider can say (#4156).
  ///
  /// Never used in the ARITHMETIC — it gates whether Best Value may LEAD
  /// (spec §3.1). A confident recommendation at a closed forecourt is the
  /// failure §5 named as costing more trust than the optimisation buys.
  ///
  /// Was a `bool?`, which conflated two different absences and read both
  /// as "closed": eleven of the seventeen registered countries publish no
  /// opening hours for anyone, so the conditional lead could not fire in
  /// any of them and nothing said why.
  /// `ProviderCapability.openState` produces this, and the difference
  /// between the two unknowns is what the gate now reads.
  final DataValue<bool> openState;

  /// How old the price is (#4139), as far as the country's provider can
  /// say (#4156). Gates the lead for the same reason; never enters the
  /// cost.
  ///
  /// [DataUnknownReason.notPublishedByProvider] means the source stamps
  /// no prices at all — the age we could compute would be our own
  /// download clock. See `ProviderCapability.priceAge`.
  final DataValue<Duration> priceAge;

  @override
  bool operator ==(Object other) =>
      other is RefuelCandidate &&
      other.stationId == stationId &&
      other.oneWayKm == oneWayKm &&
      other.pricePerLitre == pricePerLitre &&
      other.currencyCode == currencyCode &&
      other.isRoadDistance == isRoadDistance &&
      identical(other.roadTravel, roadTravel) &&
      other.isPhysicalStation == isPhysicalStation &&
      other.coverageComplete == coverageComplete &&
      other.openState == openState &&
      other.priceAge == priceAge;

  @override
  int get hashCode =>
      Object.hash(stationId, oneWayKm, pricePerLitre, currencyCode,
          isRoadDistance, roadTravel, isPhysicalStation, coverageComplete,
          openState, priceAge);
}
