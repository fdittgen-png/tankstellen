// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3597 — a crash-recovered OBD2 trip used to save the WAL skeleton
// summary verbatim (distance + maxRpm only), so a fully-measured 92 km
// field drive surfaced with avgLPer100Km null. The rebuild replays the
// persisted samples through the canonical TripRecorder and merges the
// skeleton's trusted gap-capped distance/provenance (#3251) back in.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/services/recovered_summary_rebuild.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

void main() {
  final t0 = DateTime(2026, 7, 24, 17);

  /// A 1 Hz OBD2 sample stream shaped like the field trip: constant
  /// 60 km/h, 2600 rpm bursts above the high-RPM threshold at the tail,
  /// and a fuel rate carried on every 6th sample (~0.17 coverage — the
  /// live 6 s fuel cadence).
  List<TripSample> samples(int count, {int gapAfter = -1, int gapSec = 0}) {
    final out = <TripSample>[];
    var t = t0;
    for (var i = 0; i < count; i++) {
      if (i == gapAfter) t = t.add(Duration(seconds: gapSec));
      out.add(TripSample(
        timestamp: t,
        speedKmh: 60,
        rpm: i > count * 0.8 ? 3800 : 2600,
        fuelRateLPerHour: i % 6 == 0 ? 6.0 : null,
        coolantTempC: i < count ~/ 2 ? 55 : 88,
      ));
      t = t.add(const Duration(seconds: 1));
    }
    return out;
  }

  TripSummary skeleton({double distanceKm = 10.0}) => TripSummary(
        distanceKm: distanceKm,
        maxRpm: 3800,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: t0,
        distanceSource: 'gps',
      );

  test('the rebuilt summary regains fuel, avg, high-RPM time and the '
      'cold-start flag the skeleton lost', () {
    final rebuilt = rebuildRecoveredSummary(
      skeleton: skeleton(),
      samples: samples(600), // 10 min at 60 km/h ≈ 10 km
    );

    // 6.0 L/h over ~599 s ≈ 1.0 L.
    expect(rebuilt.fuelLitersConsumed, isNotNull);
    expect(rebuilt.fuelLitersConsumed!, closeTo(1.0, 0.05));
    // Recomputed against the skeleton's trusted 10 km, not re-derived.
    expect(rebuilt.avgLPer100Km, isNotNull);
    expect(rebuilt.avgLPer100Km!, closeTo(10.0, 0.6));
    expect(rebuilt.highRpmSeconds, greaterThan(60));
    expect(rebuilt.coldStartSurcharge, isTrue,
        reason: 'coolant crossed 70°C in the second half — warmedLate');
    expect(rebuilt.distanceKm, 10.0, reason: 'skeleton distance is kept');
    expect(rebuilt.distanceSource, 'gps');
    expect(rebuilt.startedAt, t0);
  });

  test('a 20-minute dropout hole neither rides the fuel rate nor '
      'fabricates litres (the #1927 gap cap)', () {
    final withHole = rebuildRecoveredSummary(
      skeleton: skeleton(),
      samples: samples(600, gapAfter: 300, gapSec: 1200),
    );
    final without = rebuildRecoveredSummary(
      skeleton: skeleton(),
      samples: samples(600),
    );
    // The hole interval must contribute ~nothing: 6 L/h over 20 min
    // would be 2 extra litres.
    expect(withHole.fuelLitersConsumed!,
        closeTo(without.fuelLitersConsumed!, 0.05));
  });

  test('empty samples return the skeleton untouched', () {
    final sk = skeleton();
    expect(identical(rebuildRecoveredSummary(skeleton: sk, samples: const []), sk),
        isTrue);
  });

  test('harsh scoring stays suppressed on gps-sourced replay (#2895)', () {
    // A hard speed ramp that WOULD register on direct speed.
    final ramp = <TripSample>[
      for (var i = 0; i < 30; i++)
        TripSample(
          timestamp: t0.add(Duration(milliseconds: 500 * i)),
          speedKmh: 20.0 + i * 3.0,
          rpm: 3000,
        ),
    ];
    final rebuilt =
        rebuildRecoveredSummary(skeleton: skeleton(), samples: ramp);
    expect(rebuilt.harshAccelerations, 0,
        reason: 'gps provenance suppresses derivative harsh scoring');
  });
}
