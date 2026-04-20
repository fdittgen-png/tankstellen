import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/price_velocity_detector.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Price-velocity detector (#579). Pure function. Input: the
/// current prices + price history, plus configurable thresholds.
/// Output: a [VelocityAlert] when enough stations have dropped
/// fast enough, or null.
PriceRecord _record({
  required String stationId,
  required DateTime at,
  double? e10,
}) {
  return PriceRecord(stationId: stationId, recordedAt: at, e10: e10);
}

void main() {
  group('PriceVelocityDetector (#579)', () {
    final now = DateTime.utc(2026, 4, 19, 12);
    final hourAgo = now.subtract(const Duration(hours: 1));

    test(
        'fires when 2+ stations drop ≥3 ct on the alert fuel within the '
        'last hour', () {
      final history = [
        _record(stationId: 's1', at: hourAgo, e10: 1.899),
        _record(stationId: 's1', at: now, e10: 1.849), // -5 ct
        _record(stationId: 's2', at: hourAgo, e10: 1.920),
        _record(stationId: 's2', at: now, e10: 1.885), // -3.5 ct
        _record(stationId: 's3', at: hourAgo, e10: 1.799),
        _record(stationId: 's3', at: now, e10: 1.799), // no change
      ];
      final alert = PriceVelocityDetector.detect(
        fuelType: FuelType.e10,
        history: history,
        now: now,
      );
      expect(alert, isNotNull);
      expect(alert!.affectedStationIds, containsAll(['s1', 's2']));
      expect(alert.fuelType, FuelType.e10);
      expect(alert.maxDropCt, closeTo(5.0, 0.1));
    });

    test('returns null when only one station drops (threshold is 2)', () {
      final history = [
        _record(stationId: 's1', at: hourAgo, e10: 1.899),
        _record(stationId: 's1', at: now, e10: 1.849), // -5 ct
        _record(stationId: 's2', at: hourAgo, e10: 1.850),
        _record(stationId: 's2', at: now, e10: 1.850), // flat
      ];
      expect(
        PriceVelocityDetector.detect(
          fuelType: FuelType.e10,
          history: history,
          now: now,
        ),
        isNull,
      );
    });

    test(
        'returns null when drops are smaller than the configured '
        'minDropCt (default 3 ct)', () {
      final history = [
        _record(stationId: 's1', at: hourAgo, e10: 1.899),
        _record(stationId: 's1', at: now, e10: 1.889), // -1 ct
        _record(stationId: 's2', at: hourAgo, e10: 1.920),
        _record(stationId: 's2', at: now, e10: 1.905), // -1.5 ct
      ];
      expect(
        PriceVelocityDetector.detect(
          fuelType: FuelType.e10,
          history: history,
          now: now,
        ),
        isNull,
      );
    });

    test('ignores records older than the 1-hour window', () {
      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      final history = [
        // Old drops — should be ignored.
        _record(stationId: 's1', at: threeHoursAgo, e10: 1.899),
        _record(stationId: 's2', at: threeHoursAgo, e10: 1.920),
        // Current snapshots only — nothing in the last hour to compare.
        _record(stationId: 's1', at: now, e10: 1.849),
        _record(stationId: 's2', at: now, e10: 1.885),
      ];
      expect(
        PriceVelocityDetector.detect(
          fuelType: FuelType.e10,
          history: history,
          now: now,
          lookback: const Duration(hours: 1),
        ),
        isNull,
      );
    });

    test(
        'custom thresholds (minDropCt=2, minStations=3) require the '
        'higher bar', () {
      final history = [
        _record(stationId: 's1', at: hourAgo, e10: 1.899),
        _record(stationId: 's1', at: now, e10: 1.879), // -2 ct
        _record(stationId: 's2', at: hourAgo, e10: 1.920),
        _record(stationId: 's2', at: now, e10: 1.895), // -2.5 ct
      ];
      expect(
        PriceVelocityDetector.detect(
          fuelType: FuelType.e10,
          history: history,
          now: now,
          minDropCt: 2,
          minStations: 3,
        ),
        isNull,
      );
    });

    test('reads the right fuel column per FuelType', () {
      final history = [
        PriceRecord(
            stationId: 's1', recordedAt: hourAgo, e10: 1.0, diesel: 1.899),
        PriceRecord(
            stationId: 's1', recordedAt: now, e10: 1.0, diesel: 1.849),
        PriceRecord(
            stationId: 's2', recordedAt: hourAgo, e10: 1.0, diesel: 1.920),
        PriceRecord(
            stationId: 's2', recordedAt: now, e10: 1.0, diesel: 1.885),
      ];
      final alert = PriceVelocityDetector.detect(
        fuelType: FuelType.diesel,
        history: history,
        now: now,
      );
      expect(alert, isNotNull);
      expect(alert!.fuelType, FuelType.diesel);
    });

    test('empty / single-sample histories return null safely', () {
      expect(
        PriceVelocityDetector.detect(
          fuelType: FuelType.e10,
          history: const [],
          now: now,
        ),
        isNull,
      );
    });
  });
}
