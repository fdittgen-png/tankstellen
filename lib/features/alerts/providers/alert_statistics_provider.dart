import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/price_alert.dart';
import 'alert_provider.dart';

part 'alert_statistics_provider.g.dart';

/// Computed statistics about the user's price alerts.
class AlertStatistics {
  final int totalAlerts;
  final int activeAlerts;
  final int triggeredToday;
  final int triggeredThisWeek;

  const AlertStatistics({
    required this.totalAlerts,
    required this.activeAlerts,
    required this.triggeredToday,
    required this.triggeredThisWeek,
  });

  const AlertStatistics.empty()
      : totalAlerts = 0,
        activeAlerts = 0,
        triggeredToday = 0,
        triggeredThisWeek = 0;
}

/// Computes [AlertStatistics] from the current alert list.
///
/// Uses [DateTime.now] by default but accepts an override for testing.
AlertStatistics computeAlertStatistics(
  List<PriceAlert> alerts, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final todayStart = DateTime(currentTime.year, currentTime.month, currentTime.day);
  final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));

  int activeCount = 0;
  int triggeredToday = 0;
  int triggeredThisWeek = 0;

  for (final alert in alerts) {
    if (alert.isActive) activeCount++;

    final triggered = alert.lastTriggeredAt;
    if (triggered == null) continue;

    if (!triggered.isBefore(todayStart)) {
      triggeredToday++;
    }
    if (!triggered.isBefore(weekStart)) {
      triggeredThisWeek++;
    }
  }

  return AlertStatistics(
    totalAlerts: alerts.length,
    activeAlerts: activeCount,
    triggeredToday: triggeredToday,
    triggeredThisWeek: triggeredThisWeek,
  );
}

@riverpod
AlertStatistics alertStatistics(Ref ref) {
  final alerts = ref.watch(alertProvider);
  return computeAlertStatistics(alerts);
}
