import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/gear_inference.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic coverage for the [inferGears] gear-inference module
/// (#1263 phase 1).
///
/// Every test builds a synthetic [TripSample] fixture that simulates
/// known gear regimes — the tests then assert that the centroids land
/// where they should and that the per-sample labels match. The
/// fixtures are deterministic (no randomness) so the assertions can
/// stay tight.

const double _tireC = 1.95; // 195/65R15 ≈ 1.95 m

/// Helper: build a chronological run of [count] samples at fixed
/// (speedKmh, rpm), starting at [start] and stepping by 1 second.
List<TripSample> _steady({
  required DateTime start,
  required int count,
  required double speedKmh,
  required double rpm,
}) {
  return List<TripSample>.generate(
    count,
    (i) => TripSample(
      timestamp: start.add(Duration(seconds: i)),
      speedKmh: speedKmh,
      rpm: rpm,
    ),
    growable: false,
  );
}

/// Helper: build a 5-speed-manual fixture covering all five gears
/// at plausible cruise points. ~600 samples total — large enough for
/// k-means to settle, small enough to stay readable.
///
/// Gear regimes (each ~120 samples at 1 Hz):
/// - 1st: 10 km/h @ 1500 RPM
/// - 2nd: 25 km/h @ 2000 RPM
/// - 3rd: 50 km/h @ 2500 RPM
/// - 4th: 80 km/h @ 2500 RPM
/// - 5th: 110 km/h @ 2500 RPM
List<TripSample> _fiveSpeedFixture({DateTime? start}) {
  final t0 = start ?? DateTime(2026, 4, 28, 8, 0, 0);
  final out = <TripSample>[];
  out.addAll(_steady(start: t0, count: 120, speedKmh: 10, rpm: 1500));
  out.addAll(_steady(
      start: t0.add(const Duration(seconds: 120)),
      count: 120,
      speedKmh: 25,
      rpm: 2000));
  out.addAll(_steady(
      start: t0.add(const Duration(seconds: 240)),
      count: 120,
      speedKmh: 50,
      rpm: 2500));
  out.addAll(_steady(
      start: t0.add(const Duration(seconds: 360)),
      count: 120,
      speedKmh: 80,
      rpm: 2500));
  out.addAll(_steady(
      start: t0.add(const Duration(seconds: 480)),
      count: 120,
      speedKmh: 110,
      rpm: 2500));
  return out;
}

/// Helper: compute the expected ratio for a (speedKmh, rpm) pair —
/// duplicates the formula in the production module so the tests
/// don't drift if a thinko changes one but not the other.
double _expectedRatio(double speedKmh, double rpm) {
  final wheelRpm = (speedKmh / 3.6) / _tireC * 60.0;
  return rpm / wheelRpm;
}

