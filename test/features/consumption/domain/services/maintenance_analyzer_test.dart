import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/maintenance_suggestion.dart';
import 'package:tankstellen/features/consumption/domain/services/maintenance_analyzer.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic coverage for `analyzeMaintenance` (#1124, expanded under
/// #561).
///
/// `analyzeMaintenance` is a pure function: feed it a list of
/// [TripHistoryEntry] plus a `now` clock, get back a list of
/// [MaintenanceSuggestion]s. Tests are organised mirroring the
/// analyzer's three logical layers:
///
///   * **Window filtering** — null `startedAt`, before-cutoff,
///     future-stamped, below-the-gate trip counts.
///   * **idleRpmCreep heuristic** — fires on > 8 % rise, doesn't fire
///     on smaller deltas / when sample gates fail / when sample
///     filters knock out the inputs.
///   * **mafDeviation heuristic** — same shape, but on a > 10 % drop
///     in the steady-cruise (60–100 km/h, 1500–2500 RPM) fuel rate.
///
/// Plus a combined fixture that exercises both heuristics on the same
/// trip set, a confidence-saturation check, and a smoke check on the
/// public [MaintenanceAnalyzerThresholds] constants so an accidental
/// edit to a threshold breaks a test rather than slipping past CI.
void main() {
  // Anchor the simulated clock so the half-split is deterministic.
  // Trips are timestamped relative to this `now` and the analyzer
  // does the windowing.
  final now = DateTime(2026, 4, 1, 12);

  group('analyzeMaintenance — window filtering', () {
    test('returns an empty list when the trip list is empty', () {
      final result = analyzeMaintenance(trips: const [], now: now);
      expect(result, isEmpty);
    });

    test('skips trips whose summary.startedAt is null', () {
      // Eight trips, all with null startedAt — should be ignored
      // entirely, leaving zero in-window trips and an empty result.
      final trips = List<TripHistoryEntry>.generate(
        8,
        (i) => _idleTrip(
          id: 'null-$i',
          startedAt: null,
          idleRpm: 800.0,
        ),
      );
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test(
      'mixes legacy null-startedAt trips with valid trips and ignores only the former',
      () {
        // 6 valid trips (idle creep 700 → 900, would normally fire)
        // + 4 legacy null-startedAt trips that must be skipped
        // without polluting the per-trip medians.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 3; i++) {
          trips.add(
            _idleTrip(
              id: 'old-$i',
              startedAt: now.subtract(Duration(days: 25 - i)),
              idleRpm: 700.0,
            ),
          );
        }
        for (var i = 0; i < 3; i++) {
          trips.add(
            _idleTrip(
              id: 'new-$i',
              startedAt: now.subtract(Duration(days: 5 - i)),
              idleRpm: 900.0,
            ),
          );
        }
        for (var i = 0; i < 4; i++) {
          trips.add(
            _idleTrip(
              id: 'legacy-$i',
              startedAt: null,
              // If these were not skipped they'd be sorted to the
              // start of the list (null `startedAt`) and skew the
              // median — a noisy 1500 RPM here would derail the
              // signal entirely.
              idleRpm: 1500.0,
            ),
          );
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result, hasLength(1));
        expect(result.single.signal, MaintenanceSignal.idleRpmCreep);
        expect(result.single.sampleTripCount, 6);
      },
    );

    test('excludes trips before the rolling-window cutoff', () {
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

    test('excludes future-stamped trips even if otherwise valid', () {
      // 8 trips, all stamped in the future relative to `now`. An
      // honest `now` clock excludes them — clock skew or test
      // fixtures must not accidentally drive a signal.
      final trips = List<TripHistoryEntry>.generate(
        8,
        (i) => _idleTrip(
          id: 'future-$i',
          startedAt: now.add(Duration(days: 1 + i)),
          idleRpm: 900.0,
        ),
      );
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('returns an empty list when fewer than minTripsTotal trips fit', () {
      // Five trips, all in-window — below the gate of 6 total.
      final trips = List<TripHistoryEntry>.generate(
        5,
        (i) => _idleTrip(
          id: 'trip-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 2)),
          idleRpm: 800.0,
        ),
      );
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('honours a non-default windowDays parameter', () {
      // 8 trips, half older than 7 days. With windowDays = 7 only 4
      // remain — below the gate of 6, so empty.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 800.0,
          ),
        );
      }
      for (var i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 900.0,
          ),
        );
      }
      final result = analyzeMaintenance(
        trips: trips,
        now: now,
        windowDays: 7,
      );
      expect(result, isEmpty);
    });

    test('handles upstream newest-first ordering by re-sorting', () {
      // Repository hands the analyzer trips newest-first. Reverse the
      // chronologically-built list and assert the half-split still
      // finds the older trips at idle 700, newer at 900.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 3; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 700.0,
          ),
        );
      }
      for (var i = 0; i < 3; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 900.0,
          ),
        );
      }
      final reversed = trips.reversed.toList();
      final result = analyzeMaintenance(trips: reversed, now: now);
      expect(result, hasLength(1));
      expect(result.single.signal, MaintenanceSignal.idleRpmCreep);
    });
  });

  group('analyzeMaintenance — idleRpmCreep heuristic', () {
    test(
      'fires when older half median 700 vs newer half 900 (≈28.5 % rise)',
      () {
        // 6 trips. First half (oldest): idle = 700. Second half
        // (newest): idle = 900. (900 − 700) / 700 = 28.571… %.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 3; i++) {
          trips.add(
            _idleTrip(
              id: 'old-$i',
              startedAt: now.subtract(Duration(days: 25 - i)),
              idleRpm: 700.0,
            ),
          );
        }
        for (var i = 0; i < 3; i++) {
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
        expect(s.observedDelta, closeTo(28.5714, 1e-3));
        expect(s.sampleTripCount, 6);
        // 6 / 20 = 0.30 — well below the cap.
        expect(s.confidence, closeTo(0.30, 1e-9));
        expect(s.computedAt, now);
      },
    );

    test('does not fire on a 5 % rise (below the 8 % threshold)', () {
      // First half: 800. Second half: 840 (5 % above — below the
      // 8 % trigger).
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 800.0,
          ),
        );
      }
      for (var i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 840.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('does not fire at exactly the 8 % threshold (strict greater-than)', () {
      // First half 800, second half 864 = exactly 8 %. The trigger
      // is `delta > 0.08` — strict, so the 8.0 % case must NOT fire.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 800.0,
          ),
        );
      }
      for (var i = 0; i < 4; i++) {
        trips.add(
          _idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 864.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test(
      'does not fire when fewer than minTripsPerHalf trips have idle samples',
      () {
        // 8 trips in-window. Only 5 of them carry usable idle
        // samples (the rest are highway-only). After filtering,
        // perTripIdle = 5 — below minTripsTotal == 6, so no signal.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 5; i++) {
          trips.add(
            _idleTrip(
              id: 'idle-$i',
              startedAt: now.subtract(Duration(days: 25 - i * 5)),
              idleRpm: i < 2 ? 700.0 : 900.0,
            ),
          );
        }
        for (var i = 0; i < 3; i++) {
          // Highway trips contribute no idle samples — they only
          // count toward `inWindow.length` (passing the outer gate)
          // but are dropped by `_medianIdleRpm`'s sample filter.
          trips.add(_highwayTrip(
            id: 'hwy-$i',
            startedAt: now.subtract(Duration(days: 4 - i)),
          ));
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result, isEmpty);
      },
    );

    test(
      'does not fire when each trip has fewer than 4 qualifying idle samples',
      () {
        // 8 trips in-window. Each one has only 3 idle samples — below
        // `_medianIdleRpm`'s 4-sample gate. Per-trip median is null,
        // so nothing reaches perTripIdle and the signal stays silent.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 4; i++) {
          trips.add(
            _idleTrip(
              id: 'old-$i',
              startedAt: now.subtract(Duration(days: 25 - i)),
              idleRpm: 700.0,
              idleSampleCount: 3,
            ),
          );
        }
        for (var i = 0; i < 4; i++) {
          trips.add(
            _idleTrip(
              id: 'new-$i',
              startedAt: now.subtract(Duration(days: 5 - i)),
              idleRpm: 900.0,
              idleSampleCount: 3,
            ),
          );
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result, isEmpty);
      },
    );

    test(
      'does fire when each trip has exactly 4 qualifying idle samples',
      () {
        // Boundary case: 4 idle samples per trip is the minimum
        // accepted by `_medianIdleRpm`. With creep present the
        // signal must fire — guards against an off-by-one in the
        // sample-count gate.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 3; i++) {
          trips.add(
            _idleTrip(
              id: 'old-$i',
              startedAt: now.subtract(Duration(days: 25 - i)),
              idleRpm: 700.0,
              idleSampleCount: 4,
            ),
          );
        }
        for (var i = 0; i < 3; i++) {
          trips.add(
            _idleTrip(
              id: 'new-$i',
              startedAt: now.subtract(Duration(days: 5 - i)),
              idleRpm: 900.0,
              idleSampleCount: 4,
            ),
          );
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result, hasLength(1));
        expect(result.single.signal, MaintenanceSignal.idleRpmCreep);
      },
    );

    test('excludes idle samples whose speed is above the 5 km/h cutoff', () {
      // Build trips where every "candidate" idle sample has speed
      // 6 km/h — above the 5.0 cutoff. The remaining 2 idle ticks
      // per trip (speed 0) drop us under the 4-sample gate, so no
      // per-trip median, no signal.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        final start = now.subtract(Duration(days: 28 - i * 2));
        trips.add(
          TripHistoryEntry(
            id: 'creep-$i',
            vehicleId: 'v1',
            summary: TripSummary(
              distanceKm: 5,
              maxRpm: 2500,
              highRpmSeconds: 0,
              idleSeconds: 4,
              harshBrakes: 0,
              harshAccelerations: 0,
              startedAt: start,
              endedAt: start.add(const Duration(minutes: 5)),
            ),
            samples: [
              for (var j = 0; j < 2; j++)
                TripSample(
                  timestamp: start.add(Duration(seconds: j)),
                  speedKmh: 0,
                  // Idle RPM rises across trips — would trigger a
                  // signal if these samples reached the median.
                  rpm: i < 4 ? 700.0 : 900.0,
                ),
              for (var j = 0; j < 6; j++)
                TripSample(
                  // 6.0 km/h — strictly greater than 5.0, so the
                  // analyzer's `> idleSpeedKmhCutoff` filter drops
                  // these. With only 2 surviving samples per trip,
                  // `_medianIdleRpm` returns null.
                  timestamp: start.add(Duration(seconds: 10 + j)),
                  speedKmh: 6.0,
                  rpm: i < 4 ? 700.0 : 900.0,
                ),
            ],
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('includes idle samples at exactly speed 5.0 km/h (inclusive)', () {
      // The cutoff is `> 5.0`, so `speedKmh == 5.0` MUST be counted.
      // Build trips with 4 idle ticks at speed 5.0 — the signal
      // should fire because each per-trip median resolves cleanly.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 3; i++) {
        final start = now.subtract(Duration(days: 25 - i));
        trips.add(_idleTripAtSpeed(
          id: 'old-$i',
          startedAt: start,
          idleRpm: 700.0,
          speedKmh: 5.0,
        ));
      }
      for (var i = 0; i < 3; i++) {
        final start = now.subtract(Duration(days: 5 - i));
        trips.add(_idleTripAtSpeed(
          id: 'new-$i',
          startedAt: start,
          idleRpm: 900.0,
          speedKmh: 5.0,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(1));
      expect(result.single.signal, MaintenanceSignal.idleRpmCreep);
    });

    test('excludes idle samples whose RPM is below the 200 floor', () {
      // 8 trips. Each has 8 "idle-looking" samples — speed 0, but
      // rpm 150 (below the 200 floor → adapter glitch territory).
      // None of those samples count, so no per-trip median, empty
      // result.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        trips.add(
          _idleTrip(
            id: 'glitch-$i',
            startedAt: now.subtract(Duration(days: 28 - i * 2)),
            idleRpm: 150.0,
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test(
      'reports observedDelta as a percent (28.5, not 0.285)',
      () {
        // Confirms the analyzer pre-multiplies its delta by 100 so
        // the UI can render `{percent}%` directly. 700 → 900 = 28.57 %.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 3; i++) {
          trips.add(_idleTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            idleRpm: 700.0,
          ));
        }
        for (var i = 0; i < 3; i++) {
          trips.add(_idleTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            idleRpm: 900.0,
          ));
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result.single.observedDelta, greaterThan(20.0));
        expect(result.single.observedDelta, lessThan(30.0));
      },
    );
  });

  group('analyzeMaintenance — mafDeviation heuristic', () {
    test(
      'fires when second-half cruise fuel rate drops > 10 % below first-half',
      () {
        // First half cruise rate 7.0 L/h, second half 6.0 L/h —
        // (7 − 6) / 7 = 14.28 %, above the 10 % trigger.
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 4; i++) {
          trips.add(_cruiseTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            cruiseFuelRate: 7.0,
          ));
        }
        for (var i = 0; i < 4; i++) {
          trips.add(_cruiseTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            cruiseFuelRate: 6.0,
          ));
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result, hasLength(1));
        final s = result.single;
        expect(s.signal, MaintenanceSignal.mafDeviation);
        expect(s.observedDelta, closeTo(14.2857, 1e-3));
        expect(s.sampleTripCount, 8);
        expect(s.confidence, closeTo(0.4, 1e-9));
        expect(s.computedAt, now);
      },
    );

    test('does not fire on a 5 % drop in cruise fuel rate', () {
      // First half 7.0, second half 6.65 (5 % drop) — below the
      // 10 % trigger.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 4; i++) {
        trips.add(_cruiseTrip(
          id: 'old-$i',
          startedAt: now.subtract(Duration(days: 25 - i)),
          cruiseFuelRate: 7.0,
        ));
      }
      for (var i = 0; i < 4; i++) {
        trips.add(_cruiseTrip(
          id: 'new-$i',
          startedAt: now.subtract(Duration(days: 5 - i)),
          cruiseFuelRate: 6.65,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('does not fire when cruise fuel rate stays flat across trips', () {
      // 8 trips, every trip cruise rate identical at 6.5.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        trips.add(_cruiseTrip(
          id: 'flat-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 3)),
          cruiseFuelRate: 6.5,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('does not fire on a fuel-rate RISE (one-sided drop heuristic)', () {
      // The MAF heuristic is one-sided: it fires only on a drop. A
      // 14 % rise (older 6.0, newer 7.0) must NOT fire.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 4; i++) {
        trips.add(_cruiseTrip(
          id: 'old-$i',
          startedAt: now.subtract(Duration(days: 25 - i)),
          cruiseFuelRate: 6.0,
        ));
      }
      for (var i = 0; i < 4; i++) {
        trips.add(_cruiseTrip(
          id: 'new-$i',
          startedAt: now.subtract(Duration(days: 5 - i)),
          cruiseFuelRate: 7.0,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('skips samples without a fuelRateLPerHour reading', () {
      // 8 trips in-window with cruise speed/RPM but every fuel-rate
      // is null (legacy car without PID 5E). Per-trip median is
      // null → empty result.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        final start = now.subtract(Duration(days: 28 - i * 2));
        trips.add(
          TripHistoryEntry(
            id: 'no-fuel-$i',
            vehicleId: 'v1',
            summary: TripSummary(
              distanceKm: 50,
              maxRpm: 2500,
              highRpmSeconds: 0,
              idleSeconds: 0,
              harshBrakes: 0,
              harshAccelerations: 0,
              startedAt: start,
              endedAt: start.add(const Duration(minutes: 30)),
            ),
            samples: List<TripSample>.generate(
              8,
              (j) => TripSample(
                timestamp: start.add(Duration(seconds: j)),
                speedKmh: 80,
                rpm: 2000,
                // No fuelRateLPerHour — older car without PID 5E.
              ),
            ),
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('excludes samples below the 60 km/h cruise floor', () {
      // Cruise envelope is `[60, 100]`. Samples at 59 km/h are
      // excluded — without enough cruise samples, no per-trip
      // median, no signal.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        trips.add(_cruiseTripAtEnvelope(
          id: 'slow-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 2)),
          cruiseFuelRate: 6.0,
          speedKmh: 59,
          rpm: 2000,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('excludes samples above the 100 km/h cruise ceiling', () {
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        trips.add(_cruiseTripAtEnvelope(
          id: 'fast-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 2)),
          cruiseFuelRate: 6.0,
          speedKmh: 101,
          rpm: 2000,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('excludes samples below the 1500 RPM cruise floor', () {
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        trips.add(_cruiseTripAtEnvelope(
          id: 'low-rpm-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 2)),
          cruiseFuelRate: 6.0,
          speedKmh: 80,
          rpm: 1499,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('excludes samples above the 2500 RPM cruise ceiling', () {
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 8; i++) {
        trips.add(_cruiseTripAtEnvelope(
          id: 'high-rpm-$i',
          startedAt: now.subtract(Duration(days: 28 - i * 2)),
          cruiseFuelRate: 6.0,
          speedKmh: 80,
          rpm: 2501,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, isEmpty);
    });

    test('includes samples at the cruise envelope boundaries (inclusive)', () {
      // Cruise envelope is `[60, 100]` × `[1500, 2500]`. Samples at
      // exactly 60 km/h / 100 km/h / 1500 RPM / 2500 RPM must count.
      // Build trips with 4 cruise samples at the corners and verify
      // the signal fires when the rate drop crosses 10 %.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 3; i++) {
        final start = now.subtract(Duration(days: 25 - i));
        trips.add(
          TripHistoryEntry(
            id: 'corner-old-$i',
            vehicleId: 'v1',
            summary: _summary(start: start),
            samples: [
              TripSample(
                timestamp: start,
                speedKmh: 60,
                rpm: 1500,
                fuelRateLPerHour: 7.0,
              ),
              TripSample(
                timestamp: start.add(const Duration(seconds: 1)),
                speedKmh: 100,
                rpm: 1500,
                fuelRateLPerHour: 7.0,
              ),
              TripSample(
                timestamp: start.add(const Duration(seconds: 2)),
                speedKmh: 60,
                rpm: 2500,
                fuelRateLPerHour: 7.0,
              ),
              TripSample(
                timestamp: start.add(const Duration(seconds: 3)),
                speedKmh: 100,
                rpm: 2500,
                fuelRateLPerHour: 7.0,
              ),
            ],
          ),
        );
      }
      for (var i = 0; i < 3; i++) {
        final start = now.subtract(Duration(days: 5 - i));
        trips.add(
          TripHistoryEntry(
            id: 'corner-new-$i',
            vehicleId: 'v1',
            summary: _summary(start: start),
            samples: [
              TripSample(
                timestamp: start,
                speedKmh: 60,
                rpm: 1500,
                fuelRateLPerHour: 6.0,
              ),
              TripSample(
                timestamp: start.add(const Duration(seconds: 1)),
                speedKmh: 100,
                rpm: 1500,
                fuelRateLPerHour: 6.0,
              ),
              TripSample(
                timestamp: start.add(const Duration(seconds: 2)),
                speedKmh: 60,
                rpm: 2500,
                fuelRateLPerHour: 6.0,
              ),
              TripSample(
                timestamp: start.add(const Duration(seconds: 3)),
                speedKmh: 100,
                rpm: 2500,
                fuelRateLPerHour: 6.0,
              ),
            ],
          ),
        );
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(1));
      expect(result.single.signal, MaintenanceSignal.mafDeviation);
    });

    test(
      'does not fire when each trip has fewer than 4 qualifying cruise samples',
      () {
        // 8 trips, each with only 3 cruise samples. Per-trip median
        // returns null (the `< 4` gate in `_medianCruiseFuelRate`).
        final trips = <TripHistoryEntry>[];
        for (var i = 0; i < 4; i++) {
          trips.add(_cruiseTrip(
            id: 'old-$i',
            startedAt: now.subtract(Duration(days: 25 - i)),
            cruiseFuelRate: 7.0,
            cruiseSampleCount: 3,
          ));
        }
        for (var i = 0; i < 4; i++) {
          trips.add(_cruiseTrip(
            id: 'new-$i',
            startedAt: now.subtract(Duration(days: 5 - i)),
            cruiseFuelRate: 6.0,
            cruiseSampleCount: 3,
          ));
        }
        final result = analyzeMaintenance(trips: trips, now: now);
        expect(result, isEmpty);
      },
    );
  });

  group('analyzeMaintenance — combined behaviour', () {
    test('returns both signals when both heuristics fire on the same trips',
        () {
      // 8 trips, each with BOTH an idle creep signal AND a cruise
      // fuel-rate drop signal. Both heuristics fire — order is
      // implementation-defined, so assert by set membership.
      final trips = <TripHistoryEntry>[];
      for (var i = 0; i < 4; i++) {
        trips.add(_combinedTrip(
          id: 'old-$i',
          startedAt: now.subtract(Duration(days: 25 - i)),
          idleRpm: 800.0,
          cruiseFuelRate: 7.0,
        ));
      }
      for (var i = 0; i < 4; i++) {
        trips.add(_combinedTrip(
          id: 'new-$i',
          startedAt: now.subtract(Duration(days: 5 - i)),
          idleRpm: 900.0,
          cruiseFuelRate: 6.0,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(2));
      final signalSet = result.map((s) => s.signal).toSet();
      expect(signalSet, {
        MaintenanceSignal.idleRpmCreep,
        MaintenanceSignal.mafDeviation,
      });
    });

    test('confidence saturates at 1.0 once 25 trips are in the window', () {
      // 25 trips — above the 20-trip cap. Confidence must clamp to
      // 1.0 and the trip count must round-trip exactly.
      final trips = <TripHistoryEntry>[];
      // 12 older trips at idle 700.
      for (var i = 0; i < 12; i++) {
        trips.add(_idleTrip(
          id: 'old-$i',
          // Spread over 14 days so they all fit comfortably within
          // the 30-day window's first half.
          startedAt: now.subtract(Duration(days: 28 - i)),
          idleRpm: 700.0,
        ));
      }
      // 13 newer trips at idle 900.
      for (var i = 0; i < 13; i++) {
        trips.add(_idleTrip(
          id: 'new-$i',
          startedAt: now.subtract(Duration(days: 13 - i)),
          idleRpm: 900.0,
        ));
      }
      final result = analyzeMaintenance(trips: trips, now: now);
      expect(result, hasLength(1));
      expect(result.single.sampleTripCount, 25);
      expect(result.single.confidence, 1.0);
    });
  });

  group('MaintenanceAnalyzerThresholds', () {
    test('idleSpeedKmhCutoff is 5.0', () {
      expect(MaintenanceAnalyzerThresholds.idleSpeedKmhCutoff, 5.0);
    });

    test('minIdleRpm is 200.0', () {
      expect(MaintenanceAnalyzerThresholds.minIdleRpm, 200.0);
    });

    test('cruiseSpeedMinKmh is 60.0', () {
      expect(MaintenanceAnalyzerThresholds.cruiseSpeedMinKmh, 60.0);
    });

    test('cruiseSpeedMaxKmh is 100.0', () {
      expect(MaintenanceAnalyzerThresholds.cruiseSpeedMaxKmh, 100.0);
    });

    test('cruiseRpmMin is 1500.0', () {
      expect(MaintenanceAnalyzerThresholds.cruiseRpmMin, 1500.0);
    });

    test('cruiseRpmMax is 2500.0', () {
      expect(MaintenanceAnalyzerThresholds.cruiseRpmMax, 2500.0);
    });

    test('idleRpmCreepFraction is 0.08', () {
      expect(MaintenanceAnalyzerThresholds.idleRpmCreepFraction, 0.08);
    });

    test('mafDeviationDropFraction is 0.10', () {
      expect(MaintenanceAnalyzerThresholds.mafDeviationDropFraction, 0.10);
    });

    test('minTripsPerHalf is 3', () {
      expect(MaintenanceAnalyzerThresholds.minTripsPerHalf, 3);
    });

    test('minTripsTotal is 6', () {
      expect(MaintenanceAnalyzerThresholds.minTripsTotal, 6);
    });

    test('confidenceCap is 20', () {
      expect(MaintenanceAnalyzerThresholds.confidenceCap, 20);
    });

    test('windowDays is 30', () {
      expect(MaintenanceAnalyzerThresholds.windowDays, 30);
    });
  });
}

// =============================================================================
// Test fixture builders.
// =============================================================================

/// Build a trip whose samples carry [idleSampleCount] idle ticks at
/// [idleRpm] (speed 0). A handful of non-idle ticks are appended so
/// total sample count stays representative — they are filtered out by
/// the idle-only median.
TripHistoryEntry _idleTrip({
  required String id,
  required DateTime? startedAt,
  required double idleRpm,
  int idleSampleCount = 8,
}) {
  // Use a fixed reference timestamp when startedAt is null so the
  // sample timestamps round-trip cleanly. Legacy entries with null
  // startedAt are still expected to carry timestamped samples on
  // disk — the analyzer skips them at the trip level, never reaches
  // the samples.
  final base = startedAt ?? DateTime(2024, 1, 1);
  final samples = <TripSample>[
    for (var j = 0; j < idleSampleCount; j++)
      TripSample(
        timestamp: base.add(Duration(seconds: j)),
        speedKmh: 0,
        rpm: idleRpm,
      ),
    // A few non-idle ticks so the analyzer doesn't trip a
    // hypothetical "no distance" guard somewhere — they are
    // filtered out by the idle-only median anyway.
    for (var j = 0; j < 4; j++)
      TripSample(
        timestamp: base.add(Duration(seconds: 60 + j)),
        speedKmh: 30,
        rpm: 2000,
      ),
  ];
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: _summary(start: startedAt),
    samples: samples,
  );
}

/// Build a trip with 4 idle ticks at a custom [speedKmh]. Used to
/// pin behaviour at the speed-cutoff boundary.
TripHistoryEntry _idleTripAtSpeed({
  required String id,
  required DateTime startedAt,
  required double idleRpm,
  required double speedKmh,
}) {
  final samples = <TripSample>[
    for (var j = 0; j < 4; j++)
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: speedKmh,
        rpm: idleRpm,
      ),
  ];
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: _summary(start: startedAt),
    samples: samples,
  );
}

/// Build a trip with [cruiseSampleCount] cruise ticks at the canonical
/// envelope (80 km/h, 2000 RPM) and the supplied fuel rate.
TripHistoryEntry _cruiseTrip({
  required String id,
  required DateTime startedAt,
  required double cruiseFuelRate,
  int cruiseSampleCount = 8,
}) {
  final samples = <TripSample>[
    for (var j = 0; j < cruiseSampleCount; j++)
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 80,
        rpm: 2000,
        fuelRateLPerHour: cruiseFuelRate,
      ),
  ];
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: _summary(start: startedAt, withFuel: true),
    samples: samples,
  );
}

/// Build a trip with 8 cruise ticks at custom [speedKmh] / [rpm] —
/// pins the cruise-envelope filter at boundary values.
TripHistoryEntry _cruiseTripAtEnvelope({
  required String id,
  required DateTime startedAt,
  required double cruiseFuelRate,
  required double speedKmh,
  required double rpm,
}) {
  final samples = <TripSample>[
    for (var j = 0; j < 8; j++)
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: speedKmh,
        rpm: rpm,
        fuelRateLPerHour: cruiseFuelRate,
      ),
  ];
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: _summary(start: startedAt, withFuel: true),
    samples: samples,
  );
}

/// Build a trip whose samples carry BOTH idle ticks (at [idleRpm]) AND
/// cruise ticks (at [cruiseFuelRate]) so a single trip set can drive
/// both heuristics simultaneously.
TripHistoryEntry _combinedTrip({
  required String id,
  required DateTime startedAt,
  required double idleRpm,
  required double cruiseFuelRate,
}) {
  final samples = <TripSample>[
    // Idle block.
    for (var j = 0; j < 8; j++)
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 0,
        rpm: idleRpm,
      ),
    // Cruise block.
    for (var j = 0; j < 8; j++)
      TripSample(
        timestamp: startedAt.add(Duration(seconds: 60 + j)),
        speedKmh: 80,
        rpm: 2000,
        fuelRateLPerHour: cruiseFuelRate,
      ),
  ];
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: _summary(start: startedAt, withFuel: true),
    samples: samples,
  );
}

/// Build a trip with samples that contain no idle and no cruise data —
/// just steady highway driving above the cruise envelope. Used to pad
/// the in-window trip count without contributing per-trip medians.
TripHistoryEntry _highwayTrip({
  required String id,
  required DateTime startedAt,
}) {
  final samples = <TripSample>[
    for (var j = 0; j < 30; j++)
      TripSample(
        timestamp: startedAt.add(Duration(seconds: j)),
        speedKmh: 110,
        rpm: 2700,
      ),
  ];
  return TripHistoryEntry(
    id: id,
    vehicleId: 'v1',
    summary: _summary(start: startedAt),
    samples: samples,
  );
}

/// Compact [TripSummary] builder. The analyzer only reads
/// `summary.startedAt`, so every other field defaults to a
/// representative value.
TripSummary _summary({required DateTime? start, bool withFuel = false}) {
  return TripSummary(
    distanceKm: withFuel ? 50 : 5,
    maxRpm: 2500,
    highRpmSeconds: 0,
    idleSeconds: withFuel ? 0 : 8,
    harshBrakes: 0,
    harshAccelerations: 0,
    avgLPer100Km: withFuel ? 8.0 : null,
    startedAt: start,
    endedAt: start?.add(const Duration(minutes: 30)),
  );
}
