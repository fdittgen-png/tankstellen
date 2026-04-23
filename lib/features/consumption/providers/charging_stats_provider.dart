import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ev/domain/charging_cost_calculator.dart';
import '../../ev/domain/entities/charging_log.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import 'charging_logs_provider.dart';

part 'charging_stats_provider.g.dart';

/// Derived statistics over the user's charging-log history (#582 phase 2).
///
/// Phase 1 shipped the data layer ([ChargingLog] + store + notifier).
/// Phase 2 needs three rollup numbers per active vehicle — total kWh,
/// total spend, and the cost-weighted EUR/100 km average — surfaced on
/// the consumption screen's charging tab. Each derivation is a
/// standalone provider so the UI can rebuild just the affected card
/// when a single log is added/edited/removed.
///
/// All three providers return `null` (or `0.0`) when the dataset is
/// insufficient rather than throwing — the consumption tab renders "—"
/// for those cells. The wheel-lens savings story ("EUR/100 km") is a
/// nudge; it should never hide the fuel tab behind a red error.

/// Rolling EUR/100 km for the active vehicle's charging history.
///
/// Returns `null` when:
/// - there is no active vehicle,
/// - the active vehicle has fewer than two logged sessions (we need a
///   from/to odometer pair), or
/// - every derived segment would be zero-distance (back-to-back
///   sessions with no driving between them — rare but possible when a
///   user logs AC + DC legs of the same stop separately).
///
/// The weighted mean delegates to [ChargingCostCalculator.avgEurPer100km]
/// so the math lives in a single pure-Dart place the background
/// aggregator (phase 3) can reuse.
@riverpod
Future<double?> chargingEurPer100Km(Ref ref) async {
  final active = ref.watch(activeVehicleProfileProvider);
  if (active == null) return null;
  final logs =
      await ref.watch(chargingLogsForVehicleProvider(active.id).future);
  if (logs.length < 2) return null;

  // Sort oldest-first so consecutive logs define a driven segment.
  final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));

  final segLogs = <ChargingLog>[];
  final segments = <({int fromKm, int toKm})>[];
  for (var i = 1; i < sorted.length; i++) {
    final from = sorted[i - 1].odometerKm;
    final to = sorted[i].odometerKm;
    if (to <= from) continue; // Skip bad odometer sequences silently.
    segLogs.add(sorted[i]);
    segments.add((fromKm: from, toKm: to));
  }
  if (segLogs.isEmpty) return null;
  return ChargingCostCalculator.avgEurPer100km(segLogs, segments);
}

/// Total kWh delivered across the active vehicle's logged sessions.
///
/// Returns `0.0` when no logs exist — the UI renders "0.0 kWh" in that
/// case, matching the fuel side's "Total L" tile when the list is empty.
@riverpod
Future<double> chargingTotalKwh(Ref ref) async {
  final active = ref.watch(activeVehicleProfileProvider);
  if (active == null) return 0.0;
  final logs =
      await ref.watch(chargingLogsForVehicleProvider(active.id).future);
  return logs.fold<double>(0, (sum, log) => sum + log.kWh);
}

/// Total EUR spent across the active vehicle's logged sessions.
@riverpod
Future<double> chargingTotalCostEur(Ref ref) async {
  final active = ref.watch(activeVehicleProfileProvider);
  if (active == null) return 0.0;
  final logs =
      await ref.watch(chargingLogsForVehicleProvider(active.id).future);
  return logs.fold<double>(0, (sum, log) => sum + log.costEur);
}
