import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ev/domain/entities/charging_log.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import 'charging_logs_provider.dart';

part 'charging_charts_provider.g.dart';

/// Monthly total charging cost in EUR for the active vehicle, over
/// the last six months (#582 phase 3).
///
/// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
/// Missing months are included with a `0.0` value so the downstream
/// bar chart can render a continuous X axis without special-casing
/// empty months.
///
/// Watches [chargingLogsProvider] + [activeVehicleProfileProvider] so
/// it automatically refreshes when a new log lands or the user
/// switches vehicles. When no active vehicle is set or the logs
/// future is still loading/erroring, the provider returns an empty
/// map — the chart's empty state takes over.
@riverpod
Map<DateTime, double> chargingMonthlyCost(Ref ref) {
  final logsAsync = ref.watch(chargingLogsProvider);
  final vehicle = ref.watch(activeVehicleProfileProvider);
  if (vehicle == null) return const <DateTime, double>{};
  if (!logsAsync.hasValue) return const <DateTime, double>{};
  final logs = logsAsync.value!
      .where((log) => log.vehicleId == vehicle.id)
      .toList(growable: false);
  return rollupMonthlyCost(logs, now: DateTime.now().toUtc());
}

/// Monthly charging efficiency in kWh per 100 km for the active
/// vehicle, over the last six months (#582 phase 3).
///
/// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
/// Months with insufficient data to compute a ratio (< 2 logs in the
/// month, or zero distance driven between the segment anchors) map to
/// `null` so the line chart can skip the point instead of drawing a
/// misleading zero.
///
/// The ratio is a cost-weighted mean across the month:
///
///     sum(log.kWh for logs in month) / sum(kmDriven for logs in month) * 100
///
/// where `kmDriven` is the odometer delta from the prior log (either
/// within the same month or from the closest earlier log for the same
/// vehicle). This mirrors [ChargingCostCalculator.avgEurPer100km]'s
/// weighted-mean approach so short outings never dominate the axis.
@riverpod
Map<DateTime, double?> chargingMonthlyEfficiency(Ref ref) {
  final logsAsync = ref.watch(chargingLogsProvider);
  final vehicle = ref.watch(activeVehicleProfileProvider);
  if (vehicle == null) return const <DateTime, double?>{};
  if (!logsAsync.hasValue) return const <DateTime, double?>{};
  final all = logsAsync.value!
      .where((log) => log.vehicleId == vehicle.id)
      .toList(growable: false);
  return rollupMonthlyEfficiency(all, now: DateTime.now().toUtc());
}

/// Rollup of [logs] into a month-bucketed cost map.
///
/// Exposed (not `_`-prefixed) so the unit tests in
/// `test/features/consumption/providers/charging_charts_provider_test.dart`
/// can assert against it without pulling Hive + Riverpod into scope.
/// The provider wrappers above are thin — they only filter by active
/// vehicle and supply `now` — so reusing the same function in the
/// test matches what the UI sees.
Map<DateTime, double> rollupMonthlyCost(
  List<ChargingLog> logs, {
  required DateTime now,
}) {
  final months = _lastSixMonths(now);
  final result = <DateTime, double>{
    for (final m in months) m: 0.0,
  };
  for (final log in logs) {
    final key = _monthKey(log.date.toUtc());
    if (!result.containsKey(key)) continue;
    result[key] = (result[key] ?? 0) + log.costEur;
  }
  return result;
}

/// Rollup of [logs] into a month-bucketed kWh/100 km map (null =
/// insufficient data for that month). See [rollupMonthlyCost] for
/// the rationale behind exposing the helper directly.
Map<DateTime, double?> rollupMonthlyEfficiency(
  List<ChargingLog> logs, {
  required DateTime now,
}) {
  final months = _lastSixMonths(now);
  final result = <DateTime, double?>{
    for (final m in months) m: null,
  };
  // Logs are oldest-first from the store, but we don't assume; sort
  // defensively so the anchor lookup is correct regardless.
  final ordered = [...logs]
    ..sort((a, b) => a.date.compareTo(b.date));
  if (ordered.length < 2) return result;

  final buckets = <DateTime, ({double kwh, int km})>{};
  for (var i = 1; i < ordered.length; i++) {
    final cur = ordered[i];
    final prev = ordered[i - 1];
    final km = cur.odometerKm - prev.odometerKm;
    if (km <= 0) continue;
    final key = _monthKey(cur.date.toUtc());
    if (!result.containsKey(key)) continue;
    final acc = buckets[key] ?? (kwh: 0.0, km: 0);
    buckets[key] = (kwh: acc.kwh + cur.kWh, km: acc.km + km);
  }
  for (final entry in buckets.entries) {
    final km = entry.value.km;
    if (km <= 0) continue;
    result[entry.key] = entry.value.kwh / km * 100;
  }
  return result;
}

/// Last six UTC month starts, oldest first. `now` is the reference
/// month (its own bucket is included).
List<DateTime> _lastSixMonths(DateTime now) {
  final anchor = DateTime.utc(now.year, now.month, 1);
  return List.generate(
    6,
    (i) => DateTime.utc(anchor.year, anchor.month - (5 - i), 1),
    growable: false,
  );
}

DateTime _monthKey(DateTime date) =>
    DateTime.utc(date.year, date.month, 1);
