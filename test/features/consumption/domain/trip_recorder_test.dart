import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_distance_source.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic tests for the trip recorder (#718).
///
/// The recorder accepts OBD2 samples (speed, rpm, fuelRate) at a
/// poller-controlled cadence and produces a [TripSummary] on demand
/// (e.g. when the Bluetooth adapter disconnects).
///
/// Thresholds default to commonly-used telematics cutoffs:
/// - High RPM:     > 3 500 rpm
/// - Harsh brake: dv/dt < -3.5 m/s²   (~ -12.6 km/h per second)
/// - Harsh accel: dv/dt >  3.0 m/s²   (~ +10.8 km/h per second)
/// - Idle:         speed = 0 km/h and rpm > 0
void main() {
  group('TripRecorder (#718)', () {
    late TripRecorder recorder;

    setUp(() {
      recorder = TripRecorder();
    });

    test('empty recorder yields zero distance + zero metrics', () {
      final summary = recorder.buildSummary();
      expect(summary.distanceKm, 0);
      expect(summary.maxRpm, 0);
      expect(summary.highRpmSeconds, 0);
      expect(summary.idleSeconds, 0);
      expect(summary.harshBrakes, 0);
      expect(summary.harshAccelerations, 0);
    });

    test('integrates distance from speed × Δt samples', () {
      // Drive 60 km/h for 60 s → 1 km.
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 60, rpm: 2000));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 60)),
        speedKmh: 60,
        rpm: 2000,
      ));
      expect(recorder.buildSummary().distanceKm, closeTo(1.0, 0.01));
    });

    test('counts a harsh brake when Δv/Δt < -3.5 m/s²', () {
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 80, rpm: 3000));
      // 80 → 30 km/h in 2 s = -50 km/h / 2 s = -6.94 m/s² → harsh.
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 2)),
        speedKmh: 30,
        rpm: 1500,
      ));
      expect(recorder.buildSummary().harshBrakes, 1);
      expect(recorder.buildSummary().harshAccelerations, 0);
    });

    test('counts a harsh accel when Δv/Δt > 3.0 m/s²', () {
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 0, rpm: 1000));
      // 0 → 50 km/h in 3 s → +4.63 m/s² → harsh.
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 3)),
        speedKmh: 50,
        rpm: 4000,
      ));
      expect(recorder.buildSummary().harshAccelerations, 1);
    });

    test('gentle brake / accel does NOT tick the harsh counters', () {
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 50, rpm: 2000));
      // 50 → 45 km/h in 3 s → -0.46 m/s² → not harsh.
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 3)),
        speedKmh: 45,
        rpm: 1800,
      ));
      final summary = recorder.buildSummary();
      expect(summary.harshBrakes, 0);
      expect(summary.harshAccelerations, 0);
    });

    test(
        'accumulates idle seconds when speed = 0 and rpm > 0 '
        '(engine running, stationary)', () {
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 0, rpm: 800));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 30)),
        speedKmh: 0,
        rpm: 800,
      ));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 60)),
        speedKmh: 0,
        rpm: 800,
      ));
      expect(recorder.buildSummary().idleSeconds, closeTo(60, 0.5));
    });

    test('tracks max RPM across the trip', () {
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 30, rpm: 1500));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 10)),
        speedKmh: 80,
        rpm: 4200,
      ));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 20)),
        speedKmh: 100,
        rpm: 3800,
      ));
      expect(recorder.buildSummary().maxRpm, 4200);
    });

    test('accumulates high-RPM seconds above the threshold (default 3 500)',
        () {
      final start = DateTime.utc(2026);
      recorder.onSample(TripSample(timestamp: start, speedKmh: 50, rpm: 4000));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 20)),
        speedKmh: 80,
        rpm: 4000,
      ));
      recorder.onSample(TripSample(
        timestamp: start.add(const Duration(seconds: 40)),
        speedKmh: 80,
        rpm: 2500,
      ));
      // From 0→20s RPM was ≥ 3500. From 20→40s still ≥ 3500 (start of
      // sample). After 40s rpm dropped — high-RPM interval = 40 s.
      expect(recorder.buildSummary().highRpmSeconds, closeTo(40, 0.5));
    });

    test('average L/100 km uses fuel rate × time ÷ distance', () {
      // 60 km/h for 1 h = 60 km, fuel rate 6 L/h → 6 L over the hour
      // → 6 L / 60 km × 100 = 10 L/100 km.
      //
      // #2835 — fed at a realistic 10 s cadence (361 samples) rather than
      // one synthetic 1-hour interval: the recorder now rejects fuel
      // integrated across a mean interval wider than the gap the live
      // integrators bridge, so a lone 3600 s step is (correctly) treated
      // as too sparse to trust. The integral is identical at any cadence.
      final start = DateTime.utc(2026);
      for (var t = 0; t <= 3600; t += 10) {
        recorder.onSample(TripSample(
          timestamp: start.add(Duration(seconds: t)),
          speedKmh: 60,
          rpm: 2000,
          fuelRateLPerHour: 6,
        ));
      }
      final summary = recorder.buildSummary();
      expect(summary.distanceKm, closeTo(60, 0.1));
      expect(summary.avgLPer100Km, closeTo(10.0, 0.1));
    });

    test(
        '#2692 C4-E — a single transient null fuelRate is carried forward, '
        'integrating BOTH intervals (not zero them)', () {
      // rate=5 throughout, with the sample at the 1-hour mark carrying a
      // transient null PID. Pre-fix the both-endpoints-non-null gate
      // skipped the two intervals touching the null → under-count. With
      // carry-forward the null resolves the last-known 5 L/h, so the full
      // 2 h integrates at 5 L/h → 10 L total.
      //
      // #2835 — fed at a 10 s cadence (so the cadence reliability gate
      // passes); the carry-forward still spans the single null sample.
      final start = DateTime.utc(2026);
      const nullAt = 3600; // the transient-dropout sample, mid-trip.
      for (var t = 0; t <= 7200; t += 10) {
        recorder.onSample(TripSample(
          timestamp: start.add(Duration(seconds: t)),
          speedKmh: 60,
          rpm: 2000,
          // omit the rate on exactly one mid-trip sample → null dropout.
          fuelRateLPerHour: t == nullAt ? null : 5,
        ));
      }
      // 5 L/h × 2 h = 10 L; pre-fix the intervals touching the null read
      // would have been skipped, under-counting the litres.
      expect(recorder.buildSummary().fuelLitersConsumed, closeTo(10.0, 0.01));
    });

    group('consumption reliability gates (#2835)', () {
      test(
          'tiny-distance trip suppresses avgLPer100Km (no blow-up) but keeps '
          'the real measured litres', () {
        // The field backup: a 0.4 km trip integrated to 306 L/100 km.
        // Reproduce a sub-1 km trip with a dense cadence: 30 km/h for
        // 48 s ≈ 0.4 km, burning fuel at 6 L/h. Pre-fix avgLPer100Km
        // would be (6 × 48/3600) / 0.4 × 100 ≈ 20 L/100 km here, and a
        // tighter denominator drives it arbitrarily high. The litres
        // themselves (~0.08 L) are real and must survive.
        final start = DateTime.utc(2026);
        for (var t = 0; t <= 48; t += 2) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(seconds: t)),
            speedKmh: 30,
            rpm: 1500,
            fuelRateLPerHour: 6,
          ));
        }
        final s = recorder.buildSummary();
        expect(s.distanceKm, lessThan(1.0),
            reason: 'sanity: this is a sub-km trip');
        expect(s.avgLPer100Km, isNull,
            reason: 'tiny-distance L/100 km is suppressed (the blow-up '
                'fix) so it cannot pollute the rolling average');
        expect(s.fuelLitersConsumed, isNotNull,
            reason: 'the measured litres are a real quantity — only the '
                'ratio is suppressed, not the burn');
        expect(s.fuelLitersConsumed!, greaterThan(0));
      });

      test(
          'sparse-cadence trip marks BOTH litres and avgLPer100Km '
          'unavailable (no fabricated ~0)', () {
        // The field backup: a 58.8 km trip with only 126 samples
        // (~1/min) reported ~0 L/100 km because a 60 s interval assumes
        // a constant fuel rate for a whole minute. Reproduce a long trip
        // sampled once a minute: 60 km/h, fuel 6 L/h, for ~70 min ⇒ 70 km
        // (well past the distance floor), but the mean interval is 60 s,
        // beyond the 30 s cadence gate.
        final start = DateTime.utc(2026);
        for (var minute = 0; minute <= 70; minute++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: minute)),
            speedKmh: 60,
            rpm: 2000,
            fuelRateLPerHour: 6,
          ));
        }
        final s = recorder.buildSummary();
        expect(s.distanceKm, greaterThan(50.0),
            reason: 'sanity: the distance denominator is fine — only the '
                'fuel cadence is too sparse');
        expect(s.fuelLitersConsumed, isNull,
            reason: 'a ~1/min cadence cannot integrate fuel honestly, so '
                'litres are unavailable rather than a near-zero artefact');
        expect(s.avgLPer100Km, isNull,
            reason: 'and the derived L/100 km is unavailable too');
      });

      test(
          'a normal dense-cadence trip over the distance floor reports a '
          'reliable figure (gates do not over-reach)', () {
        // 60 km/h, 6 L/h, sampled every 5 s for 5 min ⇒ 5 km, mean
        // interval 5 s. Both gates pass. 6 L/h × (300/3600) h = 0.5 L
        // over 5 km ⇒ 10 L/100 km.
        final start = DateTime.utc(2026);
        for (var t = 0; t <= 300; t += 5) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(seconds: t)),
            speedKmh: 60,
            rpm: 2000,
            fuelRateLPerHour: 6,
          ));
        }
        final s = recorder.buildSummary();
        expect(s.distanceKm, closeTo(5.0, 0.05));
        expect(s.fuelLitersConsumed, closeTo(0.5, 0.01));
        expect(s.avgLPer100Km, closeTo(10.0, 0.2));
      });
    });

    test('throttlePercent on TripSample is preserved (#1261)', () {
      // The recorder doesn't aggregate throttle today — but the field
      // must round-trip through TripSample so the persisted samples
      // can drive the trip-detail throttle / RPM histogram.
      final ts = DateTime.utc(2026);
      final sample = TripSample(
        timestamp: ts,
        speedKmh: 60,
        rpm: 2000,
        throttlePercent: 42.0,
      );
      expect(sample.throttlePercent, 42.0);
      // And the existing fields still pass through unchanged.
      expect(sample.speedKmh, 60);
      expect(sample.rpm, 2000);
      expect(sample.fuelRateLPerHour, isNull);
    });

    test('throttlePercent defaults to null when omitted (#1261)', () {
      final ts = DateTime.utc(2026);
      final sample = TripSample(timestamp: ts, speedKmh: 50, rpm: 1500);
      expect(sample.throttlePercent, isNull);
    });

    group('cold-start surcharge heuristic (#1262 phase 2)', () {
      test(
          'short cold trip — 5 min @ 25 °C coolant flips coldStartSurcharge '
          'true (rule A: < 10 min AND coolant min < 70 °C)', () {
        final start = DateTime.utc(2026);
        // Five samples across 5 minutes, coolant pegged at 25 °C —
        // a typical winter short hop where the engine never warms up.
        for (var i = 0; i <= 5; i++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 30,
            rpm: 1500,
            coolantTempC: 25,
          ));
        }
        expect(recorder.buildSummary().coldStartSurcharge, isTrue);
      });

      test(
          'warm trip — climbs to 90 °C in first 2 min of a 30-min trip '
          'stays false (engine reached operating temp early)', () {
        final start = DateTime.utc(2026);
        // Minute 0: cold. Minute 2: warm. Stays warm for the rest.
        recorder.onSample(TripSample(
          timestamp: start,
          speedKmh: 50,
          rpm: 2000,
          coolantTempC: 25,
        ));
        recorder.onSample(TripSample(
          timestamp: start.add(const Duration(minutes: 2)),
          speedKmh: 70,
          rpm: 2200,
          coolantTempC: 90,
        ));
        recorder.onSample(TripSample(
          timestamp: start.add(const Duration(minutes: 30)),
          speedKmh: 70,
          rpm: 2200,
          coolantTempC: 92,
        ));
        expect(recorder.buildSummary().coldStartSurcharge, isFalse);
      });

      test(
          'never-warmed long trip — 20 min stuck at 60 °C flips true '
          '(rule B: max coolant < 70 °C across the whole trip)', () {
        final start = DateTime.utc(2026);
        // 20-minute trip, coolant never crosses the 70 °C line — the
        // engine ran rich the whole time. Rule A doesn't fire (the
        // trip is > 10 min) but rule B catches this case.
        for (var i = 0; i <= 20; i++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 25,
            rpm: 1400,
            coolantTempC: 60,
          ));
        }
        expect(recorder.buildSummary().coldStartSurcharge, isTrue);
      });

      test(
          'late-warm trip — coolant only crosses 70 °C at minute 15 of a '
          '20-min trip flips true (rule C: warmed in second half)', () {
        final start = DateTime.utc(2026);
        // 0..14: cold. 15..20: warm. Crossover at minute 15 (75 % of
        // the trip elapsed) → second half → rule C fires.
        for (var i = 0; i < 15; i++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 40,
            rpm: 1700,
            coolantTempC: 50,
          ));
        }
        for (var i = 15; i <= 20; i++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 40,
            rpm: 1700,
            coolantTempC: 80,
          ));
        }
        expect(recorder.buildSummary().coldStartSurcharge, isTrue);
      });

      test(
          'no coolant data — every sample carries coolantTempC: null '
          'leaves coldStartSurcharge false (no false positives on cars '
          'without PID 0x05)', () {
        final start = DateTime.utc(2026);
        // Short trip — would hit rule A if we had any coolant sample.
        for (var i = 0; i <= 5; i++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 30,
            rpm: 1500,
            // coolantTempC omitted → null
          ));
        }
        expect(recorder.buildSummary().coldStartSurcharge, isFalse);
      });

      test(
          'reset clears cold-start state — a warm trip after a cold trip '
          'must NOT inherit the cold flag', () {
        final start = DateTime.utc(2026);
        // First trip: short and cold → would flip true.
        for (var i = 0; i <= 5; i++) {
          recorder.onSample(TripSample(
            timestamp: start.add(Duration(minutes: i)),
            speedKmh: 30,
            rpm: 1500,
            coolantTempC: 25,
          ));
        }
        expect(recorder.buildSummary().coldStartSurcharge, isTrue);

        recorder.reset();

        // Second trip: warm from the start, long enough to not be a
        // short cold trip. Min coolant ≥ 70 means rule A (which keys
        // off min, not start) won't fire either.
        final t2 = DateTime.utc(2026, 1, 2);
        recorder.onSample(TripSample(
          timestamp: t2,
          speedKmh: 70,
          rpm: 2200,
          coolantTempC: 85,
        ));
        recorder.onSample(TripSample(
          timestamp: t2.add(const Duration(minutes: 30)),
          speedKmh: 70,
          rpm: 2200,
          coolantTempC: 90,
        ));
        expect(recorder.buildSummary().coldStartSurcharge, isFalse);
      });
    });

    group('GPS fix on TripSample (#1374 phase 1)', () {
      test('latitude / longitude default to null when omitted', () {
        // Mirrors the throttle / engineLoad / coolant defaults — a
        // pre-#1374 build never wrote these fields, so the constructor
        // MUST accept the legacy two-arg shape (or the four-arg shape
        // that includes the existing optionals) and surface null.
        final ts = DateTime.utc(2026);
        final sample = TripSample(timestamp: ts, speedKmh: 50, rpm: 1500);
        expect(sample.latitude, isNull);
        expect(sample.longitude, isNull);
      });

      test('explicit lat/lng round-trip onto the sample', () {
        // A flag-on tick: the provider pushed a Position into the
        // controller, which stamped both coords onto the sample. The
        // round-trip is trivial (the field is just a final double),
        // but locking the assertion here flags any future refactor
        // that accidentally drops one of the two fields.
        final ts = DateTime.utc(2026);
        final sample = TripSample(
          timestamp: ts,
          speedKmh: 60,
          rpm: 2000,
          latitude: 43.4567,
          longitude: 3.5821,
        );
        expect(sample.latitude, closeTo(43.4567, 1e-9));
        expect(sample.longitude, closeTo(3.5821, 1e-9));
        // Existing optional fields stay null when not supplied — the
        // GPS additions must not hijack the slot for any other PID.
        expect(sample.fuelRateLPerHour, isNull);
        expect(sample.throttlePercent, isNull);
        expect(sample.engineLoadPercent, isNull);
        expect(sample.coolantTempC, isNull);
      });

      test(
          'half-set fix is allowed by the type system but discouraged — '
          'phase 1 records both or neither at the integration site',
          () {
        // The phase-1 integration site (provider) only ever calls
        // `controller.updateGpsFix(latitude: pos.latitude,
        // longitude: pos.longitude)`, so a half-set TripSample never
        // appears in production. We still allow the constructor to
        // build one because keeping the fields independent (rather
        // than adding a `LatLng?` wrapper) keeps the JSON encoding
        // symmetric with the existing per-field compact keys.
        final ts = DateTime.utc(2026);
        final sample =
            TripSample(timestamp: ts, speedKmh: 0, rpm: 0, latitude: 50.0);
        expect(sample.latitude, 50.0);
        expect(sample.longitude, isNull);
      });

      test(
          'recorder.onSample accepts samples with GPS coords without '
          'changing aggregate metrics — coords are persisted, not '
          'integrated into distance / RPM / fuel maths', () {
        // Distance still comes from speed × Δt; the GPS coords are
        // sample-level metadata for the future heatmap (Phase 2/3),
        // not an input to the existing virtual-odometer math.
        // Without this guard, a future change that wires GPS into
        // distance would silently break every legacy trip's distance
        // value (their coords are null → division by zero / NaN).
        final start = DateTime.utc(2026);
        recorder.onSample(TripSample(
          timestamp: start,
          speedKmh: 60,
          rpm: 2000,
          latitude: 43.45,
          longitude: 3.58,
        ));
        recorder.onSample(TripSample(
          timestamp: start.add(const Duration(seconds: 60)),
          speedKmh: 60,
          rpm: 2000,
          latitude: 43.46,
          longitude: 3.59,
        ));
        // Same expected distance as the legacy "60 km/h for 60 s"
        // case earlier in this file — proves the coord plumbing
        // doesn't perturb the integration.
        expect(recorder.buildSummary().distanceKm, closeTo(1.0, 0.01));
      });
    });

    test('configurable thresholds override the defaults', () {
      final strict = TripRecorder(
        highRpmThreshold: 2500,
        harshBrakeThresholdMps2: 2.0,
        harshAccelThresholdMps2: 1.5,
      );
      final start = DateTime.utc(2026);
      strict.onSample(TripSample(timestamp: start, speedKmh: 50, rpm: 2800));
      // Δv = -20 km/h over 2.5 s → -2.22 m/s² — harsh under the
      // tighter threshold (2.0), not harsh under the default (3.5).
      strict.onSample(TripSample(
        timestamp: start.add(const Duration(milliseconds: 2500)),
        speedKmh: 30,
        rpm: 2000,
      ));
      expect(strict.buildSummary().harshBrakes, 1);
    });

    group('maxIntegrationGapSeconds dropout cap (#1927)', () {
      test('distance and fuel are not integrated across an abnormal gap',
          () {
        final r = TripRecorder(maxIntegrationGapSeconds: 15);
        final start = DateTime.utc(2026);
        r.onSample(TripSample(
            timestamp: start, speedKmh: 60, rpm: 2000, fuelRateLPerHour: 6));
        // A 20-minute connection dropout — not 20 minutes of driving.
        r.onSample(TripSample(
          timestamp: start.add(const Duration(minutes: 20)),
          speedKmh: 60,
          rpm: 2000,
          fuelRateLPerHour: 6,
        ));
        final s = r.buildSummary();
        expect(s.distanceKm, 0,
            reason: 'no distance may be fabricated across the gap');
        expect(s.fuelLitersConsumed ?? 0, 0,
            reason: 'no fuel may be fabricated across the gap');
      });

      test('a long gap does not inflate idle time', () {
        final r = TripRecorder(maxIntegrationGapSeconds: 15);
        final start = DateTime.utc(2026);
        // Stationary, engine on — would clock as "idle" if integrated.
        r.onSample(TripSample(timestamp: start, speedKmh: 0, rpm: 800));
        r.onSample(TripSample(
          timestamp: start.add(const Duration(minutes: 20)),
          speedKmh: 0,
          rpm: 800,
        ));
        expect(r.buildSummary().idleSeconds, 0);
      });

      test('intervals within the cap still integrate normally', () {
        final r = TripRecorder(maxIntegrationGapSeconds: 15);
        final start = DateTime.utc(2026);
        r.onSample(TripSample(timestamp: start, speedKmh: 60, rpm: 2000));
        r.onSample(TripSample(
          timestamp: start.add(const Duration(seconds: 10)),
          speedKmh: 60,
          rpm: 2000,
        ));
        expect(r.buildSummary().distanceKm, closeTo(60 * 10 / 3600, 1e-6));
      });

      test('only the dropout interval is skipped — the rest integrates',
          () {
        final r = TripRecorder(maxIntegrationGapSeconds: 15);
        final start = DateTime.utc(2026);
        r.onSample(TripSample(timestamp: start, speedKmh: 60, rpm: 2000));
        r.onSample(TripSample(
            timestamp: start.add(const Duration(seconds: 10)),
            speedKmh: 60,
            rpm: 2000));
        // 20-minute dropout, then driving resumes.
        r.onSample(TripSample(
            timestamp: start.add(const Duration(minutes: 20, seconds: 10)),
            speedKmh: 60,
            rpm: 2000));
        r.onSample(TripSample(
            timestamp: start.add(const Duration(minutes: 20, seconds: 20)),
            speedKmh: 60,
            rpm: 2000));
        expect(r.buildSummary().distanceKm,
            closeTo(2 * 60 * 10 / 3600, 1e-6));
      });

      test('the default (no cap) integrates any gap — unchanged behaviour',
          () {
        final r = TripRecorder();
        final start = DateTime.utc(2026);
        r.onSample(TripSample(timestamp: start, speedKmh: 60, rpm: 2000));
        r.onSample(TripSample(
          timestamp: start.add(const Duration(minutes: 20)),
          speedKmh: 60,
          rpm: 2000,
        ));
        expect(r.buildSummary().distanceKm, closeTo(60 * 20 / 60, 1e-6));
      });
    });

    group('harsh-event de-noising by distance source (#2653)', () {
      // A backup-like VIRTUAL (dead-reckoning) speed series: the recorder
      // ticks at 1 Hz, but the 1 km/h-quantised virtual speed only steps
      // to a new value every 6 s, bouncing ±15 km/h around a 45 km/h
      // cruise — the classic integrator over/undershoot. The 15 km/h
      // step compressed into a single ~1 s eval window manufactures a
      // phantom harsh event at almost every bounce.
      //
      // On master (source-blind, no sustained/min-speed gate) this
      // measured ~13.3 phantom events/km — far above even the field
      // backup's 4.78 median / 43.4 peak on virtual trips, and orders of
      // magnitude above the 1.06/km of genuine GPS-sourced trips.
      const bounce = <double>[45, 60, 45, 30];

      void feedBounce(TripRecorder r, {required String distanceSource}) {
        final start = DateTime.utc(2026);
        var latched = bounce[0];
        var stepIdx = 0;
        var lastStepSec = 0;
        for (var i = 0; i < 1200; i++) {
          if (i - lastStepSec >= 6) {
            stepIdx++;
            latched = bounce[stepIdx % bounce.length];
            lastStepSec = i;
          }
          r.onSample(
            TripSample(
              timestamp: start.add(Duration(seconds: i)),
              speedKmh: latched,
              rpm: 0,
            ),
            distanceSource: distanceSource,
          );
        }
      }

      test(
          'VIRTUAL source: the dead-reckoning staircase yields < 1.5 '
          'events/km (master ≈ 13.3, suppressed here)', () {
        final r = TripRecorder();
        feedBounce(r, distanceSource: kDistanceSourceVirtual);
        final s = r.buildSummary();
        final total = s.harshBrakes + s.harshAccelerations;
        final perKm = total / s.distanceKm;
        expect(s.distanceKm, greaterThan(10),
            reason: 'sanity: the series should cover ~15 km');
        expect(perKm, lessThan(1.5),
            reason: 'virtual dead-reckoning must not manufacture harsh '
                'events — master counted ~13.3/km here');
        expect(total, 0,
            reason: 'the virtual source is suppressed entirely');
      });

      test(
          'GPS source: the SAME staircase is gated, not suppressed, and '
          'a genuine GPS-fed signal still scores', () {
        // The 6 s-step staircase is an artefact of a coarse virtual
        // odometer; a real GPS Doppler signal does not look like this.
        // We still assert the gps path is NOT wholesale-suppressed by
        // feeding a genuine, well-spaced hard brake on the gps source
        // and confirming it counts.
        final r = TripRecorder();
        final start = DateTime.utc(2026);
        r.onSample(
          TripSample(timestamp: start, speedKmh: 90, rpm: 0, hAccuracyM: 5),
          distanceSource: kDistanceSourceGps,
        );
        r.onSample(
          TripSample(
            timestamp: start.add(const Duration(seconds: 2)),
            speedKmh: 30,
            rpm: 0,
            hAccuracyM: 5,
          ),
          distanceSource: kDistanceSourceGps,
        );
        expect(r.buildSummary().harshBrakes, 1,
            reason: 'gps source must stay enabled-but-gated');
      });

      test('a bad-accuracy GPS fix (> 10 m) is rejected end-to-end', () {
        final r = TripRecorder();
        final start = DateTime.utc(2026);
        r.onSample(
          TripSample(timestamp: start, speedKmh: 90, rpm: 0, hAccuracyM: 4),
          distanceSource: kDistanceSourceGps,
        );
        r.onSample(
          TripSample(
            timestamp: start.add(const Duration(seconds: 2)),
            speedKmh: 30,
            rpm: 0,
            hAccuracyM: 30, // jittery urban-canyon fix
          ),
          distanceSource: kDistanceSourceGps,
        );
        expect(r.buildSummary().harshBrakes, 0,
            reason: 'a bad fix is worse than no fix — not differentiated');
      });

      test('no distanceSource keeps harsh scoring enabled (legacy default)',
          () {
        // The legacy / OBD-speed call site passes no source — the genuine
        // hard brake must still count exactly as before #2653.
        final r = TripRecorder();
        final start = DateTime.utc(2026);
        r.onSample(TripSample(timestamp: start, speedKmh: 90, rpm: 3000));
        r.onSample(TripSample(
          timestamp: start.add(const Duration(seconds: 2)),
          speedKmh: 30,
          rpm: 1500,
        ));
        expect(r.buildSummary().harshBrakes, 1);
      });
    });
  });
}
