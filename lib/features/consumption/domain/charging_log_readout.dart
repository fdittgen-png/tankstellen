import '../../ev/domain/charging_cost_calculator.dart';
import '../../ev/domain/entities/charging_log.dart';

/// Shape of the EUR/100 km + kWh/100 km readout shown beneath the
/// cost field on the Add-Charging-Log form. Pulled out of
/// `add_charging_log_screen.dart` (#582 phase 2 follow-up) so the
/// derivation rule is a pure function with its own unit tests
/// instead of a private method on a stateful widget.
///
/// Three states the panel needs to render:
///
///  * `null` — inputs are incomplete or unparseable; hide the panel.
///  * [ChargingLogReadout.empty] — inputs are complete but there's no
///    prior log to anchor the distance. Render the helper text
///    instead of numbers.
///  * fully-populated — render the formatted EUR/kWh per-100-km line.
class ChargingLogReadout {
  final double? eurPer100km;
  final double? kwhPer100km;

  const ChargingLogReadout({
    required this.eurPer100km,
    required this.kwhPer100km,
  });

  const ChargingLogReadout.empty()
      : eurPer100km = null,
        kwhPer100km = null;

  bool get hasValues => eurPer100km != null && kwhPer100km != null;
}

/// Compute the readout for a hypothetical log carrying the form's
/// current inputs, comparing against the most-recent prior log for
/// the selected vehicle.
///
/// Returns `null` when:
///   * no vehicle is selected
///   * any of [kWhText], [costText], [odometerText] is null,
///     unparseable, or non-positive
///   * the prior-logs list is null (still loading)
///
/// Returns [ChargingLogReadout.empty] when:
///   * inputs parse cleanly but there's no prior log for this vehicle
///   * the most-recent prior log has the same or higher odometer
///     (i.e. zero distance driven since)
///
/// Otherwise returns a fully-populated [ChargingLogReadout].
ChargingLogReadout? computeChargingLogReadout({
  required String? vehicleId,
  required String kWhText,
  required String costText,
  required String odometerText,
  required DateTime date,
  required List<ChargingLog>? allLogs,
}) {
  if (vehicleId == null) return null;
  final kWh = double.tryParse(kWhText.replaceAll(',', '.'));
  final cost = double.tryParse(costText.replaceAll(',', '.'));
  final parsedOdo = int.tryParse(
    odometerText.replaceAll(',', '.').split('.').first,
  );
  if (kWh == null || kWh <= 0) return null;
  if (cost == null || cost <= 0) return null;
  if (parsedOdo == null || parsedOdo <= 0) return null;
  // Local non-nullable copy — Dart's flow analysis does not promote
  // captured nullable locals inside closures like [firstWhere].
  final int odo = parsedOdo;

  if (allLogs == null) return null;
  final prior = allLogs
      .where((log) => log.vehicleId == vehicleId)
      .toList(growable: false);
  if (prior.isEmpty) return const ChargingLogReadout.empty();

  // Prior logs are oldest-first; the anchor is the most recent one
  // with odometer < odo (i.e. driven since then).
  final candidate = prior.reversed.firstWhere(
    (log) => log.odometerKm < odo,
    orElse: () => prior.last,
  );
  final int kmDriven = odo - candidate.odometerKm;
  if (kmDriven <= 0) return const ChargingLogReadout.empty();

  final preview = ChargingLog(
    id: 'preview',
    vehicleId: vehicleId,
    date: date,
    kWh: kWh,
    costEur: cost,
    chargeTimeMin: 0,
    odometerKm: odo,
  );
  final eurPer100 = ChargingCostCalculator.eurPer100km(
    preview,
    kmDriven: kmDriven,
  );
  final kwhPer100 = ChargingCostCalculator.kWhPer100km(
    preview,
    kmDriven: kmDriven,
  );
  return ChargingLogReadout(
    eurPer100km: eurPer100,
    kwhPer100km: kwhPer100,
  );
}
