import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/providers/alert_statistics_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

PriceAlert _makeAlert({
  String id = 'alert-1',
  bool isActive = true,
  DateTime? lastTriggeredAt,
}) {
  return PriceAlert(
    id: id,
    stationId: 'station-1',
    stationName: 'Test Station',
    fuelType: FuelType.e10,
    targetPrice: 1.50,
    isActive: isActive,
    lastTriggeredAt: lastTriggeredAt,
    createdAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('computeAlertStatistics', () {
    test('returns empty stats for empty list', () {
      final stats = computeAlertStatistics([]);

      expect(stats.totalAlerts, 0);
      expect(stats.activeAlerts, 0);
      expect(stats.triggeredToday, 0);
      expect(stats.triggeredThisWeek, 0);
    });

    test('counts total and active alerts correctly', () {
      final alerts = [
        _makeAlert(id: 'a1', isActive: true),
        _makeAlert(id: 'a2', isActive: true),
        _makeAlert(id: 'a3', isActive: false),
      ];

      final stats = computeAlertStatistics(alerts);

      expect(stats.totalAlerts, 3);
      expect(stats.activeAlerts, 2);
    });

    test('counts alerts triggered today', () {
      // Fix "now" to Wednesday 2026-04-07 at 14:00
      final now = DateTime(2026, 4, 7, 14, 0);

      final alerts = [
        _makeAlert(
          id: 'a1',
          lastTriggeredAt: DateTime(2026, 4, 7, 8, 0), // today morning
        ),
        _makeAlert(
          id: 'a2',
          lastTriggeredAt: DateTime(2026, 4, 7, 0, 0), // today midnight
        ),
        _makeAlert(
          id: 'a3',
          lastTriggeredAt: DateTime(2026, 4, 6, 23, 59), // yesterday
        ),
        _makeAlert(id: 'a4'), // never triggered
      ];

      final stats = computeAlertStatistics(alerts, now: now);

      expect(stats.triggeredToday, 2);
    });

    test('counts alerts triggered this week', () {
      // Fix "now" to Wednesday 2026-04-08 (weekday=3 → Monday=April 6)
      final now = DateTime(2026, 4, 8, 14, 0);

      final alerts = [
        _makeAlert(
          id: 'a1',
          lastTriggeredAt: DateTime(2026, 4, 8, 8, 0), // today (Wed)
        ),
        _makeAlert(
          id: 'a2',
          lastTriggeredAt: DateTime(2026, 4, 6, 10, 0), // Monday
        ),
        _makeAlert(
          id: 'a3',
          lastTriggeredAt: DateTime(2026, 4, 5, 23, 59), // Sunday (last week)
        ),
        _makeAlert(id: 'a4'), // never triggered
      ];

      final stats = computeAlertStatistics(alerts, now: now);

      expect(stats.triggeredThisWeek, 2);
      expect(stats.triggeredToday, 1);
    });

    test('alert triggered today also counts for this week', () {
      final now = DateTime(2026, 4, 7, 14, 0);

      final alerts = [
        _makeAlert(
          id: 'a1',
          lastTriggeredAt: DateTime(2026, 4, 7, 10, 0),
        ),
      ];

      final stats = computeAlertStatistics(alerts, now: now);

      expect(stats.triggeredToday, 1);
      expect(stats.triggeredThisWeek, 1);
    });

    test('inactive alerts with triggers are still counted in trigger stats', () {
      final now = DateTime(2026, 4, 7, 14, 0);

      final alerts = [
        _makeAlert(
          id: 'a1',
          isActive: false,
          lastTriggeredAt: DateTime(2026, 4, 7, 10, 0),
        ),
      ];

      final stats = computeAlertStatistics(alerts, now: now);

      expect(stats.activeAlerts, 0);
      expect(stats.triggeredToday, 1);
    });

    test('all alerts without triggers show zero triggered counts', () {
      final alerts = [
        _makeAlert(id: 'a1'),
        _makeAlert(id: 'a2'),
      ];

      final stats = computeAlertStatistics(alerts);

      expect(stats.totalAlerts, 2);
      expect(stats.triggeredToday, 0);
      expect(stats.triggeredThisWeek, 0);
    });

    test('Monday start-of-week boundary is correct', () {
      // Monday at midnight should be included in this week
      final now = DateTime(2026, 4, 8, 14, 0); // Wednesday
      final mondayStart = DateTime(2026, 4, 6, 0, 0); // Monday

      final alerts = [
        _makeAlert(id: 'a1', lastTriggeredAt: mondayStart),
      ];

      final stats = computeAlertStatistics(alerts, now: now);

      expect(stats.triggeredThisWeek, 1);
    });
  });

  group('AlertStatistics.empty', () {
    test('all fields are zero', () {
      const stats = AlertStatistics.empty();

      expect(stats.totalAlerts, 0);
      expect(stats.activeAlerts, 0);
      expect(stats.triggeredToday, 0);
      expect(stats.triggeredThisWeek, 0);
    });
  });
}