void main() {
  group('inferGears — synthetic 5-speed manual fixture', () {
    test('returns five monotonically-ordered centroids', () {
      final samples = _fiveSpeedFixture();
      final result = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      expect(result.centroids.length, equals(5));
      // Strictly ascending — the module's documented contract.
      for (var i = 1; i < result.centroids.length; i++) {
        expect(
          result.centroids[i],
          greaterThan(result.centroids[i - 1]),
          reason: 'Centroids must be sorted ascending — index $i not '
              '> ${i - 1} (${result.centroids})',
        );
      }
    });

    test('labels each steady-state regime with the expected gear', () {
      final samples = _fiveSpeedFixture();
      final result = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      // Bin labels per regime. Each regime is 120 samples; we expect
      // the dominant label to match the gear number.
      int dominantLabel(List<int?> gears) {
        final counts = <int, int>{};
        for (final g in gears) {
          if (g == null) continue;
          counts[g] = (counts[g] ?? 0) + 1;
        }
        var bestGear = -1;
        var bestCount = -1;
        counts.forEach((g, c) {
          if (c > bestCount) {
            bestCount = c;
            bestGear = g;
          }
        });
        return bestGear;
      }

      // Slice the per-sample output back into the five 120-sample
      // regimes that the fixture built.
      final perRegime = <List<int?>>[
        result.samples.sublist(0, 120).map((s) => s.gear).toList(),
        result.samples.sublist(120, 240).map((s) => s.gear).toList(),
        result.samples.sublist(240, 360).map((s) => s.gear).toList(),
        result.samples.sublist(360, 480).map((s) => s.gear).toList(),
        result.samples.sublist(480, 600).map((s) => s.gear).toList(),
      ];

      // Module convention: gear=1 is 1st gear (highest ratio); the
      // fixture's 1st-gear regime is index 0, and ratios fall as the
      // car climbs up the box. So expected[0] = 1, ..., expected[4] =
      // 5.
      const expectedGears = <int>[1, 2, 3, 4, 5];
      for (var r = 0; r < 5; r++) {
        expect(
          dominantLabel(perRegime[r]),
          equals(expectedGears[r]),
          reason: 'Regime $r (${expectedGears[r]}th gear in fixture) '
              'mislabelled as ${dominantLabel(perRegime[r])}',
        );
      }
    });

    test('returns one InferredGearSample per input sample', () {
      final samples = _fiveSpeedFixture();
      final result = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      expect(result.samples.length, equals(samples.length));
      // Timestamps preserved 1:1.
      for (var i = 0; i < samples.length; i++) {
        expect(
          result.samples[i].timestamp,
          equals(samples[i].timestamp),
          reason: 'Timestamp at index $i not preserved',
        );
      }
    });

    test('does not throw on the five-speed fixture', () {
      expect(
        () => inferGears(
          samples: _fiveSpeedFixture(),
          tireCircumferenceMeters: _tireC,
        ),
        returnsNormally,
      );
    });
  });

  group('inferGears — cold-start vs prior-centroids parity', () {
    test('cold-start centroids match prior-centroid run within 5%', () {
      final samples = _fiveSpeedFixture();

      final coldStart = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      // Feed the cold-start result back as the prior. Same input data,
      // so the second run should converge to (essentially) the same
      // centroids.
      final warmStart = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
        priorCentroids: coldStart.centroids.toList(),
      );

      expect(warmStart.centroids.length, equals(coldStart.centroids.length));
      for (var i = 0; i < coldStart.centroids.length; i++) {
        final relDiff =
            (warmStart.centroids[i] - coldStart.centroids[i]).abs() /
                coldStart.centroids[i];
        expect(
          relDiff,
          lessThan(0.05),
          reason: 'Centroid $i drifted ${(relDiff * 100).toStringAsFixed(2)} '
              '% between cold-start and warm-start — '
              'cold=${coldStart.centroids[i]}, warm=${warmStart.centroids[i]}',
        );
      }
    });
  });

  group('inferGears — drift across trips', () {
    test('second trip skewed to higher RPM drifts but does not override', () {
      // Trip 1 — baseline 5-speed fixture.
      final trip1 = _fiveSpeedFixture();
      final trip1Result = inferGears(
        samples: trip1,
        tireCircumferenceMeters: _tireC,
      );

      // Trip 2 — same speed regimes, but every RPM is bumped by 15 %
      // (driver kept it in lower gears than usual). The drivetrain
      // ratios scale up by the same factor.
      final t0 = DateTime(2026, 4, 29, 8, 0, 0);
      final trip2 = <TripSample>[];
      trip2.addAll(_steady(start: t0, count: 120, speedKmh: 10, rpm: 1725));
      trip2.addAll(_steady(
          start: t0.add(const Duration(seconds: 120)),
          count: 120,
          speedKmh: 25,
          rpm: 2300));
      trip2.addAll(_steady(
          start: t0.add(const Duration(seconds: 240)),
          count: 120,
          speedKmh: 50,
          rpm: 2875));
      trip2.addAll(_steady(
          start: t0.add(const Duration(seconds: 360)),
          count: 120,
          speedKmh: 80,
          rpm: 2875));
      trip2.addAll(_steady(
          start: t0.add(const Duration(seconds: 480)),
          count: 120,
          speedKmh: 110,
          rpm: 2875));

      // Pass trip 1's centroids as prior — k-means re-converges on
      // trip 2's higher-RPM data. Phase 1 doesn't blend the prior
      // with the new data; it's a SEED, not a regulariser. The drift
      // expectation below reflects that — centroids will end up
      // ~15 % higher (the RPM bump fully feeds through).
      final trip2Result = inferGears(
        samples: trip2,
        tireCircumferenceMeters: _tireC,
        priorCentroids: trip1Result.centroids.toList(),
      );

      expect(trip2Result.centroids.length, equals(5));
      // Each centroid should land HIGHER than the trip-1 centroid
      // (drift in the expected direction)…
      for (var i = 0; i < 5; i++) {
        expect(
          trip2Result.centroids[i],
          greaterThan(trip1Result.centroids[i]),
          reason: 'Centroid $i did not drift upward despite higher-RPM '
              'trip 2 — trip1=${trip1Result.centroids[i]}, '
              'trip2=${trip2Result.centroids[i]}',
        );
      }
      // …and within 25 % of the trip-1 centroid (drift, not overwrite
      // — a 15 % RPM bump shouldn't blow past 25 %).
      for (var i = 0; i < 5; i++) {
        final relDiff =
            (trip2Result.centroids[i] - trip1Result.centroids[i]).abs() /
                trip1Result.centroids[i];
        expect(
          relDiff,
          lessThan(0.25),
          reason: 'Centroid $i drifted '
              '${(relDiff * 100).toStringAsFixed(1)}% — trip1='
              '${trip1Result.centroids[i]}, trip2='
              '${trip2Result.centroids[i]}',
        );
      }
    });
  });

  group('inferGears — degenerate fixtures', () {
    test('idle-only fixture: no centroids, all gear=null, no throw', () {
      final t0 = DateTime(2026, 4, 28, 8, 0, 0);
      final samples = _steady(start: t0, count: 60, speedKmh: 0, rpm: 800);

      final result = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      expect(result.centroids, isEmpty);
      expect(result.samples.length, equals(60));
      for (final s in result.samples) {
        expect(s.gear, isNull);
      }
    });

    test('short fixture (5 samples) does not throw', () {
      final t0 = DateTime(2026, 4, 28, 8, 0, 0);
      final samples = <TripSample>[
        TripSample(timestamp: t0, speedKmh: 25, rpm: 2000),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 1)),
            speedKmh: 50,
            rpm: 2500),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 2)),
            speedKmh: 80,
            rpm: 2500),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 3)),
            speedKmh: 110,
            rpm: 2500),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 4)),
            speedKmh: 10,
            rpm: 1500),
      ];

      expect(
        () => inferGears(
          samples: samples,
          tireCircumferenceMeters: _tireC,
        ),
        returnsNormally,
      );

      final result = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      // Five samples → up to five distinct kept ratios → centroids
      // can be 5 (one per sample) or fewer if outlier-trim drops any.
      // We don't assert on centroid count beyond ≤ 5 — fewer-than-N
      // fixtures are explicitly documented as degenerate. We DO
      // assert that every input sample is represented in the output.
      expect(result.samples.length, equals(5));
      expect(result.centroids.length, lessThanOrEqualTo(5));
    });

    test('non-positive tyre circumference returns null gears, no throw', () {
      final samples = _fiveSpeedFixture();

      expect(
        () => inferGears(
          samples: samples,
          tireCircumferenceMeters: 0.0,
        ),
        returnsNormally,
      );

      final result = inferGears(
        samples: samples,
        tireCircumferenceMeters: -1.0,
      );

      expect(result.centroids, isEmpty);
      for (final s in result.samples) {
        expect(s.gear, isNull);
      }
    });
  });

  group('inferGears — outlier robustness', () {
    test('extreme ratio outliers do not pollute the centroids', () {
      // Build the 5-speed fixture and prepend / append a handful of
      // clutch-slipping samples (RPM 5000 at 5.5 km/h → ratio of
      // ~99 — about 6 × the 1st-gear cluster). The module's
      // outlier-trim should drop these before clustering.
      final base = _fiveSpeedFixture();
      final t0 = DateTime(2026, 4, 28, 7, 59, 0);
      final outliers = <TripSample>[
        TripSample(timestamp: t0, speedKmh: 5.5, rpm: 5000),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 1)),
            speedKmh: 5.5,
            rpm: 6000),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 2)),
            speedKmh: 5.5,
            rpm: 5500),
      ];
      final samples = <TripSample>[...outliers, ...base];

      // Run the clean and the polluted fixture through the same
      // function — centroids should match within 10 %.
      final clean = inferGears(
        samples: base,
        tireCircumferenceMeters: _tireC,
      );
      final dirty = inferGears(
        samples: samples,
        tireCircumferenceMeters: _tireC,
      );

      expect(dirty.centroids.length, equals(clean.centroids.length));
      for (var i = 0; i < clean.centroids.length; i++) {
        final relDiff = (dirty.centroids[i] - clean.centroids[i]).abs() /
            clean.centroids[i];
        expect(
          relDiff,
          lessThan(0.10),
          reason: 'Outliers shifted centroid $i by '
              '${(relDiff * 100).toStringAsFixed(2)}% — '
              'clean=${clean.centroids[i]}, dirty=${dirty.centroids[i]}',
        );
      }
    });
  });

  group('inferGears — formula sanity', () {
    test('helper math matches a known regime ratio', () {
      // Ground-truth check: 50 km/h @ 2500 RPM with 1.95 m tyre ≈
      // 5.85 ratio. If this drifts, the production module's formula
      // is wrong.
      final r = _expectedRatio(50, 2500);
      expect(r, closeTo(5.85, 0.02));
    });
  });
}
