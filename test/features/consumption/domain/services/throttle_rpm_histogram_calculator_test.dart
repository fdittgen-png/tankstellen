import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/throttle_rpm_histogram_calculator.dart';

/// Pure-logic coverage for `calculateThrottleRpmHistogram` (#1041 phase
/// 3a — Card C).
///
/// The calculator is the data feed for the `ThrottleRpmHistogramCard`
/// widget; the widget tests pump fixed histograms, so the maths /
/// edge-case behaviour MUST be locked down here. The tests are split
/// into:
///   * input-shape edge cases (empty, single sample, non-monotonic
///     timestamps) — all return all-zero histograms
///   * axis-isolation (throttle null shouldn't erase RPM weight, and
///     vice versa)
///   * bucketing (every band edge tested at the boundary)
///   * sums-to-one invariant on every populated axis
void main() {
  group('calculateThrottleRpmHistogram — empty / degenerate input', () {
    test('returns all-zero histograms when samples is empty', () {
      final result = calculateThrottleRpmHistogram(const []);

      expect(result.throttleQuartiles, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(result.rpmBands, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(result.hasData, isFalse);
    });

    test('returns all-zero histograms when only a single sample is given',
        () {
      final result = calculateThrottleRpmHistogram([
        ThrottleRpmSample(
          timestamp: DateTime(2026, 1, 1, 8, 0, 0),
          throttlePercent: 30.0,
          rpm: 1500,
        ),
      ]);

      // No successor → no dt → no weight credited to any bucket.
      expect(result.throttleQuartiles, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(result.rpmBands, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(result.hasData, isFalse);
    });

    test('skips intervals with non-monotonic timestamps', () {
      final t0 = DateTime(2026, 1, 1, 8, 0, 0);
      final result = calculateThrottleRpmHistogram([
        ThrottleRpmSample(timestamp: t0, throttlePercent: 30, rpm: 1500),
        // dt <= 0 → interval skipped
        ThrottleRpmSample(
          timestamp: t0,
          throttlePercent: 30,
          rpm: 1500,
        ),
      ]);

      expect(result.throttleQuartiles, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(result.rpmBands, equals(<double>[0.0, 0.0, 0.0, 0.0]));
    });
  });

  group('calculateThrottleRpmHistogram — throttle bucketing', () {
    test('credits 100% to the 0–25 bucket when throttle stays at coast', () {
      // 4 intervals → 5 samples; every START sample is in bucket 0.
      final samples = _evenlySpaced(
        durations: const [1, 1, 1, 1],
        throttle: const [0, 5, 10, 20, 24],
        rpm: const [800, 800, 800, 800, 800],
      );

      final result = calculateThrottleRpmHistogram(samples);

      // All four intervals (4s) credit bucket 0; the trailing sample
      // carries no dt of its own.
      expect(result.throttleQuartiles[0], closeTo(1.0, 1e-9));
      expect(result.throttleQuartiles[1], 0.0);
      expect(result.throttleQuartiles[2], 0.0);
      expect(result.throttleQuartiles[3], 0.0);
    });

    test('25.0% lands in the 25–50 bucket (boundary is exclusive on left)',
        () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [25.0, 25.0],
        rpm: const [1500, 1500],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles[0], 0.0);
      expect(result.throttleQuartiles[1], closeTo(1.0, 1e-9));
      expect(result.throttleQuartiles[2], 0.0);
      expect(result.throttleQuartiles[3], 0.0);
    });

    test(
        '75.0% lands in the 75–100 bucket (top quartile is closed on the right)',
        () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [75.0, 75.0],
        rpm: const [3500, 3500],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles[3], closeTo(1.0, 1e-9));
    });

    test('clamps over-100 throttle into the top quartile', () {
      // Defensive — no real OBD2 stream emits >100, but a bad parser
      // shouldn't blow the histogram up. 150 → bucket 3.
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [150, 150],
        rpm: const [1500, 1500],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles[3], closeTo(1.0, 1e-9));
    });

    test('clamps negative throttle into the bottom quartile', () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [-5, -5],
        rpm: const [1500, 1500],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles[0], closeTo(1.0, 1e-9));
    });

    test('weights buckets proportionally to dt, not sample count', () {
      // Two intervals, same throttle each (one in bucket 1, one in
      // bucket 2). The longer interval should dominate.
      final t0 = DateTime(2026, 1, 1, 8, 0, 0);
      final samples = <ThrottleRpmSample>[
        ThrottleRpmSample(
          timestamp: t0,
          throttlePercent: 30, // bucket 1
          rpm: 1500,
        ),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 9)),
          throttlePercent: 60, // bucket 2 — short interval (1s) starts here
          rpm: 1500,
        ),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 10)),
          throttlePercent: 60,
          rpm: 1500,
        ),
      ];

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles[1], closeTo(0.9, 1e-9));
      expect(result.throttleQuartiles[2], closeTo(0.1, 1e-9));
    });
  });

  group('calculateThrottleRpmHistogram — RPM bucketing', () {
    test('900 RPM stays in idle (band 0)', () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [10, 10],
        rpm: const [900, 900],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.rpmBands[0], closeTo(1.0, 1e-9));
    });

    test('901 RPM crosses into cruise (band 1)', () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [10, 10],
        rpm: const [901, 901],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.rpmBands[0], 0.0);
      expect(result.rpmBands[1], closeTo(1.0, 1e-9));
    });

    test('2000 RPM stays in cruise (band 1)', () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [10, 10],
        rpm: const [2000, 2000],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.rpmBands[1], closeTo(1.0, 1e-9));
    });

    test('2001 RPM crosses into spirited (band 2)', () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [10, 10],
        rpm: const [2001, 2001],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.rpmBands[2], closeTo(1.0, 1e-9));
    });

    test('3000 RPM stays in spirited (band 2)', () {
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [10, 10],
        rpm: const [3000, 3000],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.rpmBands[2], closeTo(1.0, 1e-9));
    });

    test('3001 RPM crosses into hard (band 3) — matches analyzer threshold',
        () {
      // The "hard" cutoff intentionally aligns with the analyzer's
      // 3000 RPM threshold so the histogram and the
      // "Engine over 3000 RPM" insight tell a consistent story.
      final samples = _evenlySpaced(
        durations: const [1],
        throttle: const [10, 10],
        rpm: const [3001, 3001],
      );

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.rpmBands[3], closeTo(1.0, 1e-9));
    });
  });

  group('calculateThrottleRpmHistogram — null handling', () {
    test('null throttle in a sample skips that interval on throttle axis only',
        () {
      // Three samples, two intervals. First sample has null throttle
      // (interval 0 contributes to RPM only); second sample drives
      // throttle into bucket 2 (interval 1 contributes to both axes).
      final t0 = DateTime(2026, 1, 1, 8, 0, 0);
      final samples = <ThrottleRpmSample>[
        ThrottleRpmSample(
          timestamp: t0,
          throttlePercent: null,
          rpm: 1500,
        ),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 1)),
          throttlePercent: 60, // bucket 2
          rpm: 1500,
        ),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 2)),
          throttlePercent: 60,
          rpm: 1500,
        ),
      ];

      final result = calculateThrottleRpmHistogram(samples);

      // RPM saw 2s in band 1 (cruise): both intervals contribute.
      expect(result.rpmBands[1], closeTo(1.0, 1e-9));
      // Throttle only saw 1s of usable data — but it's still
      // normalized to 1.0 because that's the whole valid throttle
      // window.
      expect(result.throttleQuartiles[2], closeTo(1.0, 1e-9));
    });

    test('null RPM in a sample skips that interval on RPM axis only', () {
      final t0 = DateTime(2026, 1, 1, 8, 0, 0);
      final samples = <ThrottleRpmSample>[
        ThrottleRpmSample(
          timestamp: t0,
          throttlePercent: 60, // bucket 2
          rpm: null,
        ),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 1)),
          throttlePercent: 60,
          rpm: 1500, // band 1
        ),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 2)),
          throttlePercent: 60,
          rpm: 1500,
        ),
      ];

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles[2], closeTo(1.0, 1e-9));
      expect(result.rpmBands[1], closeTo(1.0, 1e-9));
    });

    test(
        'all-null throttle but valid RPM yields all-zero throttle, populated RPM',
        () {
      final t0 = DateTime(2026, 1, 1, 8, 0, 0);
      final samples = <ThrottleRpmSample>[
        ThrottleRpmSample(timestamp: t0, throttlePercent: null, rpm: 1500),
        ThrottleRpmSample(
          timestamp: t0.add(const Duration(seconds: 1)),
          throttlePercent: null,
          rpm: 1500,
        ),
      ];

      final result = calculateThrottleRpmHistogram(samples);

      expect(result.throttleQuartiles, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(result.rpmBands[1], closeTo(1.0, 1e-9));
      expect(result.hasData, isTrue);
    });
  });

  group('calculateThrottleRpmHistogram — sums-to-one invariant', () {
    test('throttle quartiles sum to 1.0 across a mixed trip', () {
      // 8 intervals (durations) → 9 samples (one more than gaps). The
      // last sample is the trailing one — its bucket carries no dt.
      // Two intervals land in each of the four buckets.
      final samples = _evenlySpaced(
        durations: const [1, 1, 1, 1, 1, 1, 1, 1],
        throttle: const [
          0, // bucket 0 → 1s
          24, // bucket 0 → 1s
          25, // bucket 1 → 1s
          49, // bucket 1 → 1s
          50, // bucket 2 → 1s
          74, // bucket 2 → 1s
          75, // bucket 3 → 1s
          100, // bucket 3 → 1s
          100, // trailing — no dt of its own
        ],
        rpm: const [
          900,
          901,
          1500,
          2000,
          2001,
          2500,
          3000,
          3001,
          3500,
        ],
      );

      final result = calculateThrottleRpmHistogram(samples);

      final throttleSum = result.throttleQuartiles.reduce((a, b) => a + b);
      expect(throttleSum, closeTo(1.0, 1e-9));
      // 8 intervals total, 2 per bucket → 0.25 each.
      expect(result.throttleQuartiles[0], closeTo(0.25, 1e-9));
      expect(result.throttleQuartiles[1], closeTo(0.25, 1e-9));
      expect(result.throttleQuartiles[2], closeTo(0.25, 1e-9));
      expect(result.throttleQuartiles[3], closeTo(0.25, 1e-9));
    });

    test('rpm bands sum to 1.0 across a mixed trip', () {
      final samples = _evenlySpaced(
        durations: const [1, 1, 1, 1],
        throttle: const [10, 10, 10, 10, 10],
        rpm: const [
          800, // idle
          1500, // cruise
          2500, // spirited
          3500, // hard
          3500,
        ],
      );

      final result = calculateThrottleRpmHistogram(samples);

      final rpmSum = result.rpmBands.reduce((a, b) => a + b);
      expect(rpmSum, closeTo(1.0, 1e-9));
      // Each START sample owns 1s; 4 intervals total → each populated
      // band gets 0.25.
      expect(result.rpmBands[0], closeTo(0.25, 1e-9));
      expect(result.rpmBands[1], closeTo(0.25, 1e-9));
      expect(result.rpmBands[2], closeTo(0.25, 1e-9));
      expect(result.rpmBands[3], closeTo(0.25, 1e-9));
    });
  });

  group('ThrottleRpmHistogram.empty / hasData', () {
    test('empty constant has all-zero arrays and hasData == false', () {
      const h = ThrottleRpmHistogram.empty;
      expect(h.throttleQuartiles, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(h.rpmBands, equals(<double>[0.0, 0.0, 0.0, 0.0]));
      expect(h.hasData, isFalse);
    });

    test('hasData true when any throttle bucket is non-zero', () {
      const h = ThrottleRpmHistogram(
        throttleQuartiles: [0.0, 0.5, 0.5, 0.0],
        rpmBands: [0.0, 0.0, 0.0, 0.0],
      );
      expect(h.hasData, isTrue);
    });

    test('hasData true when any RPM band is non-zero', () {
      const h = ThrottleRpmHistogram(
        throttleQuartiles: [0.0, 0.0, 0.0, 0.0],
        rpmBands: [0.5, 0.5, 0.0, 0.0],
      );
      expect(h.hasData, isTrue);
    });
  });
}

