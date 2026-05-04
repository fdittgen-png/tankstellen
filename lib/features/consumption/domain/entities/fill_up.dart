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

    /// Whether this fill-up is an auto-generated correction entry that
    /// closes the gap between OBD-recorded trip fuel and pumped liters
    /// over a plein-to-plein window (#1361). Correction entries are
    /// rendered orange in the fill-up list and are user-editable.
    /// Defaults `false` so existing fill-ups deserialise unchanged.
    @Default(false) bool isCorrection,

    /// Tank level in litres read from OBD2 immediately before the pump
    /// started (#1401 phase 7a). Used by the upcoming reconciliation
    /// flow to verify pumped litres against tank-delta and surface a
    /// "verified by adapter" badge. Null when not captured — phone away
    /// from the car, no adapter paired, fuel-level PID unsupported, or
    /// the user logged the fill-up after the fact. Existing fill-ups
    /// deserialise with null so historical data keeps working.
    double? fuelLevelBeforeL,

    /// Tank level in litres read from OBD2 after the pump finished
    /// (#1401 phase 7a). Paired with [fuelLevelBeforeL] to compute the
    /// adapter-measured tank delta and compare it against the pumped
    /// volume. Null when not captured for the same reasons as
    /// [fuelLevelBeforeL]. Existing fill-ups deserialise with null so
    /// historical data keeps working.
    double? fuelLevelAfterL,
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
