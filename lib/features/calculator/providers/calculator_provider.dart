// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/trip_calculation.dart';

part 'calculator_provider.g.dart';

/// Immutable input state for the fuel-cost calculator.
///
/// [consumptionPer100Km] defaults to a sensible 7.0 so a cold-open
/// calculator already has a plausible figure the user can override.
/// [roundTrip] / [tripsPerMonth] drive the derived figures in
/// [TripCalculation] without ever mutating the entered distance (#2543).
class CalculatorState {
  final double distanceKm;
  final double consumptionPer100Km;
  final double pricePerLiter;

  /// When true the result hero leads with the round-trip total
  /// (`2 ×` the one-way cost). Stored as a flag — the one-way
  /// [distanceKm] the user typed is never doubled.
  final bool roundTrip;

  /// Optional trips-per-month estimate driving the cost/month tile.
  /// Null = the user has not entered a value, so the tile hides.
  final double? tripsPerMonth;

  const CalculatorState({
    this.distanceKm = 0,
    this.consumptionPer100Km = 7.0,
    this.pricePerLiter = 0,
    this.roundTrip = false,
    this.tripsPerMonth,
  });

  TripCalculation get calculation => TripCalculation(
        distanceKm: distanceKm,
        consumptionPer100Km: consumptionPer100Km,
        pricePerLiter: pricePerLiter,
      );

  bool get hasInput =>
      distanceKm > 0 && consumptionPer100Km > 0 && pricePerLiter > 0;

  /// Sentinel for [copyWith] so callers can distinguish "leave
  /// [tripsPerMonth] unchanged" (default) from "clear it to null".
  static const Object _unset = Object();

  CalculatorState copyWith({
    double? distanceKm,
    double? consumptionPer100Km,
    double? pricePerLiter,
    bool? roundTrip,
    Object? tripsPerMonth = _unset,
  }) {
    return CalculatorState(
      distanceKm: distanceKm ?? this.distanceKm,
      consumptionPer100Km: consumptionPer100Km ?? this.consumptionPer100Km,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      roundTrip: roundTrip ?? this.roundTrip,
      tripsPerMonth: identical(tripsPerMonth, _unset)
          ? this.tripsPerMonth
          : tripsPerMonth as double?,
    );
  }
}

@riverpod
class Calculator extends _$Calculator {
  @override
  CalculatorState build() => const CalculatorState();

  void setDistance(double value) {
    state = state.copyWith(distanceKm: value);
  }

  void setConsumption(double value) {
    state = state.copyWith(consumptionPer100Km: value);
  }

  void setPrice(double value) {
    state = state.copyWith(pricePerLiter: value);
  }

  void setRoundTrip(bool value) {
    state = state.copyWith(roundTrip: value);
  }

  /// Set the trips-per-month estimate. A non-positive value clears it
  /// (passing `0` from an emptied field hides the cost/month tile).
  void setTripsPerMonth(double? value) {
    state = state.copyWith(
      tripsPerMonth: (value != null && value > 0) ? value : null,
    );
  }

  void reset() {
    state = const CalculatorState();
  }
}
