import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_speed_consumption_aggregator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/speed_consumption_histogram.dart';

/// Pure-logic coverage for the per-vehicle speed-consumption aggregator
/// (`lib/features/vehicle/data/vehicle_speed_consumption_aggregator.dart`).
///
/// This file is distinct from the trip-level aggregator under
/// `consumption/domain/services/speed_consumption_histogram.dart` —
/// different return type ([SpeedConsumptionHistogram] vs.
/// `List<SpeedConsumptionBin>`), different threshold semantics, and a
/// dedicated incremental-fold variant.
///
/// What's locked down here:
///   * empty / negative-speed input
///   * the 50-sample band-inclusion floor
///     ([kMinSamplesPerSpeedBand])
///   * half-open `[lo, hi)` band classifier (boundaries assert what the
///     implementation does, not what feels intuitive)
///   * `meanLPer100km = Σlitres / Σkm * 100` over a hand-computed mix
///   * null-fuel samples count toward sampleCount + timeShareFraction
///     but contribute zero litres
///   * `timeShareFraction` summing to ~1.0 when every populated band is
///     above threshold
///   * incremental fold with `prior == null` matches closed-form
///     bit-for-bit
void main() {
  group('aggregateSpeedConsumption — empty / degenerate input', () {
    test('returns an empty histogram when input is empty', () {
      final histogram = aggregateSpeedConsumption(const <TripSample>[]);

      expect(histogram.bands, isEmpty);
    });

    test('returns an empty histogram when every sample has negative speed',
        () {
      final samples = List<TripSample>.generate(
        100,
        (_) => _sample(speed: -1.0, fuelRate: 5.0),
      );

      final histogram = aggregateSpeedConsumption(samples);

      // Every sample is skipped by `_classifySpeed`, totalCount stays 0,
      // the early `totalCount == 0` guard fires.
      expect(histogram.bands, isEmpty);
    });
  });

  group('aggregateSpeedConsumption — band-inclusion floor', () {
    test('a band with 49 samples (one shy) is omitted from `bands`', () {
      final samples = List<TripSample>.generate(
        49,
        (_) => _sample(speed: 60.0, fuelRate: 6.0),
      );

      final histogram = aggregateSpeedConsumption(samples);

      expect(histogram.bands, isEmpty);
    });

    test('a band with exactly `kMinSamplesPerSpeedBand` samples IS included',
        () {
      // Sanity-check the constant first — if anyone bumps it the test
      // changes shape, not silently passes.
      expect(kMinSamplesPerSpeedBand, 50);

      final samples = List<TripSample>.generate(
        kMinSamplesPerSpeedBand,
        (_) => _sample(speed: 60.0, fuelRate: 6.0),
      );

      final histogram = aggregateSpeedConsumption(samples);

      expect(histogram.bands, hasLength(1));
      expect(histogram.bands.single.minKmh, 50);
      expect(histogram.bands.single.maxKmh, 80);
      expect(histogram.bands.single.sampleCount, 50);
    });

    test('only bands above the floor are emitted; below-floor are dropped',
        () {
      // 50 samples at 60 km/h (band [50,80)) — passes the floor.
      // 10 samples at 20 km/h (band [0,30))   — below floor, dropped.
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
        ...List<TripSample>.generate(
          10,
          (_) => _sample(speed: 20.0, fuelRate: 2.0),
        ),
      ];

      final histogram = aggregateSpeedConsumption(samples);

      expect(histogram.bands, hasLength(1));
      expect(histogram.bands.single.minKmh, 50);
      expect(histogram.bands.single.sampleCount, 50);
      // totalCount = 60, emitted band's count = 50 → timeShare = 50/60.
      expect(
        histogram.bands.single.timeShareFraction,
        closeTo(50.0 / 60.0, 1e-9),
      );
    });
  });

  group('aggregateSpeedConsumption — half-open band classifier', () {
    test('exactly 0.0 km/h lands in [0, 30) (lower edge inclusive)', () {
      final histogram = _runSingleBand(speed: 0.0, fuelRate: 1.0);

      expect(histogram.bands.single.minKmh, 0);
      expect(histogram.bands.single.maxKmh, 30);
    });

    test('exactly 30.0 km/h lands in [30, 50) (upper edge exclusive)', () {
      final histogram = _runSingleBand(speed: 30.0, fuelRate: 4.0);

      expect(histogram.bands.single.minKmh, 30);
      expect(histogram.bands.single.maxKmh, 50);
    });

    test('exactly 50.0 km/h lands in [50, 80)', () {
      final histogram = _runSingleBand(speed: 50.0, fuelRate: 5.0);

      expect(histogram.bands.single.minKmh, 50);
      expect(histogram.bands.single.maxKmh, 80);
    });

    test('exactly 80.0 km/h lands in [80, 110)', () {
      final histogram = _runSingleBand(speed: 80.0, fuelRate: 6.0);

      expect(histogram.bands.single.minKmh, 80);
      expect(histogram.bands.single.maxKmh, 110);
    });

    test('exactly 110.0 km/h lands in the open-ended [110, null) top band',
        () {
      final histogram = _runSingleBand(speed: 110.0, fuelRate: 7.5);

      expect(histogram.bands.single.minKmh, 110);
      expect(histogram.bands.single.maxKmh, isNull);
    });

    test('a value just under 30.0 still belongs to [0, 30)', () {
      final histogram = _runSingleBand(speed: 29.999, fuelRate: 3.0);

      expect(histogram.bands.single.minKmh, 0);
      expect(histogram.bands.single.maxKmh, 30);
    });

    test('a very high speed (e.g. 200 km/h) lands in the open-ended top band',
        () {
      final histogram = _runSingleBand(speed: 200.0, fuelRate: 12.0);

      expect(histogram.bands.single.minKmh, 110);
      expect(histogram.bands.single.maxKmh, isNull);
    });

    test('negative speed never makes it into any band', () {
      // Mix 50 valid samples (so a band IS emitted) with 50 negative
      // samples — the negatives are skipped, the totalCount reflects
      // ONLY the valid 50.
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: -10.0, fuelRate: 1.0),
        ),
      ];

      final histogram = aggregateSpeedConsumption(samples);

      expect(histogram.bands, hasLength(1));
      expect(histogram.bands.single.sampleCount, 50);
      // Negative samples never bumped totalCount → time share is 1.0.
      expect(histogram.bands.single.timeShareFraction, closeTo(1.0, 1e-9));
    });
  });

  group('aggregateSpeedConsumption — mean L/100 km math', () {
    test('single-band uniform samples: mean = fuelRate / speed * 100', () {
      // 50 samples × (speed=60, fuelRate=6.0).
      //   litres = 50 * 6.0 / 3600 ≈ 0.08333
      //   km     = 50 * 60  / 3600 ≈ 0.83333
      //   mean   = 0.08333 / 0.83333 * 100 = 10.0
      final samples = List<TripSample>.generate(
        50,
        (_) => _sample(speed: 60.0, fuelRate: 6.0),
      );

      final histogram = aggregateSpeedConsumption(samples);

      final band = histogram.bands.single;
      expect(band.sampleCount, 50);
      expect(band.meanLPer100km, closeTo(10.0, 1e-9));
    });

    test('mixed within a single band: Σlitres / Σkm * 100 (not mean of ratios)',
        () {
      // Both speeds land in the [50, 80) band.
      //   30 × (speed=60, fuelRate=6.0) → mean ratio 10.0
      //   30 × (speed=70, fuelRate=14.0) → mean ratio 20.0
      // Mean-of-ratios would yield 15.0.
      // Σ/Σ:
      //   litres = (30*6 + 30*14) / 3600 = 600/3600 = 0.16667
      //   km     = (30*60 + 30*70) / 3600 = 3900/3600 = 1.08333
      //   mean   = 0.16667 / 1.08333 * 100 ≈ 15.3846
      // Asserting the Σ/Σ value catches a regression to mean-of-ratios.
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          30,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
        ...List<TripSample>.generate(
          30,
          (_) => _sample(speed: 70.0, fuelRate: 14.0),
        ),
      ];

      final histogram = aggregateSpeedConsumption(samples);

      final band = histogram.bands.single;
      expect(band.sampleCount, 60);
      expect(band.meanLPer100km, closeTo(600.0 / 3900.0 * 100.0, 1e-9));
    });

    test('two populated bands: each band carries its own correct mean', () {
      // 50 × (speed=20, fuelRate=2.0) → band [0, 30) → mean 10.0
      // 50 × (speed=60, fuelRate=6.0) → band [50, 80) → mean 10.0
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 20.0, fuelRate: 2.0),
        ),
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
      ];

      final histogram = aggregateSpeedConsumption(samples);

      expect(histogram.bands, hasLength(2));
      // Bands emitted in template order — [0,30) first, then [50,80).
      final low = histogram.bands.firstWhere((b) => b.minKmh == 0);
      final mid = histogram.bands.firstWhere((b) => b.minKmh == 50);
      expect(low.meanLPer100km, closeTo(10.0, 1e-9));
      expect(mid.meanLPer100km, closeTo(10.0, 1e-9));
      expect(low.sampleCount, 50);
      expect(mid.sampleCount, 50);
      // 100 total → each share = 0.5.
      expect(low.timeShareFraction, closeTo(0.5, 1e-9));
      expect(mid.timeShareFraction, closeTo(0.5, 1e-9));
    });
  });

  group('aggregateSpeedConsumption — null fuel rate', () {
    test('null fuel still counts toward sampleCount and timeShareFraction',
        () {
      // 50 samples at speed=60 km/h, every one with `fuelRateLPerHour`
      // null. The band passes the floor (count=50) but contributes zero
      // litres. km > 0 because km only depends on speed, but litres = 0
      // → mean = 0.0.
      final samples = List<TripSample>.generate(
        50,
        (_) => _sample(speed: 60.0),
      );

      final histogram = aggregateSpeedConsumption(samples);

      expect(histogram.bands, hasLength(1));
      final band = histogram.bands.single;
      expect(band.sampleCount, 50);
      expect(band.timeShareFraction, closeTo(1.0, 1e-9));
      // Σlitres = 0, Σkm > 0 → mean = 0.0 / km * 100 = 0.0.
      expect(band.meanLPer100km, 0.0);
    });

    test('mixed null + non-null fuel: null contributes 0 L, non-null integrates',
        () {
      // 50 samples in band [50, 80):
      //   25 with fuelRate=6.0 → contribute 25*6/3600 = 0.04167 L
      //   25 with fuelRate=null → contribute 0 L
      // km is integrated over ALL 50 (km cares about speed only):
      //   km = 50 * 60 / 3600 = 0.83333
      // mean = 0.04167 / 0.83333 * 100 = 5.0
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          25,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
        ...List<TripSample>.generate(
          25,
          (_) => _sample(speed: 60.0),
        ),
      ];

      final histogram = aggregateSpeedConsumption(samples);

      final band = histogram.bands.single;
      expect(band.sampleCount, 50);
      expect(band.meanLPer100km, closeTo(5.0, 1e-9));
    });
  });

  group('aggregateSpeedConsumption — time share roll-up', () {
    test('timeShareFraction sums to ~1.0 when every populated band is above '
        'the floor', () {
      // Two populated bands, each at exactly the floor. Every sample is
      // counted (no negative speeds), so totalCount = 100 and the two
      // shares (0.5 + 0.5) sum to 1.0.
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 20.0, fuelRate: 2.0),
        ),
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
      ];

      final histogram = aggregateSpeedConsumption(samples);

      final sumShares = histogram.bands
          .map((b) => b.timeShareFraction)
          .fold<double>(0.0, (acc, x) => acc + x);
      expect(sumShares, closeTo(1.0, 1e-9));
    });
  });

  group('foldSpeedConsumptionIncremental — cold start', () {
    test('null prior + empty samples returns an empty histogram', () {
      final histogram =
          foldSpeedConsumptionIncremental(null, const <TripSample>[]);

      expect(histogram.bands, isEmpty);
    });

    test('null prior + samples matches closed-form (bit-for-bit on counts, '
        'time shares, and mean-L/100 km)', () {
      // Mixed input across two populated bands AND a sub-threshold band
      // — exercises the floor-skip + totalCount accounting in BOTH
      // entry points.
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 20.0, fuelRate: 2.0),
        ),
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 60.0, fuelRate: 6.0),
        ),
        ...List<TripSample>.generate(
          10,
          (_) => _sample(speed: 100.0, fuelRate: 8.0),
        ),
      ];

      final viaClosed = aggregateSpeedConsumption(samples);
      final viaFold = foldSpeedConsumptionIncremental(null, samples);

      // Same number of emitted bands (both filter at floor identically).
      expect(viaFold.bands.length, viaClosed.bands.length);

      for (var i = 0; i < viaClosed.bands.length; i++) {
        final a = viaClosed.bands[i];
        final b = viaFold.bands[i];
        expect(b.minKmh, a.minKmh);
        expect(b.maxKmh, a.maxKmh);
        expect(b.sampleCount, a.sampleCount);
        expect(b.timeShareFraction, closeTo(a.timeShareFraction, 1e-12));
        expect(b.meanLPer100km, closeTo(a.meanLPer100km, 1e-12));
      }
    });

    test('null prior + null-fuel samples folds correctly (zero litres)', () {
      // 50 samples in [50, 80) — every fuelRate is null. Cold-start
      // fold should return one band, count=50, mean=0.0.
      final samples = List<TripSample>.generate(
        50,
        (_) => _sample(speed: 60.0),
      );

      final histogram = foldSpeedConsumptionIncremental(null, samples);

      expect(histogram.bands, hasLength(1));
      final band = histogram.bands.single;
      expect(band.minKmh, 50);
      expect(band.maxKmh, 80);
      expect(band.sampleCount, 50);
      expect(band.meanLPer100km, 0.0);
      expect(band.timeShareFraction, closeTo(1.0, 1e-9));
    });

    test('non-null prior with sub-threshold seeded counters: new samples '
        'tip the band over the floor', () {
      // Build a "prior" that already had a populated band — say, the
      // result of a closed-form aggregate over 50 samples in [50, 80).
      // Then fold one more matching sample. The lossy reconstruction
      // means we cannot assert the EXACT mean, but we CAN assert:
      //   * the band still appears in the output
      //   * sampleCount is monotone (>= 51)
      //   * minKmh / maxKmh match the template
      final priorSamples = List<TripSample>.generate(
        50,
        (_) => _sample(speed: 60.0, fuelRate: 6.0),
      );
      final prior = aggregateSpeedConsumption(priorSamples);
      expect(prior.bands, hasLength(1));

      final extra = <TripSample>[_sample(speed: 60.0, fuelRate: 6.0)];
      final folded = foldSpeedConsumptionIncremental(prior, extra);

      expect(folded.bands, hasLength(1));
      final band = folded.bands.single;
      expect(band.minKmh, 50);
      expect(band.maxKmh, 80);
      expect(band.sampleCount, 51);
    });
  });
}

/// Build a [TripSample] with default safe values and only the
/// parameters we care about overriding. The aggregator only reads
/// `speedKmh` and `fuelRateLPerHour`; `rpm` / `timestamp` are pinned to
/// keep fixtures readable.
TripSample _sample({
  required double speed,
  double? fuelRate,
}) {
  return TripSample(
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    speedKmh: speed,
    rpm: 0.0,
    fuelRateLPerHour: fuelRate,
  );
}

/// Run the closed-form aggregator on [kMinSamplesPerSpeedBand] samples
/// of the same `(speed, fuelRate)` pair so the resulting histogram is
/// guaranteed to have exactly one populated band — the band classifier
/// boundary tests use this to assert which band the boundary value
/// landed in.
SpeedConsumptionHistogram _runSingleBand({
  required double speed,
  required double fuelRate,
}) {
  final samples = List<TripSample>.generate(
    kMinSamplesPerSpeedBand,
    (_) => _sample(speed: speed, fuelRate: fuelRate),
  );
  return aggregateSpeedConsumption(samples);
}
