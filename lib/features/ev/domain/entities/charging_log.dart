import 'package:freezed_annotation/freezed_annotation.dart';

part 'charging_log.freezed.dart';
part 'charging_log.g.dart';

/// One EV charging session logged by the user (#582 phase 1).
///
/// Sibling to `FillUp` for petrol/diesel vehicles — different
/// economics (kWh instead of litres, mandatory charge-time for the
/// "how long did you wait" lens) and different provenance (optional
/// link to an OCM charging station when the log was opened from the
/// EV station-detail screen in phase 2).
///
/// Stored as a JSON payload inside the shared encrypted `settings`
/// Hive box keyed by `charging_log:<id>` — see [ChargingLogStore]. The
/// entity stays UI- and persistence-agnostic so it can be imported
/// from a background isolate (WorkManager, future Supabase sync)
/// without dragging Riverpod or Flutter in.
///
/// ### Shape change from phase-0
/// The earlier scratch entity (deleted in this PR) lived under
/// `features/consumption/domain/entities/`, used `kwh` / `totalCost`
/// and made `chargeTimeMin` + `vehicleId` optional. The issue #582
/// specification pins the field list to `kWh` (camel-cased),
/// `costEur`, non-null `chargeTimeMin`, non-null `vehicleId`, and
/// adds `chargingStationId` as the optional OCM link. This PR
/// rewrites the entity to match — see the PR body for the precedent
/// (PR #853 followed the same path).
@freezed
abstract class ChargingLog with _$ChargingLog {
  const factory ChargingLog({
    required String id,

    /// Vehicle that was charged. Required so per-vehicle EUR/100km
    /// analytics (phase 2) always have a grouping key.
    required String vehicleId,

    /// Session timestamp. UTC is preferred so the phase-2 charts
    /// line up across timezones, but the store persists whatever the
    /// caller supplies.
    required DateTime date,

    /// Energy delivered during the session, in kilowatt-hours.
    required double kWh,

    /// Total amount paid for the session in euros. Keeping the
    /// currency implicit mirrors the rest of the app — euro-only
    /// until multi-currency lands.
    required double costEur,

    /// How long the car was plugged in, in whole minutes. Non-null
    /// because "how long did that fast charge take?" is part of the
    /// wheel-lens value prop — if the user genuinely doesn't know,
    /// zero is the right sentinel (counts as "unreported" in
    /// downstream analytics).
    required int chargeTimeMin,

    /// Odometer reading at the end of the session, in kilometres.
    /// Drives the EUR/100km and kWh/100km calculations in
    /// [ChargingCostCalculator] when paired with the previous log's
    /// odometer.
    required int odometerKm,

    /// Free-form station label. Pre-filled when the log is opened
    /// from the EV-station-detail screen in phase 2; editable
    /// otherwise. Null when the user never typed one.
    String? stationName,

    /// Optional link to the OCM charging station id — populated only
    /// when the log was opened from the EV-station-detail screen.
    /// Kept alongside [stationName] so phase-2 analytics can aggregate
    /// by station without relying on free-form strings.
    String? chargingStationId,
  }) = _ChargingLog;

  factory ChargingLog.fromJson(Map<String, dynamic> json) =>
      _$ChargingLogFromJson(json);
}
