import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/trip_calculation.dart';

part 'calculator_provider.g.dart';

class CalculatorState {
  final double distanceKm;
  final double consumptionPer100Km;
  final double pricePerLiter;

  const CalculatorState({
    this.distanceKm = 0,
    this.consumptionPer100Km = 7.0,
    this.pricePerLiter = 0,
  });

  TripCalculation get calculation => TripCalculation(
        distanceKm: distanceKm,
        consumptionPer100Km: consumptionPer100Km,
        pricePerLiter: pricePerLiter,
      );

  bool get hasInput => distanceKm > 0 && consumptionPer100Km > 0 && pricePerLiter > 0;

  CalculatorState copyWith({
    double? distanceKm,
    double? consumptionPer100Km,
    double? pricePerLiter,
  }) {
    return CalculatorState(
      distanceKm: distanceKm ?? this.distanceKm,
      consumptionPer100Km: consumptionPer100Km ?? this.consumptionPer100Km,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
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

  void reset() {
    state = const CalculatorState();
  }
}
