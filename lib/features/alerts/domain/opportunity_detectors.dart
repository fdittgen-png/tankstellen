// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The three existing alert kinds, emitting [Opportunity] (#4149).
///
/// Migration, not a rewrite. Each function takes exactly what the
/// existing detector already produces and states it in the one shape;
/// none of them changes when an alert fires. The three stores and the
/// three firing rules are untouched here on purpose — a migration that
/// loses somebody's alerts is worse than the primitive model it
/// replaces.
///
/// What moves is the DESCRIPTION: once every reason to notify has the
/// same shape, one budget can compare them and decide which is worth an
/// interruption, instead of three independent rules each certain of
/// itself.
///
/// Pure functions over primitives, and the clock is a parameter — a
/// detector that reads the wall clock itself cannot be tested and, in a
/// background isolate, cannot be trusted either (#3660).
library;

import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';
import '../data/models/price_alert.dart';
import 'entities/radius_alert.dart';
import 'opportunity.dart';
import 'station_price_sample.dart';
import 'velocity_alert_detector.dart';

/// How long a price-based opportunity stays true.
///
/// Six hours: long enough that a user who sees the notification an hour
/// later is not being told about a station that has already changed its
/// board, short enough that a phone which was off overnight does not
/// wake up and announce yesterday's bargain. `expiresAt` is what stops
/// that, and #4149's acceptance criteria require it to be honoured
/// rather than merely recorded.
const Duration kOpportunityLifetime = Duration(hours: 6);

/// A station-and-threshold alert the user set themselves
/// ([OpportunityKind.favouriteStation]).
///
/// [currentPrice] has already been found to be at or below
/// [PriceAlert.targetPrice] by the existing runner; this only states it.
/// The reference is [OpportunityReference.thresholdYouSet] because that
/// is literally what it was compared with — the user's own number, which
/// is the most checkable reference there is.
Opportunity opportunityFromPriceAlert({
  required PriceAlert alert,
  required double currentPrice,
  required double distanceKm,
  required DataValue<Duration> priceAge,
  required DataConfidence confidence,
  required DateTime now,
  Money? money,
}) =>
    Opportunity(
      kind: OpportunityKind.favouriteStation,
      stationId: alert.stationId,
      stationName: alert.stationName,
      fuelType: alert.fuelType.apiValue,
      currentPrice: currentPrice,
      reference: OpportunityReference.thresholdYouSet,
      referencePrice: alert.targetPrice,
      grossSaving: money?.gross,
      detourCost: money?.detour,
      netSaving: money?.net,
      distanceKm: distanceKm,
      priceAge: priceAge,
      confidence: confidence,
      detectedAt: now,
      expiresAt: now.add(kOpportunityLifetime),
    );

/// One station that satisfied a radius alert
/// ([OpportunityKind.exceptionalLocalPrice]).
///
/// The existing runner produces several of these per alert and rolls
/// them into ONE grouped notification. That grouping stays where it is:
/// it belongs to delivery, not to detection, and flattening it into N
/// notifications would be a regression dressed as a refactor.
Opportunity opportunityFromRadiusMatch({
  required RadiusAlert alert,
  required StationPriceSample sample,
  required double distanceKm,
  required DataValue<Duration> priceAge,
  required DataConfidence confidence,
  required DateTime now,
  Money? money,
}) =>
    Opportunity(
      kind: OpportunityKind.exceptionalLocalPrice,
      stationId: sample.stationId,
      stationName: sample.name,
      fuelType: sample.fuelType,
      currentPrice: sample.pricePerLiter,
      reference: OpportunityReference.thresholdYouSet,
      referencePrice: alert.threshold,
      grossSaving: money?.gross,
      detourCost: money?.detour,
      netSaving: money?.net,
      distanceKm: distanceKm,
      priceAge: priceAge,
      confidence: confidence,
      detectedAt: now,
      expiresAt: now.add(kOpportunityLifetime),
    );

/// Prices falling across several nearby stations at once
/// ([OpportunityKind.localMovement]).
///
/// The one kind that is NOT about a single station, which is why
/// [Opportunity.stationId] is nullable: a movement is a fact about an
/// area. Its reference is [OpportunityReference.priceEarlier] because
/// that is exactly what the detector compared — the same stations, a
/// lookback window ago.
///
/// It also carries no money. A drop of N cents is not a saving until
/// someone says how many litres they are buying and how far they would
/// drive, and the velocity detector knows neither. [Opportunity
/// .isPriceable] is false, and `OpportunityScorer` will therefore never
/// rank it on money it does not have.
Opportunity opportunityFromVelocityEvent({
  required VelocityAlertEvent event,
  required DataValue<Duration> priceAge,
  required DataConfidence confidence,
  required DateTime now,
  required double referencePrice,
  required double currentPrice,
  double distanceKm = 0,
}) =>
    Opportunity(
      kind: OpportunityKind.localMovement,
      fuelType: event.fuelType.apiValue,
      currentPrice: currentPrice,
      reference: OpportunityReference.priceEarlier,
      referencePrice: referencePrice,
      distanceKm: distanceKm,
      priceAge: priceAge,
      confidence: confidence,
      detectedAt: now,
      expiresAt: now.add(kOpportunityLifetime),
    );

/// The money side of an opportunity, or absent.
///
/// A single type rather than three nullable parameters, so the three
/// figures trust rule 4 ties together cannot be passed independently —
/// and therefore cannot disagree. [net] is computed here, never
/// supplied: a caller that could pass its own net could pass one that
/// does not equal `gross - detour`, which is precisely the unverifiable
/// claim the rule forbids.
class Money {
  Money({required this.gross, required this.detour})
      : net = gross - detour;

  /// Price difference × the litres this user actually buys.
  final double gross;

  /// What the detour costs in fuel, at this user's consumption.
  final double detour;

  /// [gross] − [detour]. Derived, never given.
  final double net;
}
