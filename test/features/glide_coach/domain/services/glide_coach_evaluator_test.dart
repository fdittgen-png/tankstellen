// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/glide_coach/data/osm_traffic_signal_client.dart';
import 'package:tankstellen/features/glide_coach/data/traffic_signal_repository.dart';
import 'package:tankstellen/features/glide_coach/domain/entities/glide_coach_advice.dart';
import 'package:tankstellen/features/glide_coach/domain/entities/traffic_signal.dart';
import 'package:tankstellen/features/glide_coach/domain/services/glide_coach_evaluator.dart';
import 'package:tankstellen/features/glide_coach/domain/services/imminent_signal_detector.dart';

/// Test double for [TrafficSignalRepository] mirroring the pattern in
/// `imminent_signal_detector_test.dart`. The evaluator never calls the
/// repo directly — it always goes through the detector — so the stub
/// only needs to drive the bbox response that the detector will
/// inspect.
class _StubRepo implements TrafficSignalRepository {
  List<TrafficSignal> response;
  Object? errorToThrow;

  _StubRepo({this.response = const <TrafficSignal>[], this.errorToThrow});

  @override
  Future<List<TrafficSignal>> getSignalsForBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final err = errorToThrow;
    if (err != null) throw err;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Convenience: a [GpsReading] anchored on the Paris reference point
/// the detector tests use, with a configurable heading. The exact
/// coordinates are irrelevant for the evaluator — what matters is
/// that the detector reaches into the (stubbed) repo.
GpsReading _reading({double heading = 0.0}) =>
    (latitude: 48.8566, longitude: 2.3522, headingDegrees: heading);

/// A traffic signal that lies ~80 m due north of the Paris anchor —
/// inside the detector's default 200 m horizon and ±20° forward cone
/// when the user heads north. We hand-pick a tiny lat offset that
/// keeps every test deterministic without dragging in the metre-offset
/// helper from the detector test.
TrafficSignal _aheadSignal() {
  // 80 m of latitude ≈ 0.0007°. Due north of (48.8566, 2.3522).
  return const TrafficSignal(id: 'ahead', lat: 48.8573, lng: 2.3522);
}

void main() {
  group('GlideCoachEvaluator (#1125 phase 3a)', () {
    test(
      'rule 5 — throttle above threshold + signal ahead → lift',
      () async {
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        final evaluator = GlideCoachEvaluator(detector: detector);

        final advice = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(advice, GlideCoachAdvice.lift);
      },
    );

    test(
      'rule 2 — null throttle (no PID 0x11) → hold (under-trigger)',
      () async {
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        final evaluator = GlideCoachEvaluator(detector: detector);

        final advice = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: null,
        );
        expect(advice, GlideCoachAdvice.hold);
      },
    );

    test(
      'rule 3 — throttle below threshold (already coasting) → hold',
      () async {
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        final evaluator = GlideCoachEvaluator(detector: detector);

        final advice = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 5.0,
        );
        expect(advice, GlideCoachAdvice.hold);
      },
    );

    test('rule 4 — detector returns null (no signal ahead) → hold', () async {
      final repo = _StubRepo(response: const <TrafficSignal>[]);
      final detector = ImminentSignalDetector(repo: repo);
      final evaluator = GlideCoachEvaluator(detector: detector);

      final advice = await evaluator.evaluate(
        reading: _reading(),
        throttlePercent: 45.0,
      );
      expect(advice, GlideCoachAdvice.hold);
    });

    test(
      'rule 1 — second call within cool-down → cooldown (no re-fire)',
      () async {
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        var clock = DateTime(2026, 5, 6, 12, 0, 0);
        final evaluator = GlideCoachEvaluator(
          detector: detector,
          now: () => clock,
        );

        final first = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(first, GlideCoachAdvice.lift);

        // 5 seconds later — well inside the default 15s cool-down.
        clock = clock.add(const Duration(seconds: 5));
        final second = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(second, GlideCoachAdvice.cooldown);
      },
    );

    test(
      'rule 1 — call after cool-down expires → lift again',
      () async {
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        var clock = DateTime(2026, 5, 6, 12, 0, 0);
        final evaluator = GlideCoachEvaluator(
          detector: detector,
          now: () => clock,
        );

        final first = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(first, GlideCoachAdvice.lift);

        // 16 seconds — one second past the default 15s cool-down.
        clock = clock.add(const Duration(seconds: 16));
        final second = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(second, GlideCoachAdvice.lift);
      },
    );

    test('custom cool-down (5s) — exact-boundary behaviour', () async {
      final repo = _StubRepo(response: [_aheadSignal()]);
      final detector = ImminentSignalDetector(repo: repo);
      var clock = DateTime(2026, 5, 6, 12, 0, 0);
      final evaluator = GlideCoachEvaluator(
        detector: detector,
        cooldown: const Duration(seconds: 5),
        now: () => clock,
      );

      final first = await evaluator.evaluate(
        reading: _reading(),
        throttlePercent: 45.0,
      );
      expect(first, GlideCoachAdvice.lift);

      // 4s later — still inside the 5s window.
      clock = clock.add(const Duration(seconds: 4));
      final inside = await evaluator.evaluate(
        reading: _reading(),
        throttlePercent: 45.0,
      );
      expect(inside, GlideCoachAdvice.cooldown);

      // Exactly 5s after the lift — boundary is "strictly less than
      // cooldown", so we are no longer suppressed.
      clock = clock.add(const Duration(seconds: 1));
      final boundary = await evaluator.evaluate(
        reading: _reading(),
        throttlePercent: 45.0,
      );
      expect(
        boundary,
        GlideCoachAdvice.lift,
        reason:
            'cool-down boundary is strict less-than; at exactly the '
            'window length the next lift is allowed.',
      );
    });

    test(
      'custom throttle threshold (40%) — 35% holds, 45% lifts',
      () async {
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        final below = GlideCoachEvaluator(
          detector: detector,
          throttleThresholdPercent: 40.0,
        );

        final adviceBelow = await below.evaluate(
          reading: _reading(),
          throttlePercent: 35.0,
        );
        expect(adviceBelow, GlideCoachAdvice.hold);

        // Fresh evaluator so the cool-down state from below doesn't
        // leak.
        final above = GlideCoachEvaluator(
          detector: detector,
          throttleThresholdPercent: 40.0,
        );
        final adviceAbove = await above.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(adviceAbove, GlideCoachAdvice.lift);
      },
    );

    test(
      'detector errors are swallowed by phase-2 contract → evaluator returns hold',
      () async {
        // The phase-2 detector swallows repo exceptions internally and
        // returns null. The evaluator inherits that under-trigger
        // preference for free; verify the chain end-to-end so a future
        // detector refactor that re-throws is caught here.
        final repo = _StubRepo(
          errorToThrow: const OsmTrafficSignalException('overpass down'),
        );
        final detector = ImminentSignalDetector(repo: repo);
        final evaluator = GlideCoachEvaluator(detector: detector);

        final advice = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(advice, GlideCoachAdvice.hold);
      },
    );

    test(
      'sequence: hold → lift → cooldown → cooldown → lift (after time)',
      () async {
        // Empty response first → hold; then signal appears → lift;
        // two ticks inside cool-down → cooldown × 2; advance past
        // cool-down → lift again.
        final repo = _StubRepo(response: const <TrafficSignal>[]);
        final detector = ImminentSignalDetector(repo: repo);
        var clock = DateTime(2026, 5, 6, 12, 0, 0);
        final evaluator = GlideCoachEvaluator(
          detector: detector,
          now: () => clock,
        );

        // Tick 1 — no signal in the bbox.
        final tick1 = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(tick1, GlideCoachAdvice.hold);

        // Signal appears in the bbox; advance the clock a touch so
        // sequencing is realistic.
        repo.response = [_aheadSignal()];
        clock = clock.add(const Duration(seconds: 1));

        // Tick 2 — first lift.
        final tick2 = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(tick2, GlideCoachAdvice.lift);

        // Tick 3 — 5s into the 15s cool-down.
        clock = clock.add(const Duration(seconds: 5));
        final tick3 = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(tick3, GlideCoachAdvice.cooldown);

        // Tick 4 — 10s into cool-down. Still suppressed.
        clock = clock.add(const Duration(seconds: 5));
        final tick4 = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(tick4, GlideCoachAdvice.cooldown);

        // Tick 5 — 16s after the lift, cool-down expired.
        clock = clock.add(const Duration(seconds: 6));
        final tick5 = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(tick5, GlideCoachAdvice.lift);
      },
    );

    test(
      'cool-down state is NOT extended by repeated cooldown returns',
      () async {
        // Regression: a flurry of GPS ticks during the cool-down
        // window must not push the next eligible buzz further out —
        // only `lift` updates the timestamp.
        final repo = _StubRepo(response: [_aheadSignal()]);
        final detector = ImminentSignalDetector(repo: repo);
        var clock = DateTime(2026, 5, 6, 12, 0, 0);
        final evaluator = GlideCoachEvaluator(
          detector: detector,
          now: () => clock,
        );

        final first = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(first, GlideCoachAdvice.lift);

        // Spam ticks every second through the cool-down.
        for (var i = 1; i <= 14; i++) {
          clock = clock.add(const Duration(seconds: 1));
          final tick = await evaluator.evaluate(
            reading: _reading(),
            throttlePercent: 45.0,
          );
          expect(
            tick,
            GlideCoachAdvice.cooldown,
            reason: 'tick=$i should still be suppressed',
          );
        }

        // 15s after the lift — boundary, no longer suppressed.
        clock = clock.add(const Duration(seconds: 1));
        final reFire = await evaluator.evaluate(
          reading: _reading(),
          throttlePercent: 45.0,
        );
        expect(
          reFire,
          GlideCoachAdvice.lift,
          reason:
              'cool-down should NOT have been extended by the 14 '
              'cooldown returns; the second lift fires exactly at the '
              'window boundary.',
        );
      },
    );
  });
}
