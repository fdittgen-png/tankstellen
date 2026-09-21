// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// How far an alert may be trusted, derived (#4152, epic #4148).
///
/// A **band**, never a percentage. A confidence of 94 % invites a
/// precision the inputs do not have: they are a price age, a provider's
/// published cadence, whether a consumption figure was measured or
/// modelled, and whether a distance is road or crow-flies. Multiplying
/// four soft facts into two significant figures manufactures certainty
/// out of its absence.
///
/// Each input is nameable and individually testable, and the band is the
/// WEAKEST of them — the same rule `ProviderCapability.confidence` uses
/// for provider trust, for the same reason: a chain is as strong as its
/// weakest link, and unlike a weighted score it can be explained in one
/// sentence to the person it woke up.
library;

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';
import 'opportunity.dart';

/// What the user is told, and what may be sent.
enum AlertConfidence {
  /// Say nothing — the alert speaks for itself.
  high,

  /// Hedge the claim: "potential saving".
  medium,

  /// Do not interrupt. It may still appear in the in-app feed, where
  /// the user came looking, but it must not arrive uninvited.
  low,
}

/// Past this, a price is old enough to hedge the claim built on it.
///
/// Six hours, deliberately tighter than the 24 h that decides whether an
/// opportunity is ELIGIBLE at all (`kOpportunityMaxPriceAge`). Those are
/// different questions: 24 h is when we stop believing the number, 6 h
/// is when we stop presenting it without a caveat.
const Duration kAlertHedgePriceAge = Duration(hours: 6);

/// One named input to the band, so a test can drive each on its own.
@immutable
class ConfidenceInputs {
  const ConfidenceInputs({
    required this.provider,
    required this.priceAge,
    this.moneyClaimed = false,
    this.consumptionIsEstimated = false,
    this.distanceIsRoad = false,
  });

  /// What the country's data source is worth (#4156).
  final DataConfidence provider;

  /// How old this row's price is, as far as that provider can say.
  final DataValue<Duration> priceAge;

  /// Whether this alert actually makes a MONEY claim.
  ///
  /// Load-bearing, and the thing a first pass at this got wrong. An
  /// input only weakens the claim it supports: consumption provenance
  /// and distance quality feed the detour cost, so they matter to "this
  /// saves you €4.30" and are irrelevant to "diesel is below the price
  /// you set at your own station". Letting them hedge a pure price
  /// threshold would have made every alert in the app read "potential
  /// saving" — over-hedging is not the safe direction, it is just a
  /// different way of being uninformative.
  final bool moneyClaimed;

  /// Whether the money figure rests on a modelled consumption rather
  /// than one measured from the user's own fill-ups.
  final bool consumptionIsEstimated;

  /// Whether the distance is a real road distance rather than
  /// crow-flies × a correction factor.
  final bool distanceIsRoad;

  /// The provider's own trust, mapped onto the alert band.
  AlertConfidence get providerTier => switch (provider) {
        DataConfidence.high => AlertConfidence.high,
        DataConfidence.medium => AlertConfidence.medium,
        DataConfidence.low || DataConfidence.none => AlertConfidence.low,
      };

  /// How current the price is.
  ///
  /// An UNKNOWN age does not sink the band. Nine of seventeen providers
  /// stamp no prices, and treating that as staleness would make every
  /// alert in those countries low-confidence forever — the same
  /// "unknown read as no" bug #4156 fixed. It hedges instead: medium,
  /// with `PriceAgeUnknownReason` saying why in the list.
  AlertConfidence get freshnessTier => switch (priceAge) {
        Measured<Duration>(:final value) =>
          value <= kAlertHedgePriceAge
              ? AlertConfidence.high
              : AlertConfidence.medium,
        Unknown<Duration>() => AlertConfidence.medium,
        _ => AlertConfidence.medium,
      };

  /// Whether the money rests on something the user actually drove.
  ///
  /// `docs/specs/refuel-economics.md` trust rule 2: an explanation built
  /// on a model must not read as a measurement. It caps at medium rather
  /// than sinking to low — a modelled consumption makes the amount
  /// approximate, not the alert wrong.
  AlertConfidence get consumptionTier => !moneyClaimed
      ? AlertConfidence.high
      : consumptionIsEstimated
          ? AlertConfidence.medium
          : AlertConfidence.high;

  /// Whether the detour cost rests on a real road distance.
  ///
  /// Crow-flies × 1.3 is a decent estimate and the app says so
  /// everywhere else; it hedges, it does not disqualify.
  AlertConfidence get distanceTier => !moneyClaimed
      ? AlertConfidence.high
      : distanceIsRoad
          ? AlertConfidence.high
          : AlertConfidence.medium;
}

/// Derives the band. No weights, no score.
abstract final class OpportunityConfidence {
  /// The weakest named tier.
  static AlertConfidence of(ConfidenceInputs inputs) {
    var worst = AlertConfidence.high;
    for (final tier in [
      inputs.providerTier,
      inputs.freshnessTier,
      inputs.consumptionTier,
      inputs.distanceTier,
    ]) {
      if (tier.index > worst.index) worst = tier;
    }
    return worst;
  }

  /// The inputs an [Opportunity] carries on its own.
  ///
  /// Consumption provenance and distance quality are NOT on the
  /// opportunity — they belong to the profile and the routing that
  /// produced it — so the caller supplies them. Defaulting them to the
  /// favourable value would quietly inflate the band, which is the one
  /// direction this must never fail in.
  static ConfidenceInputs inputsFor(
    Opportunity o, {
    bool consumptionIsEstimated = false,
    bool distanceIsRoad = false,
  }) =>
      ConfidenceInputs(
        provider: o.confidence,
        priceAge: o.priceAge,
        moneyClaimed: o.isPriceable,
        consumptionIsEstimated: consumptionIsEstimated,
        distanceIsRoad: distanceIsRoad,
      );

  /// Whether this may arrive uninvited.
  ///
  /// The acceptance criterion, as a function: a low-confidence
  /// opportunity cannot become a push. It is not discarded — the in-app
  /// feed is where the user came looking, and a weak signal is still
  /// worth having when they asked for it. It simply may not interrupt.
  static bool mayNotify(AlertConfidence band) => band != AlertConfidence.low;
}
