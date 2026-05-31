// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure value object for a one-way fuel-cost calculation, plus the
/// derived figures the redesigned calculator surfaces (#2543):
/// cost-per-km and the round-trip total.
///
/// [distanceKm] is always the **one-way** distance the user entered —
/// the round-trip variant is a derived getter ([roundTripCost]) so the
/// switch never mutates the input the user typed.
class TripCalculation {
  final double distanceKm;
  final double consumptionPer100Km;
  final double pricePerLiter;

  const TripCalculation({
    required this.distanceKm,
    required this.consumptionPer100Km,
    required this.pricePerLiter,
  });

  /// Litres needed for the one-way trip.
  double get totalLiters => distanceKm * consumptionPer100Km / 100;

  /// Cost of the one-way trip in the active currency.
  double get totalCost => totalLiters * pricePerLiter;

  /// Cost per kilometre (guards a zero / negative distance so the
  /// breakdown tile renders `--` instead of NaN/Infinity).
  double get costPerKm => distanceKm > 0 ? totalCost / distanceKm : 0;

  /// Round-trip total — double the one-way cost. Derived, never an
  /// input mutation: the user's typed distance stays one-way.
  double get roundTripCost => totalCost * 2;

  /// Litres for the round trip — double the one-way litres.
  double get roundTripLiters => totalLiters * 2;

  /// Effective total honouring the round-trip flag — the single figure
  /// the result hero leads with. [roundTrip] true returns
  /// [roundTripCost], otherwise [totalCost].
  double effectiveCost({required bool roundTrip}) =>
      roundTrip ? roundTripCost : totalCost;

  /// Effective litres honouring the round-trip flag.
  double effectiveLiters({required bool roundTrip}) =>
      roundTrip ? roundTripLiters : totalLiters;

  /// Estimated monthly cost for [tripsPerMonth] repetitions of the
  /// effective (one-way or round-trip) trip. Returns 0 when
  /// [tripsPerMonth] is null or non-positive so the tile hides.
  double monthlyCost({required bool roundTrip, double? tripsPerMonth}) {
    if (tripsPerMonth == null || tripsPerMonth <= 0) return 0;
    return effectiveCost(roundTrip: roundTrip) * tripsPerMonth;
  }
}
