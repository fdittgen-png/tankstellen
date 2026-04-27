import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/speed_consumption_histogram.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Pure-logic coverage for `aggregateSpeedConsumption` (#1192).
///
/// Locks down the bin boundaries, sample skip rules, statistical floor,
/// idle/jam carve-out, and avg-of-aggregates math. The widget pumps
/// pre-built bins, so this is the only file that exercises the actual
/// folding behaviour.
void main() {
  group('aggregateSpeedConsumption — empty / degenerate input', () {
    test('returns 7 zero-bins (one per band) when input is empty', () {
      final bins = aggregateSpeedConsumption(const <TripSample>[]);

      expect(bins.length, SpeedBand.values.length);
      // Bins land in declaration order so the chart can render
      // top-to-bottom without re-sorting.
      for (var i = 0; i < SpeedBand.values.length; i++) {
        expect(bins[i].band, SpeedBand.values[i]);
        expect(bins[i].sampleCount, 0);
        expect(bins[i].timeShareSeconds, 0.0);
        expect(bins[i].avgLPer100Km, isNull);
      }
    });

    test('skips samples with fuelRateLPerHour == null entirely', () {
      // Three samples, none with fuel rate → no bin sees them.
      final bins = aggregateSpeedConsumption([
        _sample(speed: 5.0),
        _sample(speed: 70.0),
        _sample(speed: 130.0),
      ]);

      for (final bin in bins) {
        expect(bin.sampleCount, 0);
        expect(bin.timeShareSeconds, 0.0);
      }
    });

    test('skips samples with negative speed (sensor glitch)', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: -1.0, fuelRate: 8.0),
        _sample(speed: -5.0, fuelRate: 6.0),
      ]);

      for (final bin in bins) {
        expect(bin.sampleCount, 0);
      }
    });
  });

  group('aggregateSpeedConsumption — bin boundaries', () {
    test('exactly 10.0 km/h lands in urban (lower edge inclusive)', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 10.0, fuelRate: 4.0),
      ]);
      expect(_binFor(bins, SpeedBand.idleJam).sampleCount, 0);
      expect(_binFor(bins, SpeedBand.urban).sampleCount, 1);
    });

    test('exactly 50.0 km/h lands in suburban', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 50.0, fuelRate: 5.0),
      ]);
      expect(_binFor(bins, SpeedBand.urban).sampleCount, 0);
      expect(_binFor(bins, SpeedBand.suburban).sampleCount, 1);
    });

    test('exactly 80.0 km/h lands in rural', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 80.0, fuelRate: 6.0),
      ]);
      expect(_binFor(bins, SpeedBand.suburban).sampleCount, 0);
      expect(_binFor(bins, SpeedBand.rural).sampleCount, 1);
    });

    test('exactly 100.0 km/h lands in motorwaySlow', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 100.0, fuelRate: 6.5),
      ]);
      expect(_binFor(bins, SpeedBand.rural).sampleCount, 0);
      expect(_binFor(bins, SpeedBand.motorwaySlow).sampleCount, 1);
    });

    test('exactly 115.0 km/h lands in motorway', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 115.0, fuelRate: 7.0),
      ]);
      expect(_binFor(bins, SpeedBand.motorwaySlow).sampleCount, 0);
      expect(_binFor(bins, SpeedBand.motorway).sampleCount, 1);
    });

    test('exactly 130.0 km/h lands in motorwayFast (top band, no upper)', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 130.0, fuelRate: 9.0),
      ]);
      expect(_binFor(bins, SpeedBand.motorway).sampleCount, 0);
      expect(_binFor(bins, SpeedBand.motorwayFast).sampleCount, 1);
    });

    test('a value just under 10.0 lands in idleJam', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 9.999, fuelRate: 1.5),
      ]);
      expect(_binFor(bins, SpeedBand.idleJam).sampleCount, 1);
    });
  });

  group('aggregateSpeedConsumption — under-threshold floor', () {
    test('a single sample under threshold has avgLPer100Km null', () {
      final bins = aggregateSpeedConsumption([
        _sample(speed: 70.0, fuelRate: 8.0),
      ]);

      final suburban = _binFor(bins, SpeedBand.suburban);
      expect(suburban.sampleCount, 1);
      expect(suburban.timeShareSeconds, 1.0);
      // 1 < default 30 → avg suppressed.
      expect(suburban.avgLPer100Km, isNull);
    });

    test('30 identical samples reach the floor — avg = fuelRate/speed*100', () {
      final samples = List<TripSample>.generate(
        30,
        (_) => _sample(speed: 70.0, fuelRate: 8.0),
      );
      final bins = aggregateSpeedConsumption(samples);

      final suburban = _binFor(bins, SpeedBand.suburban);
      expect(suburban.sampleCount, 30);
      expect(suburban.timeShareSeconds, 30.0);
      // 8.0 / 70.0 * 100 ≈ 11.4286 — same for any number of identical
      // samples because Σ-fuel / Σ-speed cancels the count.
      expect(suburban.avgLPer100Km, isNotNull);
      expect(suburban.avgLPer100Km!, closeTo(11.4286, 0.001));
    });

    test('29 samples (one shy) keeps avg null', () {
      final samples = List<TripSample>.generate(
        29,
        (_) => _sample(speed: 70.0, fuelRate: 8.0),
      );
      final bins = aggregateSpeedConsumption(samples);

      final suburban = _binFor(bins, SpeedBand.suburban);
      expect(suburban.sampleCount, 29);
      expect(suburban.avgLPer100Km, isNull);
    });

    test('custom minSamplesPerBin pins the floor', () {
      // With minSamplesPerBin=1 a single sample's avg shows up.
      final bins = aggregateSpeedConsumption(
        [_sample(speed: 70.0, fuelRate: 8.0)],
        minSamplesPerBin: 1,
      );
      final suburban = _binFor(bins, SpeedBand.suburban);
      expect(suburban.avgLPer100Km, isNotNull);
      expect(suburban.avgLPer100Km!, closeTo(11.4286, 0.001));
    });
  });

  group('aggregateSpeedConsumption — idle/jam band carve-out', () {
    test('idleJam: time-share counted, avg always null', () {
      final samples = List<TripSample>.generate(
        100,
        (_) => _sample(speed: 5.0, fuelRate: 2.0),
      );
      final bins = aggregateSpeedConsumption(samples);

      final idle = _binFor(bins, SpeedBand.idleJam);
      expect(idle.sampleCount, 100);
      expect(idle.timeShareSeconds, 100.0);
      // Even with 100 samples (well over the 30 floor) the avg stays
      // null — the band-rule overrides the threshold-rule.
      expect(idle.avgLPer100Km, isNull);
    });

    test('idleJam samples do not pollute neighbouring band averages', () {
      // 30 samples at speed=70/fuel=8 PLUS 50 idle-jam samples.
      // Without the carve-out the suburban average would be dragged
      // toward the idle-jam ratio.
      final samples = <TripSample>[
        ...List<TripSample>.generate(
          30,
          (_) => _sample(speed: 70.0, fuelRate: 8.0),
        ),
        ...List<TripSample>.generate(
          50,
          (_) => _sample(speed: 5.0, fuelRate: 2.0),
        ),
      ];
      final bins = aggregateSpeedConsumption(samples);

      // Suburban computation is unchanged — idle/jam samples never
      // entered fuelSum / speedSum for any band.
      expect(
        _binFor(bins, SpeedBand.suburban).avgLPer100Km!,
        closeTo(11.4286, 0.001),
      );
      // Idle/jam timeshare is preserved.
      expect(_binFor(bins, SpeedBand.idleJam).sampleCount, 50);
    });
  });

  group('aggregateSpeedConsumption — multi-trip variant', () {
    test('flattens trips and matches concatenated single-trip input', () {
      final t1 = List<TripSample>.generate(
        20,
        (_) => _sample(speed: 70.0, fuelRate: 8.0),
      );
      final t2 = List<TripSample>.generate(
        20,
        (_) => _sample(speed: 70.0, fuelRate: 8.0),
      );

      final viaMulti = aggregateSpeedConsumptionMultiTrip([t1, t2]);
      final viaConcat = aggregateSpeedConsumption([...t1, ...t2]);

      // Bins are returned in band-declaration order so element-wise
      // comparison is valid across the two call shapes.
      for (var i = 0; i < SpeedBand.values.length; i++) {
        expect(viaMulti[i].band, viaConcat[i].band);
        expect(viaMulti[i].sampleCount, viaConcat[i].sampleCount);
        expect(viaMulti[i].timeShareSeconds, viaConcat[i].timeShareSeconds);
        expect(viaMulti[i].avgLPer100Km, viaConcat[i].avgLPer100Km);
      }
    });

    test('single-trip aggregator on flattened iterable matches', () {
      final t1 = [_sample(speed: 30.0, fuelRate: 4.0)];
      final t2 = [_sample(speed: 90.0, fuelRate: 6.0)];

      final flat = [...t1, ...t2];
      final viaSingle = aggregateSpeedConsumption(flat);
      final viaMulti = aggregateSpeedConsumptionMultiTrip([t1, t2]);

      expect(_binFor(viaSingle, SpeedBand.urban).sampleCount,
          _binFor(viaMulti, SpeedBand.urban).sampleCount);
      expect(_binFor(viaSingle, SpeedBand.rural).sampleCount,
          _binFor(viaMulti, SpeedBand.rural).sampleCount);
    });
  });

  group('aggregateSpeedConsumption — Σ/Σ vs mean-of-ratios divergence', () {
    test(
      'aggregate uses Σ-fuel / Σ-speed, not arithmetic mean of ratios',
      () {
        // Contrived case where the two formulas DO diverge:
        //   - 30 samples at speed=20 km/h, fuelRate=4.0 L/h
        //       → ratio = 4.0/20*100 = 20 L/100 km
        //   - 30 samples at speed=120 km/h, fuelRate=8.0 L/h
        //       → ratio = 8.0/120*100 ≈ 6.6667 L/100 km
        //
        // Mean of ratios: (20 + 6.6667) / 2 = 13.3333 L/100 km
        // Aggregate: (Σ fuel) / (Σ speed) * 100
        //          = (30*4.0 + 30*8.0) / (30*20 + 30*120) * 100
        //          = 360 / 4200 * 100
        //          = 8.5714 L/100 km
        //
        // The aggregate is the honest figure — every km is weighted by
        // the actual fuel burned over it. Asserting the aggregate
        // value (8.5714) catches a regression that switches the
        // implementation to mean-of-ratios.
        final samples = <TripSample>[
          ...List<TripSample>.generate(
            30,
            (_) => _sample(speed: 20.0, fuelRate: 4.0),
          ),
          ...List<TripSample>.generate(
            30,
            (_) => _sample(speed: 120.0, fuelRate: 8.0),
          ),
        ];

        final bins = aggregateSpeedConsumption(samples);

        // Urban band has 30 samples at 20 km/h.
        final urban = _binFor(bins, SpeedBand.urban);
        expect(urban.sampleCount, 30);
        // 4.0 / 20.0 * 100 = 20.0 — only one rate represented in this
        // bin so aggregate == per-sample ratio here.
        expect(urban.avgLPer100Km!, closeTo(20.0, 0.001));

        // Motorway band has 30 samples at 120 km/h.
        final motorway = _binFor(bins, SpeedBand.motorway);
        expect(motorway.sampleCount, 30);
        // 8.0 / 120.0 * 100 ≈ 6.6667 — same reasoning.
        expect(motorway.avgLPer100Km!, closeTo(6.6667, 0.001));

        // Now combine the two into a single "all samples" check by
        // dropping minSamplesPerBin=1 and putting them in the same
        // band. We use a custom band-collapse via two distinct speeds
        // that BOTH land in suburban (50–80 km/h).
        // Pick speed=60 (fuel=2) and speed=70 (fuel=10):
        //   ratios: 2/60*100=3.333, 10/70*100=14.286
        //   mean of ratios: 8.81
        //   aggregate: (30*2 + 30*10) / (30*60 + 30*70) * 100
        //            = 360 / 3900 * 100 = 9.2308
        final mixedSuburban = <TripSample>[
          ...List<TripSample>.generate(
            30,
            (_) => _sample(speed: 60.0, fuelRate: 2.0),
          ),
          ...List<TripSample>.generate(
            30,
            (_) => _sample(speed: 70.0, fuelRate: 10.0),
          ),
        ];
        final mixedBins = aggregateSpeedConsumption(mixedSuburban);
        final suburban = _binFor(mixedBins, SpeedBand.suburban);
        expect(suburban.sampleCount, 60);
        // Aggregate Σ/Σ: 360 / 3900 * 100 ≈ 9.2308
        // Mean-of-ratios would be ≈ 8.8095 — assertion bites if
        // anyone "fixes" the implementation to arithmetic mean.
        expect(suburban.avgLPer100Km!, closeTo(9.2308, 0.001));
      },
    );
  });
}

/// Build a [TripSample] with default safe values and the parameters
/// we care about overriding. The recorder's downstream metrics (rpm,
/// timestamp) don't affect the histogram — pinning them to zero keeps
/// the test fixtures readable.
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

/// Pick the bin for [band] from a histogram result. Bins are stored in
/// declaration order so this is just a lookup, but the helper makes
/// the assertions read top-down.
SpeedConsumptionBin _binFor(List<SpeedConsumptionBin> bins, SpeedBand band) =>
    bins.firstWhere((b) => b.band == band);
