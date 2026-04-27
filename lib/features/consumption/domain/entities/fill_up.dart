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
    /// Optional reference to the [VehicleProfile] this fill-up belongs to
    /// (#694). Null means the user logged the fill-up without attributing
    /// it to a specific vehicle. Used to group per-vehicle stats and to
    /// pre-fill the next log entry.
    String? vehicleId,

    /// OBD2 trip-history ids that were recorded for this vehicle since
    /// the previous fill-up (#888). Populated automatically by the
    /// `FillUpList.add` path: trajets are first-class, standalone
    /// recordings, and the link from tank-to-tank is derived on save
    /// rather than baked into the trip flow. Empty when no trajets
    /// were recorded in the window or when the fill-up has no bound
    /// vehicle.
    @Default(<String>[]) List<String> linkedTripIds,

    /// Whether this fill-up topped the tank up to capacity (#1195).
    ///
    /// Default `true` matches the typical European "plein" pattern —
    /// most users fill all the way up. The flag governs how the tank-
    /// level estimator initialises after this fill-up: when `true`, the
    /// estimator resets to the vehicle's `tankCapacityL`; when `false`,
    /// it uses `previous_level + liters_added` (partial top-up).
    /// Existing fill-ups deserialise with the default so historical
    /// data keeps working as full-tank fills.
    @Default(true) bool isFullTank,
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
