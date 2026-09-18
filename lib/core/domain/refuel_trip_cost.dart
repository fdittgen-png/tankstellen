// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Fuel conservation and comparable money for one refuelling trip
/// (#4360, Epic #4358, work package B).
///
/// `RefuelEconomics.tripCost` is the entry point; this library holds its
/// value types and arithmetic so `refuel_economics.dart` stays one
/// calculator under the file cap rather than growing a second one.
///
/// ## The quantities, kept apart
///
/// | quantity | meaning |
/// |---|---|
/// | [RefuelTripCost.litresDispensed] | what the pump actually delivers — the litres to buy |
/// | [RefuelTripCost.cashAtPump] | `litresDispensed × price`, counted ONCE |
/// | [RefuelTripCost.consumedLitres] | fuel burned on the outbound AND return legs |
/// | [RefuelTripCost.consumedValue] | those litres valued for explanation — never added to cash |
/// | [RefuelTripCost.endLitres] | what is left after the return leg |
/// | [RefuelTripCost.charges] | known tolls/ferries; unknown is not zero |
///
/// ## Conservation, leg by leg
///
/// ```
/// arrival   = start     − consumed(outbound)      ≥ 0
/// departure = arrival   + dispensed               ≤ capacity
/// end       = departure − consumed(return)
/// ```
///
/// ## What a purchase quantity MEANS ([RefuelPurchaseQuantity])
///
///  * dispensed — the litres the driver actually buys; never
///    reinterpreted to make a comparison work;
///  * netIncrease — the fuel gained after the return trip, so
///    `dispensed = netIncrease + consumed`;
///  * targetFinal — the tank level wanted after returning, so
///    `dispensed = target − start + consumed`, which needs a known start.
///
/// Worked (#4360 fixture A): start 10 L, target 20 L, 10 L/100 km.
/// Station A, 2 km return at €1.80 → consumes 0.2 L, dispenses 10.2 L,
/// cash €18.36. Station B, 12 km at €1.70 → 1.2 L, 11.2 L, €19.04. B has
/// the cheaper pump and costs €0.68 MORE for the same final tank.
library;

import 'package:meta/meta.dart';

import 'data_value.dart';
import 'travel_estimate.dart';

/// What a purchase litre figure stands for.
enum RefuelQuantityMeaning { dispensed, netIncrease, targetFinal }

/// A purchase quantity with its meaning attached, end to end.
@immutable
class RefuelPurchaseQuantity {
  const RefuelPurchaseQuantity.dispensed(this.litres)
      : meaning = RefuelQuantityMeaning.dispensed;
  const RefuelPurchaseQuantity.netIncrease(this.litres)
      : meaning = RefuelQuantityMeaning.netIncrease;
  const RefuelPurchaseQuantity.targetFinal(this.litres)
      : meaning = RefuelQuantityMeaning.targetFinal;

  final RefuelQuantityMeaning meaning;
  final double litres;

  @override
  bool operator ==(Object other) =>
      other is RefuelPurchaseQuantity &&
      other.meaning == meaning &&
      other.litres == litres;

  @override
  int get hashCode => Object.hash(meaning, litres);
}

/// Why a trip could not be costed — each a named, explicit failure.
enum RefuelTripBlocker {
  /// A negative, NaN or infinite distance, price, consumption or level.
  invalidInput,
  noPrice,
  noConsumption,

  /// A reference price (#4348): nobody drives to a stand-in point.
  notAStation,

  /// [RefuelQuantityMeaning.targetFinal] without a known start level.
  unknownStartLevel,

  /// The start level cannot cover the outbound leg.
  cannotReachStation,

  /// The purchase would overflow the tank at the pump.
  exceedsCapacity,

  /// The target is below what the tank would hold without buying.
  targetBelowStart,
}

/// The inputs of one trip, with travel split into its two real legs.
@immutable
class RefuelTripInput {
  const RefuelTripInput({
    required this.outboundKm,
    required this.returnKm,
    required this.pricePerLitre,
    required this.consumptionLPer100km,
    required this.quantity,
    this.isPhysicalStation = true,
    this.travelIsRoad = false,
    this.consumptionIsEstimated = false,
    this.startLitres,
    this.capacityL,
    this.reserveLitres = 0,
    this.openingPricePerLitre,
    this.charges = const TravelCharges.unknown(),
  });

  /// Origin → station. From a #4359 road estimate when [travelIsRoad].
  final double outboundKm;

  /// Station → origin (0 for a one-way errand).
  final double returnKm;
  final double? pricePerLitre;
  final double? consumptionLPer100km;
  final RefuelPurchaseQuantity quantity;
  final bool isPhysicalStation;
  final bool travelIsRoad;
  final bool consumptionIsEstimated;
  final double? startLitres;
  final double? capacityL;
  final double reserveLitres;

  /// What the fuel already in the tank cost, when known. Only this can
  /// value the outbound leg honestly; without it [RefuelTripCost.
  /// consumedValue] is unknown rather than invented.
  final double? openingPricePerLitre;
  final TravelCharges charges;
}

/// The typed breakdown every consumer receives.
@immutable
class RefuelTripCost {
  const RefuelTripCost({
    required this.quantity,
    required this.pricePerLitre,
    required this.litresDispensed,
    required this.consumedLitres,
    required this.consumedValue,
    required this.travelKm,
    required this.travelIsRoad,
    required this.consumption,
    required this.charges,
    this.arrivalLitres,
    this.departureLitres,
    this.endLitres,
    this.arrivesBelowReserve = false,
  });

