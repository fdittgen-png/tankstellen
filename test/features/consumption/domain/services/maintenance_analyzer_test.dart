import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/maintenance_suggestion.dart';
import 'package:tankstellen/features/consumption/domain/services/maintenance_analyzer.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic coverage for `analyzeMaintenance` (#1124).
///
/// The analyzer's contract: feed it a list of [TripHistoryEntry] plus a
/// `now` clock, get back a list of [MaintenanceSuggestion]s. Tests are
/// split into:
///
///   * Empty / under-the-gate inputs → empty result (no creep, no
///     deviation, sample count below minimum).
///   * Window-edge behaviour — trips outside the 30-day window are
///     ignored.
///   * Idle-RPM creep heuristic — fires when second-half median RPM
///     is > 8 % above first-half, doesn't fire when it isn't.
///   * MAF-deviation (cruise fuel rate) heuristic — fires on a >10 %
///     drop, doesn't fire on a smaller one.
///   * Combined fixture — both heuristics fire on the same trip set.
///   * Confidence ramp — saturates at 1.0 once the sample count
///     reaches the cap.
void main() {
  // Anchor the simulated clock so the half-split is deterministic.
  // Trips are timestamped relative to this `now` and the analyzer
  // does the windowing.
  final now = DateTime(2026, 4, 1, 12);

  group('analyzeMaintenance — empty / degenerate input', () {
    test('returns an empty list when the trip list is empty', () {
      final result = analyzeMaintenance(trips: const [], now: now);
      expect(result, isEmpty);
    });

    test('returns an empty list when fewer than minTripsTotal trips fit', () {
      // Five trips, all in-window — below the gate of 6 total.
      final trips = List<TripHistoryEntry>.generate(
        5,
        (i) => _idleTrip(
          id: 'trip-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 2)),
          idleRpm: 800.0, // identical idle medians across trips
        ),
      );

      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('returns an empty list when trips are outside the 30-day window', () {
      // 8 trips, every one of them 60+ days old.
      final trips = List<TripHistoryEntry>.generate(
        8,
        (i) => _idleTrip(
          id: 'old-$i',
          startedAt: now.subtract(Duration(days: 60 + i)),
          idleRpm: 1200.0,
        ),
      );
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test(
        'returns an empty list when no trip carries enough usable idle samples',
        () {
      // Eight trips in-window, but every sample shows the car moving
      // at highway speed — no idle samples at all.
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 8; i++) {
        final start = now.subtract(Duration(days: 28 - i * 2));
        trips.add(
          TripHistoryEntry(
            id: 'highway-$i',
            vehicleId: 'v1',
            summary: TripSummary(
              distanceKm: 50,
              maxRpm: 3000,
              highRpmSeconds: 0,
              idleSeconds: 0,
              harshBrakes: 0,
              harshAccelerations: 0,
              startedAt: start,
              endedAt: start.add(const Duration(minutes: 30)),
            ),
            samples: List<TripSample>.generate(
              30,
              (j) => TripSample(
                timestamp: start.add(Duration(seconds: j)),
                speedKmh: 110, // far above the 5 km/h idle cutoff
                rpm: 2200,
              ),
            ),
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });
  });

  group('analyzeMaintenance — idle-RPM creep heuristic', () {
    test('fires when second-half idle median is > 8 % above first-half', () {
      // 8 trips total. First half (oldest): idle ≈ 800. Second half
      // (newest): idle ≈ 900 (12.5 % above first half — clear creep).
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 800.0,
          ),
        );
      }
      for (int i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 900.0,
          ),
        );
      }

      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(1));
      final s = result.single;
      expect(s.signal, MaintenanceSignal.idleRpmCreep);
      expect(s.observedDelta, greaterThan(8.0));
      expect(s.observedDelta, lessThan(15.0));
      expect(s.sampleTripCount, 8);
      // 8 / 20 = 0.4 — well below the cap.
      expect(s.confidence, closeTo(0.4, 1e-9));
      expect(s.computedAt, now);
    });

    test('does not fire when second-half idle median is within tolerance', () {
      // First half: 800. Second half: 850 (only 6.25 % above —
      // below the 8 % trigger).
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 800.0,
          ),
        );
      }
      for (int i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 850.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('confidence saturates at 1.0 once the trip cap is reached', () {
      // 24 trips — well above the 20-trip cap. First half ≈ 800,
      // second half ≈ 900 (12.5 % creep).
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 12; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 28 - i)),
            idleRpm: 800.0,
          ),
        );
      }
      for (int i = 0; i < 12; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 14 - i)),
            idleRpm: 900.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(1));
      expect(result.single.confidence, 1.0);
    });
  });

  group('analyzeMaintenance — MAF-deviation heuristic', () {
    test('fires when second-half cruise fuel rate is > 10 % below first-half',
        () {
      // First half cruise rate 7.0 L/h, second half 6.0 L/h
      // (14.3 % drop — above the 10 % trigger).
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 4; i++) {
        trips.add(
          _cruiseTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            cruiseFuelRate: 7.0,
          ),
        );
      }
      for (int i = 0; i < 4; i++) {
        trips.add(
          _cruiseTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            cruiseFuelRate: 6.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(1));
      final s = result.single;
      expect(s.signal, MaintenanceSignal.mafDeviation);
      expect(s.observedDelta, greaterThan(10.0));
      expect(s.sampleTripCount, 8);
    });

    test('does not fire when cruise fuel rate stays within tolerance', () {
      // 8 trips, every trip cruise rate identical at 6.5.
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 8; i++) {
        trips.add(
          _cruiseTrip(
            id: 'flat-$i',
            startedAt: now.subtract(Duration(days: 28 - i * 3)),
            cruiseFuelRate: 6.5,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });
  });

  group('analyzeMaintenance — both signals at once', () {
    test('returns both signals when both heuristics fire on the same trips',
        () {
      // 8 trips, each with BOTH an idle creep signal AND a cruise
      // fuel-rate drop signal. Both heuristics should fire.
      final trips = <TripHistoryEntry>[];
      for (int i = 0; i < 4; i++) {
        trips.add(
          _combinedTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 800.0,
            cruiseFuelRate: 7.0,
          ),
        );
      }
      for (int i = 0; i < 4; i++) {
        trips.add(
          _combinedTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 900.0,
            cruiseFuelRate: 6.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(2));
      final signalSet = result.map((s) => s.signal).toSet();
      expect(signalSet, {
        MaintenanceSignal.idleRpmCreep,
        MaintenanceSignal.mafDeviation,
      });
    });
  });
}