/// Build a chronologically-ordered list of [ThrottleRpmSample]s where
/// consecutive samples are spaced by [durations] (in seconds) and
/// carry the matching entries from [throttle] / [rpm].
///
/// `throttle` and `rpm` MUST have length `durations.length + 1` —
/// each duration is the gap to the next sample, so we need one more
/// sample than gap. This helper keeps the arithmetic-heavy tests
/// terse.
List<ThrottleRpmSample> _evenlySpaced({
  required List<int> durations,
  required List<num> throttle,
  required List<num> rpm,
}) {
  expect(
    throttle.length,
    durations.length + 1,
    reason: 'throttle list must be one longer than durations',
  );
  expect(
    rpm.length,
    durations.length + 1,
    reason: 'rpm list must be one longer than durations',
  );

  var t = DateTime(2026, 1, 1, 8, 0, 0);
  final out = <ThrottleRpmSample>[];
  out.add(ThrottleRpmSample(
    timestamp: t,
    throttlePercent: throttle[0].toDouble(),
    rpm: rpm[0].toDouble(),
  ));
  for (int i = 0; i < durations.length; i++) {
    t = t.add(Duration(seconds: durations[i]));
    out.add(ThrottleRpmSample(
      timestamp: t,
      throttlePercent: throttle[i + 1].toDouble(),
      rpm: rpm[i + 1].toDouble(),
    ));
  }
  return out;
}
