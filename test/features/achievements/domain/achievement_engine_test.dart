import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';
import 'package:tankstellen/features/achievements/domain/achievement_engine.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

TripHistoryEntry _trip({
  required double km,
  int harshBrakes = 0,
  int harshAccels = 0,
  DateTime? startedAt,
}) {
  final start = startedAt ?? DateTime(2026, 1, 1);
  return TripHistoryEntry(
    id: start.toIso8601String(),
    vehicleId: null,
    summary: TripSummary(
      distanceKm: km,
      maxRpm: 2000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: harshBrakes,
      harshAccelerations: harshAccels,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 20)),
    ),
  );
}

FillUp _fillUp(String id) {
  return FillUp(
    id: id,
    stationId: 's',
    stationName: 'Station',
    date: DateTime(2026, 1, 1),
    liters: 40,
    totalCost: 60,
    odometerKm: 12345,
    fuelType: FuelType.e10,
  );
}

void main() {
  final engine = AchievementEngine();

  group('AchievementEngine (#781)', () {
    test('empty activity earns nothing', () {
      final earned = engine.evaluate(trips: const [], fillUps: const []);
      expect(earned, isEmpty);
    });

    test('one trip → firstTrip earned, firstFillUp not earned', () {
      final earned =
          engine.evaluate(trips: [_trip(km: 5)], fillUps: const []);
      expect(earned, contains(AchievementId.firstTrip));
      expect(earned, isNot(contains(AchievementId.firstFillUp)));
    });

    test('one fill-up → firstFillUp earned', () {
      final earned = engine.evaluate(
        trips: const [],
        fillUps: [_fillUp('a')],
      );
      expect(earned, contains(AchievementId.firstFillUp));
    });

    test('tenTrips requires exactly 10 trips — 9 not enough, 10 yes',
        () {
      final nine = List.generate(9, (_) => _trip(km: 5));
      final ten = List.generate(10, (_) => _trip(km: 5));
      expect(
        engine.evaluate(trips: nine, fillUps: const []),
        isNot(contains(AchievementId.tenTrips)),
      );
      expect(
        engine.evaluate(trips: ten, fillUps: const []),
        contains(AchievementId.tenTrips),
      );
    });

    test('zeroHarshTrip requires ≥10 km AND zero harsh events — '
        'short trips and any harsh event disqualify', () {
      // Short trip with 0 harsh events — doesn't count (trivially
      // clean because there was no chance to brake hard in 3 km).
      expect(
        engine.evaluate(
          trips: [_trip(km: 3)],
          fillUps: const [],
        ),
        isNot(contains(AchievementId.zeroHarshTrip)),
      );
      // Long trip with a single harsh brake — doesn't count.
      expect(
        engine.evaluate(
          trips: [_trip(km: 20, harshBrakes: 1)],
          fillUps: const [],
        ),
        isNot(contains(AchievementId.zeroHarshTrip)),
      );
      // Long trip with zero harsh events — counts.
      expect(
        engine.evaluate(
          trips: [_trip(km: 20)],
          fillUps: const [],
        ),
        contains(AchievementId.zeroHarshTrip),
      );
    });

    test('mixed activity earns every applicable badge in one call', () {
      final trips = [
        ...List.generate(10, (_) => _trip(km: 5)),
        _trip(km: 30),
      ];
      final fillUps = [_fillUp('a')];
      final earned = engine.evaluate(trips: trips, fillUps: fillUps);
      expect(earned, {
        AchievementId.firstTrip,
        AchievementId.firstFillUp,
        AchievementId.tenTrips,
        AchievementId.zeroHarshTrip,
      });
    });
  });
}
