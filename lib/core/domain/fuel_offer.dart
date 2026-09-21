// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One comparable fuel offer (#4361, Epic #4358, work package D).
///
/// A price on a screen is not an offer. To compare two of them across a
/// border the decision needs all of it: which station, in which country,
/// for which GRADE, in which currency, measured in which volume unit, how
/// old, from a source covering how much of its country, at a place you
/// can actually drive to.
///
/// ## Two things that are not the same question
///
///  * **Will it go in the tank?** `fuelCompatibilityFamily` in
///    `fuel_type.dart` answers that (#713) — and answers "yes" for E85 in
///    every petrol car, most of which it damages.
///  * **Is this vehicle approved for it?** [VehicleFuelCapability] answers
///    that (#4274/#4324), and it is the only question a RECOMMENDATION may
///    ask. [fuelOfferApproval] below routes the offer through the
///    capability and never widens it.
///
/// So the classes here are stricter than the filler-neck family: E85 is
/// its own class, diesel is its own, LPG is its own. A price existing does
/// not make two fuels interchangeable.
///
/// ## Cheaper per litre is not cheaper per kilometre
///
/// E85 at €1.30/L in a car that burns 9 L/100 km costs €11.70 per 100 km;
/// E10 at €1.60/L at 7 L/100 km costs €11.20. The per-litre winner loses.
/// [FuelOffer.costToCoverKm] is therefore the comparison whenever two
/// offers are different grades, and the caller supplies the per-grade
/// consumption from the canonical consumption contract rather than
/// inventing an energy conversion here.
///
/// Pure Dart: no Flutter, no provider, no station type.
library;

import 'package:meta/meta.dart';

import 'data_value.dart';
import 'fuel/fuel_grade.dart';
import 'money.dart';

/// The physical unit a price is quoted per.
///
/// Every country in the table sells liquid fuel by the litre today; the
/// enum exists so a gallon country cannot be added by editing a format
/// mask alone, and so a quote can state its unit instead of assuming one.
enum FuelVolumeUnit {
  litre(1),

  /// US gallon, for the day a US price arrives. 1 gal = 3.785411784 L.
  usGallon(3.785411784);

  const FuelVolumeUnit(this.litresPerUnit);

  final double litresPerUnit;
}

/// A pump price with its currency and unit attached.
///
/// [amountPerLitre] is always in the currency's PRIMARY unit (GBP, not
/// pence). The forecourt convention — `155.9 p/L`, `185.9 c/L` — is a
/// display scale, and [FuelPriceQuote.fromSubUnit] is the single door it
/// may come through, so a pence figure can never be compared with a euro
/// figure by accident.
@immutable
class FuelPriceQuote {
  const FuelPriceQuote({
    required this.amountPerLitre,
    required this.currencyCode,
    this.volumeUnit = FuelVolumeUnit.litre,
  });

  /// A price quoted in the currency's sub-unit (pence, cents).
  ///
  /// [subUnitsPerPrimary] is 100 for every decimal currency; it is named
  /// rather than hard-coded so the conversion is visible at the call site
  /// that owns the country's convention.
  factory FuelPriceQuote.fromSubUnit(
    double amountPerLitre, {
    required String currencyCode,
    double subUnitsPerPrimary = 100,
    FuelVolumeUnit volumeUnit = FuelVolumeUnit.litre,
  }) =>
      FuelPriceQuote(
        amountPerLitre: subUnitsPerPrimary <= 0
            ? amountPerLitre
            : amountPerLitre / subUnitsPerPrimary,
        currencyCode: currencyCode,
        volumeUnit: volumeUnit,
      );

  /// A price quoted per [volumeUnit] rather than per litre — normalised
  /// on the way in, so nothing downstream has to know the unit existed.
  factory FuelPriceQuote.perUnit(
    double amountPerUnit, {
    required String currencyCode,
    required FuelVolumeUnit volumeUnit,
  }) =>
      FuelPriceQuote(
        amountPerLitre: volumeUnit.litresPerUnit <= 0
            ? amountPerUnit
            : amountPerUnit / volumeUnit.litresPerUnit,
        currencyCode: currencyCode,
        volumeUnit: volumeUnit,
      );

  /// Always in the currency's PRIMARY unit — see the library doc.
  final double amountPerLitre;

  final String currencyCode;

  /// The unit the source quoted, kept for the explanation only — the
  /// arithmetic below is per litre throughout.
  final FuelVolumeUnit volumeUnit;

  Money get perLitre => Money(amountPerLitre, currencyCode);

  bool get isUsable => amountPerLitre.isFinite && amountPerLitre > 0;

  /// What [litres] cost at this price, in the native currency.
  Money cost(double litres) => Money(amountPerLitre * litres, currencyCode);

  @override
  bool operator ==(Object other) =>
      other is FuelPriceQuote &&
      other.amountPerLitre == amountPerLitre &&
      other.currencyCode == currencyCode &&
      other.volumeUnit == volumeUnit;

  @override
  int get hashCode => Object.hash(amountPerLitre, currencyCode, volumeUnit);
}

/// Grades that may never substitute for one another, whatever fits the
/// filler neck.
///
/// Deliberately finer than [FuelCompatibilityFamily]: E85 is separated
/// from the E5/E10/E98 petrol grades because a non-flex car is damaged by
/// it, which is the entire reason #4324 gave the vehicle a capability.
enum FuelApprovalClass {
  /// E5, E10, E98 — pump petrol up to 10 % ethanol.
  petrol,

  /// E85 alone.
  ethanolE85,
  diesel,
  lpg,
  cng,
  hydrogen,
  electric,

  /// A grade the app cannot classify. Never approved, never refused on
  /// its own — the surface states that it does not know.
  unclassified,
}