/// Build an in-window trip whose samples carry idle ticks at
/// [idleRpm]. We give every trip eight idle ticks at speed 0 so the
/// per-trip median is unambiguously [idleRpm].
TripHistoryEntry _idleTrip({
  required String id,
  required DateTime startedAt,
  required double idleRpm,
}) {
  final samples = <TripSample>[];
  for (int j = 0; j < 8; j++) {
    samples.add(
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 0,
        rpm: idleRpm,
      ),
    );
  }
  // Add a few non-idle ticks so the analyzer doesn't trip a "no
  // distance" guard somewhere — they are filtered out by the
  // idle-only median anyway.
  for (int j = 0; j < 4; j++) {
    samples.add(
      TripSample(
        timestamp: startedAt.add(Duration(seconds: 60 + j)),
        speedKmh: 30,
        rpm: 2000,
      ),
    );
  }
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: TripSummary(
      distanceKm: 5,
      maxRpm: 2500,
      highRpmSeconds: 0,
      idleSeconds: 8,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 5)),
    ),
    samples: samples,
  );
}

/// Build an in-window trip whose samples carry cruise ticks at
/// [cruiseFuelRate]. Eight cruise ticks in the analyzer's envelope
/// (80 km/h, 2000 rpm) make the per-trip median unambiguously
/// [cruiseFuelRate].
TripHistoryEntry _cruiseTrip({
  required String id,
  required DateTime startedAt,
  required double cruiseFuelRate,
}) {
  final samples = <TripSample>[];
  for (int j = 0; j < 8; j++) {
    samples.add(
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 80,
        rpm: 2000,
        fuelRateLPerHour: cruiseFuelRate,
      ),
    );
  }
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: TripSummary(
      distanceKm: 50,
      maxRpm: 2500,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: 8.0,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 30)),
    ),
    samples: samples,
  );
}

/// Build an in-window trip whose samples carry BOTH idle ticks (at
/// [idleRpm]) AND cruise ticks (at [cruiseFuelRate]). Used to verify
/// that both heuristics can fire on the same trip set.
TripHistoryEntry _combinedTrip({
  required String id,
  required DateTime startedAt,
  required double idleRpm,
  required double cruiseFuelRate,
}) {
  final samples = <TripSample>[];
  // Idle block.
  for (int j = 0; j < 8; j++) {
    samples.add(
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 0,
        rpm: idleRpm,
      ),
    );
  }
  // Cruise block.
  for (int j = 0; j < 8; j++) {
    samples.add(
      TripSample(
        timestamp: startedAt.add(Duration(seconds: 60 + j)),
        speedKmh: 80,
        rpm: 2000,
        fuelRateLPerHour: cruiseFuelRate,
      ),
    );
  }
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: TripSummary(
      distanceKm: 50,
      maxRpm: 2500,
      highRpmSeconds: 0,
      idleSeconds: 8,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: 8.0,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 30)),
    ),
    samples: samples,
  );
}