  /// The input quantity, meaning intact.
  final RefuelPurchaseQuantity quantity;
  final double pricePerLitre;
  final double litresDispensed;
  final double consumedLitres;

  /// Consumed fuel valued for explanation (see the library doc). Never
  /// part of [cashAtPump].
  final DataValue<double> consumedValue;
  final double travelKm;
  final bool travelIsRoad;

  /// The consumption figure used, with its provenance.
  final DataValue<double> consumption;
  final TravelCharges charges;

  /// Tank at each point of the sequence; null when the start is unknown.
  final double? arrivalLitres;
  final double? departureLitres;
  final double? endLitres;

  /// The outbound leg eats into the reserve — reachable, but flagged.
  final bool arrivesBelowReserve;

  /// Cash paid at the pump — each purchased litre counted once.
  double get cashAtPump => litresDispensed * pricePerLitre;

  /// Fuel gained over the whole trip: dispensed minus consumed.
  double get netChangeLitres => litresDispensed - consumedLitres;
}

/// A costed trip, or the reason there is none.
@immutable
class RefuelTripOutcome {
  const RefuelTripOutcome.costed(RefuelTripCost this.cost) : blocker = null;
  const RefuelTripOutcome.blocked(RefuelTripBlocker this.blocker)
      : cost = null;

  final RefuelTripCost? cost;
  final RefuelTripBlocker? blocker;
}

bool _bad(double? v) => v != null && (!v.isFinite || v < 0);

/// The arithmetic behind `RefuelEconomics.tripCost` — see the library doc.
RefuelTripOutcome computeRefuelTrip(RefuelTripInput i) {
  if (_bad(i.outboundKm) ||
      _bad(i.returnKm) ||
      _bad(i.startLitres) ||
      _bad(i.capacityL) ||
      _bad(i.reserveLitres) ||
      _bad(i.openingPricePerLitre) ||
      _bad(i.quantity.litres) ||
      (i.pricePerLitre != null && !i.pricePerLitre!.isFinite) ||
      (i.consumptionLPer100km != null && !i.consumptionLPer100km!.isFinite)) {
    return const RefuelTripOutcome.blocked(RefuelTripBlocker.invalidInput);
  }
  if (!i.isPhysicalStation) {
    return const RefuelTripOutcome.blocked(RefuelTripBlocker.notAStation);
  }
  final price = i.pricePerLitre;
  if (price == null || price <= 0) {
    return const RefuelTripOutcome.blocked(RefuelTripBlocker.noPrice);
  }
  final c = i.consumptionLPer100km;
  if (c == null || c <= 0) {
    return const RefuelTripOutcome.blocked(RefuelTripBlocker.noConsumption);
  }

  final outLitres = i.outboundKm * c / 100;
  final backLitres = i.returnKm * c / 100;
  final consumed = outLitres + backLitres;
  final start = i.startLitres;

  final double dispensed;
  switch (i.quantity.meaning) {
    case RefuelQuantityMeaning.dispensed:
      dispensed = i.quantity.litres;
    case RefuelQuantityMeaning.netIncrease:
      dispensed = i.quantity.litres + consumed;
    case RefuelQuantityMeaning.targetFinal:
      if (start == null) {
        return const RefuelTripOutcome.blocked(
            RefuelTripBlocker.unknownStartLevel);
      }
      final need = i.quantity.litres - start + consumed;
      if (need < 0) {
        return const RefuelTripOutcome.blocked(
            RefuelTripBlocker.targetBelowStart);
      }
      dispensed = need;
  }

  double? arrival, departure, end;
  if (start != null) {
    arrival = start - outLitres;
    if (arrival < 0) {
      return const RefuelTripOutcome.blocked(
          RefuelTripBlocker.cannotReachStation);
    }
    departure = arrival + dispensed;
    final cap = i.capacityL;
    if (cap != null && departure > cap + 1e-9) {
      return const RefuelTripOutcome.blocked(
          RefuelTripBlocker.exceedsCapacity);
    }
    end = departure - backLitres;
  }

  final opening = i.openingPricePerLitre;
  return RefuelTripOutcome.costed(RefuelTripCost(
    quantity: i.quantity,
    pricePerLitre: price,
    litresDispensed: dispensed,
    consumedLitres: consumed,
    // The outbound litres are old fuel: only its own price values them.
    consumedValue: opening == null
        ? const DataValue.unknown(reason: DataUnknownReason.notMeasuredYet)
        : DataValue.estimated(outLitres * opening + backLitres * price,
            basis: DataBasis.derived),
    travelKm: i.outboundKm + i.returnKm,
    travelIsRoad: i.travelIsRoad,
    consumption: i.consumptionIsEstimated
        ? DataValue.estimated(c, basis: DataBasis.fleetAverage)
        : DataValue.measured(c),
    charges: i.charges,
    arrivalLitres: arrival,
    departureLitres: departure,
    endLitres: end,
    arrivesBelowReserve: arrival != null && arrival < i.reserveLitres,
  ));
}

/// What choosing [trip] over [reference] saves in cash (negative: costs
/// more), or null when the two do not end in the same fuel state — the
/// only condition under which a cash difference is a journey saving
/// rather than a difference in what is left in the tank (#4360 rule 3).
double? netSavingAtEqualEnd(RefuelTripCost trip, RefuelTripCost reference) {
  if ((trip.netChangeLitres - reference.netChangeLitres).abs() > 1e-9) {
    return null;
  }
  return reference.cashAtPump - trip.cashAtPump;
}
