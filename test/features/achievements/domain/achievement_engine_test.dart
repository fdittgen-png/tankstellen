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
  String? id,
  double? fuelLitersConsumed,
}) {
  final start = startedAt ?? DateTime(2026, 1, 1);
  return TripHistoryEntry(
    id: id ?? start.toIso8601String(),
    vehicleId: null,
    summary: TripSummary(
      distanceKm: km,
      maxRpm: 2000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: harshBrakes,
      harshAccelerations: harshAccels,
      fuelLitersConsumed: fuelLitersConsumed,
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

  // #1041 phase 5 — three new achievements that consume pre-computed
  // metric maps the provider feeds in. Engine tests stay pure: build
  // synthetic trips + maps and check the rule.
  group('AchievementEngine — smoothDriver (#1041 phase 5)', () {
    test('5 consecutive ordered trips with score >= 80 earns the badge',
        () {
      final base = DateTime(2026, 3, 1);
      final trips = [
        for (var i = 0; i < 5; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
          ),
      ];
      final scores = {for (var i = 0; i < 5; i++) 'trip-$i': 85};
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      expect(earned, contains(AchievementId.smoothDriver));
    });

    test('4 consecutive trips is not enough — 5 is the threshold', () {
      final base = DateTime(2026, 3, 1);
      final trips = [
        for (var i = 0; i < 4; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
          ),
      ];
      final scores = {for (var i = 0; i < 4; i++) 'trip-$i': 95};
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      expect(earned, isNot(contains(AchievementId.smoothDriver)));
    });

    test('a single sub-80 trip in the middle resets the streak', () {
      final base = DateTime(2026, 3, 1);
      final trips = [
        for (var i = 0; i < 6; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
          ),
      ];
      // 80, 80, 70 (resets), 80, 80, 80 — only 4 in a row, not 5.
      final scores = {
        'trip-0': 80,
        'trip-1': 80,
        'trip-2': 70,
        'trip-3': 80,
        'trip-4': 80,
        'trip-5': 80,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      expect(earned, isNot(contains(AchievementId.smoothDriver)));
    });

    test('score exactly at 80 (the threshold) qualifies — boundary edge',
        () {
      final base = DateTime(2026, 3, 1);
      final trips = [
        for (var i = 0; i < 5; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
          ),
      ];
      final scores = {for (var i = 0; i < 5; i++) 'trip-$i': 80};
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      expect(earned, contains(AchievementId.smoothDriver));
    });

    test('score 79 (just below threshold) does not qualify', () {
      final base = DateTime(2026, 3, 1);
      final trips = [
        for (var i = 0; i < 5; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
          ),
      ];
      final scores = {for (var i = 0; i < 5; i++) 'trip-$i': 79};
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      expect(earned, isNot(contains(AchievementId.smoothDriver)));
    });

    test('a 15-day gap between adjacent trips breaks the streak', () {
      final base = DateTime(2026, 3, 1);
      // Trip 2 sits 15 days after trip 1 — exceeds the 14-day max
      // gap, so the streak resets at that point.
      final dayOffsets = [0, 1, 16, 17, 18, 19];
      final trips = [
        for (var i = 0; i < dayOffsets.length; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: dayOffsets[i])),
            id: 'trip-$i',
          ),
      ];
      final scores = {
        for (var i = 0; i < dayOffsets.length; i++) 'trip-$i': 95,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      // After the gap, trips 2..5 are only 4 in a row.
      expect(earned, isNot(contains(AchievementId.smoothDriver)));
    });

    test('trips arrive out of order — engine sorts before checking',
        () {
      final base = DateTime(2026, 3, 1);
      final orderedDays = [4, 0, 2, 1, 3];
      final trips = [
        for (var i = 0; i < 5; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: orderedDays[i])),
            id: 'trip-$i',
          ),
      ];
      final scores = {for (var i = 0; i < 5; i++) 'trip-$i': 95};
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
      );
      expect(earned, contains(AchievementId.smoothDriver));
    });
  });

  group('AchievementEngine — coldStartAware (#1041 phase 5)', () {
    test('one month with cold-start excess <2% of total fuel earns it',
        () {
      final base = DateTime(2026, 5, 5);
      final trips = [
        for (var i = 0; i < 4; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
            fuelLitersConsumed: 5.0,
          ),
      ];
      // Total fuel = 20 L, total cold-start excess = 0.3 L = 1.5 %.
      final coldStart = {
        'trip-0': 0.1,
        'trip-1': 0.1,
        'trip-2': 0.05,
        'trip-3': 0.05,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        coldStartExcessLByTripId: coldStart,
      );
      expect(earned, contains(AchievementId.coldStartAware));
    });

    test('exactly 2% cold-start ratio does not qualify (strict <2%)',
        () {
      final base = DateTime(2026, 5, 5);
      final trips = [
        for (var i = 0; i < 4; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
            fuelLitersConsumed: 5.0,
          ),
      ];
      // 0.4 L / 20 L = exactly 2%.
      final coldStart = {
        'trip-0': 0.1,
        'trip-1': 0.1,
        'trip-2': 0.1,
        'trip-3': 0.1,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        coldStartExcessLByTripId: coldStart,
      );
      expect(earned, isNot(contains(AchievementId.coldStartAware)));
    });

    test('months with fewer than 3 trips are skipped — '
        'two clean trips still do not earn the badge', () {
      final base = DateTime(2026, 5, 5);
      final trips = [
        for (var i = 0; i < 2; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
            fuelLitersConsumed: 5.0,
          ),
      ];
      final coldStart = {'trip-0': 0.0, 'trip-1': 0.0};
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        coldStartExcessLByTripId: coldStart,
      );
      expect(earned, isNot(contains(AchievementId.coldStartAware)));
    });

    test('a high-cold-start month elsewhere does not block a clean '
        'month — once-earned-always-earned across the whole log',
        () {
      final goodMonth = DateTime(2026, 5, 5);
      final badMonth = DateTime(2026, 6, 5);
      final trips = [
        for (var i = 0; i < 3; i++)
          _trip(
            km: 12,
            startedAt: goodMonth.add(Duration(days: i)),
            id: 'good-$i',
            fuelLitersConsumed: 5.0,
          ),
        for (var i = 0; i < 3; i++)
          _trip(
            km: 12,
            startedAt: badMonth.add(Duration(days: i)),
            id: 'bad-$i',
            fuelLitersConsumed: 5.0,
          ),
      ];
      final coldStart = {
        'good-0': 0.05,
        'good-1': 0.05,
        'good-2': 0.05,
        // bad month is 10% cold-start.
        'bad-0': 0.5,
        'bad-1': 0.5,
        'bad-2': 0.5,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        coldStartExcessLByTripId: coldStart,
      );
      expect(earned, contains(AchievementId.coldStartAware));
    });

    test('months with no fuel-rate samples (null fuelLitersConsumed) '
        'are skipped — engine cannot compute a ratio', () {
      final base = DateTime(2026, 5, 5);
      final trips = [
        for (var i = 0; i < 4; i++)
          _trip(
            km: 12,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
            // No fuelLitersConsumed — pre-#1040 trips.
          ),
      ];
      final coldStart = {
        'trip-0': 0.0,
        'trip-1': 0.0,
        'trip-2': 0.0,
        'trip-3': 0.0,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        coldStartExcessLByTripId: coldStart,
      );
      expect(earned, isNot(contains(AchievementId.coldStartAware)));
    });
  });

  group('AchievementEngine — highwayMaster (#1041 phase 5)', () {
    test('30 km trip with score >= 90 and tight std-dev earns the badge',
        () {
      final t = _trip(km: 30, id: 'h1');
      final earned = engine.evaluate(
        trips: [t],
        fillUps: const [],
        scoresByTripId: const {'h1': 92},
        speedStdDevByTripId: const {'h1': 5.0},
      );
      expect(earned, contains(AchievementId.highwayMaster));
    });

    test('29.9 km trip does not qualify — distance threshold strict',
        () {
      final t = _trip(km: 29.9, id: 'h1');
      final earned = engine.evaluate(
        trips: [t],
        fillUps: const [],
        scoresByTripId: const {'h1': 95},
        speedStdDevByTripId: const {'h1': 3.0},
      );
      expect(earned, isNot(contains(AchievementId.highwayMaster)));
    });

    test('score 89 does not qualify — score threshold is 90', () {
      final t = _trip(km: 50, id: 'h1');
      final earned = engine.evaluate(
        trips: [t],
        fillUps: const [],
        scoresByTripId: const {'h1': 89},
        speedStdDevByTripId: const {'h1': 3.0},
      );
      expect(earned, isNot(contains(AchievementId.highwayMaster)));
    });

    test('std-dev 8.5 km/h does not qualify — tightness threshold is '
        '8 km/h', () {
      final t = _trip(km: 50, id: 'h1');
      final earned = engine.evaluate(
        trips: [t],
        fillUps: const [],
        scoresByTripId: const {'h1': 95},
        speedStdDevByTripId: const {'h1': 8.5},
      );
      expect(earned, isNot(contains(AchievementId.highwayMaster)));
    });

    test('std-dev exactly 8 km/h qualifies — boundary edge', () {
      final t = _trip(km: 50, id: 'h1');
      final earned = engine.evaluate(
        trips: [t],
        fillUps: const [],
        scoresByTripId: const {'h1': 95},
        speedStdDevByTripId: const {'h1': 8.0},
      );
      expect(earned, contains(AchievementId.highwayMaster));
    });

    test('missing std-dev entry treated as +inf — does not qualify',
        () {
      final t = _trip(km: 50, id: 'h1');
      final earned = engine.evaluate(
        trips: [t],
        fillUps: const [],
        scoresByTripId: const {'h1': 95},
        // empty speedStdDevByTripId — legacy trip without samples.
      );
      expect(earned, isNot(contains(AchievementId.highwayMaster)));
    });

    test('one qualifying trip among many earns the badge', () {
      final base = DateTime(2026, 1, 1);
      final trips = [
        // 9 ordinary city trips.
        for (var i = 0; i < 9; i++)
          _trip(
            km: 5,
            startedAt: base.add(Duration(days: i)),
            id: 'city-$i',
          ),
        // One long highway run.
        _trip(km: 50, startedAt: base.add(const Duration(days: 9)), id: 'h1'),
      ];
      final scores = {
        for (var i = 0; i < 9; i++) 'city-$i': 70,
        'h1': 95,
      };
      final stdDevs = <String, double>{
        for (var i = 0; i < 9; i++) 'city-$i': 12.0,
        'h1': 4.0,
      };
      final earned = engine.evaluate(
        trips: trips,
        fillUps: const [],
        scoresByTripId: scores,
        speedStdDevByTripId: stdDevs,
      );
      expect(earned, contains(AchievementId.highwayMaster));
    });
  });

  group('AchievementEngine — phase 5 metric maps default safely', () {
    test('omitting all maps = no phase-5 badges earned', () {
      // 5 ordered trips with no score map → smoothDriver cannot fire.
      final base = DateTime(2026, 3, 1);
      final trips = [
        for (var i = 0; i < 5; i++)
          _trip(
            km: 30,
            startedAt: base.add(Duration(days: i)),
            id: 'trip-$i',
            fuelLitersConsumed: 5.0,
          ),
      ];
      final earned = engine.evaluate(trips: trips, fillUps: const []);
      expect(earned, isNot(contains(AchievementId.smoothDriver)));
      expect(earned, isNot(contains(AchievementId.coldStartAware)));
      expect(earned, isNot(contains(AchievementId.highwayMaster)));
    });
  });
}