/// The approval class of [grade].
FuelApprovalClass approvalClassOf(FuelGrade grade) => switch (grade) {
      FuelGrade.e5 || FuelGrade.e10 || FuelGrade.e98 => FuelApprovalClass.petrol,
      FuelGrade.e85 => FuelApprovalClass.ethanolE85,
      FuelGrade.diesel ||
      FuelGrade.dieselPremium =>
        FuelApprovalClass.diesel,
      FuelGrade.lpg => FuelApprovalClass.lpg,
      FuelGrade.cng => FuelApprovalClass.cng,
      FuelGrade.hydrogen => FuelApprovalClass.hydrogen,
      FuelGrade.electric => FuelApprovalClass.electric,
      FuelGrade.wildcard || FuelGrade.unknown => FuelApprovalClass.unclassified,
    };

/// Whether a vehicle may be recommended an offer.
enum FuelOfferApproval {
  /// The vehicle's capability names this grade.
  approved,

  /// Same approval class as the vehicle's own fuel, but the capability
  /// does not name it. Browsable, never a recommendation — "not confirmed"
  /// is the honest state, and it is not a refusal.
  notConfirmed,

  /// A different approval class: a diesel offer for a petrol car, E85 for
  /// a car approved for E10. Excluded from every comparison.
  incompatible,

  /// Nothing is known about what the vehicle takes (no profile, no
  /// configured fuel). No offer may be recommended on that basis.
  vehicleUnknown,
}

/// Whether [offered] may be recommended to a vehicle whose approvals are
/// [capability] and whose configured grade is [configured].
///
/// A profile's fuel FALLBACK is not proof of approval: [configured] only
/// narrows an unapproved grade from `incompatible` to `notConfirmed` when
/// the two share an approval class, and never produces `approved`.
FuelOfferApproval fuelOfferApproval(
  FuelGrade offered, {
  VehicleFuelCapability? capability,
  FuelGrade? configured,
}) {
  final offeredClass = approvalClassOf(offered);
  if (offeredClass == FuelApprovalClass.unclassified) {
    return FuelOfferApproval.vehicleUnknown;
  }
  if (capability != null && !capability.isUnknown) {
    if (capability.permits(offered)) return FuelOfferApproval.approved;
    final sameClass = capability.approvedGrades
        .any((g) => approvalClassOf(g) == offeredClass);
    return sameClass
        ? FuelOfferApproval.notConfirmed
        : FuelOfferApproval.incompatible;
  }
  if (configured == null) return FuelOfferApproval.vehicleUnknown;
  return approvalClassOf(configured) == offeredClass
      ? FuelOfferApproval.notConfirmed
      : FuelOfferApproval.incompatible;
}

/// One station's offer of one grade, comparable across borders.
@immutable
class FuelOffer {
  const FuelOffer({
    required this.stationId,
    required this.grade,
    required this.quote,
    this.countryCode,
    this.isPhysicalStation = true,
    this.coverageComplete = true,
    this.priceAge = const DataValue.unknown(
      reason: DataUnknownReason.notPublishedForThisItem,
    ),
    this.consumptionLPer100km,
    this.consumptionIsEstimated = false,
  });

  final String stationId;

  /// ISO country of the SELLING station — not the driver's country. The
  /// currency, the coverage claim and the setup prompt all follow this.
  final String? countryCode;

  final FuelGrade grade;
  final FuelPriceQuote quote;

  /// #4348 — a reference price (LU's decree at a city centroid, GR's
  /// prefecture average) is a real price and never a destination. It may
  /// explain a region; it may not be a stop.
  final bool isPhysicalStation;

  /// #4348 — false when the source lists only some of its country's
  /// stations (DK's brand feeds). A winner drawn from such a set speaks
  /// for the offers returned, not the country.
  final bool coverageComplete;

  final DataValue<Duration> priceAge;

  /// Consumption of THIS grade in the driver's vehicle, from the
  /// canonical per-fuel contract. Null when unmeasured — then no
  /// cost-to-cover-distance comparison is available for this offer, and
  /// the surface says so rather than reusing another grade's figure.
  final double? consumptionLPer100km;

  final bool consumptionIsEstimated;

  String get currencyCode => quote.currencyCode;

  /// What covering [km] costs in fuel at this offer, natively. Null
  /// without a per-grade consumption — the whole reason a cheaper litre
  /// can be the dearer kilometre.
  Money? costToCoverKm(double km) {
    final c = consumptionLPer100km;
    if (c == null || !c.isFinite || c <= 0 || !km.isFinite || km < 0) {
      return null;
    }
    return quote.cost(km * c / 100);
  }

  /// The same figure per 100 km — the shape the acceptance case states
  /// (E85 €11.70, E10 €11.20).
  Money? get costPer100Km => costToCoverKm(100);
}

/// Which of [offers] covers [km] most cheaply in [target], or null when
/// any competing offer cannot be converted or lacks a per-grade
/// consumption. Null withholds a winner; it never falls back to price.
FuelOffer? cheapestOverDistance(
  Iterable<FuelOffer> offers,
  double km, {
  required String target,
  required ExchangeRateSnapshot rates,
  required DateTime now,
}) {
  FuelOffer? winner;
  double? best;
  for (final offer in offers) {
    final native = offer.costToCoverKm(km);
    if (native == null) return null;
    final converted = rates.convert(native, target, now).converted;
    if (converted == null) return null;
    if (best == null ||
        converted.amount < best ||
        (converted.amount == best &&
            offer.stationId.compareTo(winner!.stationId) < 0)) {
      winner = offer;
      best = converted.amount;
    }
  }
  return winner;
}
