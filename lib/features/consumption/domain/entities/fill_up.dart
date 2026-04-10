import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/co2_calculator.dart';
import '../../../search/domain/entities/fuel_type.dart';

part 'fill_up.freezed.dart';
part 'fill_up.g.dart';

/// A single fuel fill-up event logged by the user.
///
/// Stored locally via [ConsumptionRepository] and used to compute
/// [ConsumptionStats] like average consumption and total spend.
@freezed
abstract class FillUp with _$FillUp {
  const factory FillUp({
    required String id,
    required DateTime date,
    required double liters,
    required double totalCost,
    required double odometerKm,
    @FuelTypeJsonConverter() required FuelType fuelType,
    String? stationId,
    String? stationName,
    String? notes,
  }) = _FillUp;

  factory FillUp.fromJson(Map<String, dynamic> json) => _$FillUpFromJson(json);
}

/// Convenience getters for an individual fill-up.
extension FillUpX on FillUp {
  /// Price per liter in the store currency (e.g. EUR/L).
  double get pricePerLiter => liters > 0 ? totalCost / liters : 0;

  /// Estimated CO2 emissions for this fill-up, in kilograms.
  ///
  /// Computed from fuel type and volume via [Co2Calculator]. Returns 0
  /// for fuel types without a per-liter emission factor (electric,
  /// hydrogen, all).
  double get co2Kg => Co2Calculator.co2ForFillUp(this);
}
