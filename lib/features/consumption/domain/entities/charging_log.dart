import 'package:freezed_annotation/freezed_annotation.dart';

part 'charging_log.freezed.dart';
part 'charging_log.g.dart';

/// One EV charging session logged by the user (#582).
///
/// Sibling to [FillUp] for petrol/diesel cars. Keeps its own entity
/// rather than reusing FillUp because the economics are different
/// (kWh not litres, optional charge-time, network operator as the
/// identity rather than the station brand).
@freezed
abstract class ChargingLog with _$ChargingLog {
  const factory ChargingLog({
    required String id,
    required DateTime date,
    required double kwh,
    required double totalCost,
    required double odometerKm,
    /// Optional charging duration in minutes. Some users log every
    /// session, others only track kWh + cost. Null when unrecorded.
    int? chargeTimeMin,
    String? stationId,
    String? stationName,
    /// Operator / network (Ionity, Shell Recharge, Tesla, etc.).
    /// Optional because OCM doesn't always carry one.
    String? operator,
    String? notes,
    /// Reference to the vehicle that was charged (#694). Null means
    /// the user logged the session without attributing it.
    String? vehicleId,
  }) = _ChargingLog;

  const ChargingLog._();

  factory ChargingLog.fromJson(Map<String, dynamic> json) =>
      _$ChargingLogFromJson(json);

  /// Price per kWh at the time of the session. Zero-safe.
  double get pricePerKwh => kwh > 0 ? totalCost / kwh : 0;
}

/// Convenience helpers for a charging session — mirrors the [FillUpX]
/// extension on fuel fill-ups so UI code can render either entity with
/// the same field names.
extension ChargingLogX on ChargingLog {
  /// Rough EUR-per-100-km using an optional [consumptionKwhPer100Km].
  /// Returns null when no per-100 km figure is supplied — the UI
  /// prefers vehicle-specific consumption to a global constant.
  double? costPer100Km({required double? consumptionKwhPer100Km}) {
    if (consumptionKwhPer100Km == null || consumptionKwhPer100Km <= 0) {
      return null;
    }
    if (kwh <= 0) return null;
    final eurPerKwh = totalCost / kwh;
    return eurPerKwh * consumptionKwhPer100Km;
  }
}
