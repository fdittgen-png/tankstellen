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

    test('ecoWeek: 7 consecutive days with one zero-harsh ≥10 km '
        'trip each earns the badge', () {
      final base = DateTime(2026, 4, 1);
      final trips = [
        for (var i = 0; i < 7; i++)
          _trip(km: 15, startedAt: base.add(Duration(days: i))),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      expect(earned, contains(AchievementId.ecoWeek));
    });

    test('ecoWeek: 6 consecutive days is not enough', () {
      final base = DateTime(2026, 4, 1);
      final trips = [
        for (var i = 0; i < 6; i++)
          _trip(km: 15, startedAt: base.add(Duration(days: i))),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      expect(earned, isNot(contains(AchievementId.ecoWeek)));
    });

    test('ecoWeek: a gap day breaks the streak', () {
      final base = DateTime(2026, 4, 1);
      final trips = [
        // Days 0, 1, 2 — then skip day 3 — days 4..8 (5 more)
        for (var i in [0, 1, 2, 4, 5, 6, 7, 8])
          _trip(km: 15, startedAt: base.add(Duration(days: i))),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      // The 4..8 run is only 5 days, not 7, and the 0..2 run is 3.
      expect(earned, isNot(contains(AchievementId.ecoWeek)));
    });

    test('ecoWeek: a rolling 7-day window in older data still '
        'counts — once earned, always earned, even if today has a '
        'streak-breaking day', () {
      final base = DateTime(2026, 1, 1);
      final trips = [
        // An old 7-day run
        for (var i = 0; i < 7; i++)
          _trip(km: 15, startedAt: base.add(Duration(days: i))),
        // …followed by a harsh trip much later (doesn't unset the
        // prior streak).
        _trip(km: 20, harshBrakes: 2, startedAt: DateTime(2026, 4, 1)),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      expect(earned, contains(AchievementId.ecoWeek));
    });

    test('ecoWeek: short trips in a 7-day run do not count — only '
        '≥10 km zero-harsh trips flag a day as eco', () {
      final base = DateTime(2026, 4, 1);
      final trips = [
        for (var i = 0; i < 7; i++)
          _trip(km: 3, startedAt: base.add(Duration(days: i))),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      expect(earned, isNot(contains(AchievementId.ecoWeek)));
    });

    test('ecoWeek: multiple trips in one day only count that day '
        'once — 7 qualifying trips all on the same day are not a '
        'week', () {
      final base = DateTime(2026, 4, 1);
      final trips = [
        for (var i = 0; i < 7; i++)
          _trip(
            km: 15,
            startedAt: base.add(Duration(hours: i * 2)),
          ),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      expect(earned, isNot(contains(AchievementId.ecoWeek)));
    });
  });
}
