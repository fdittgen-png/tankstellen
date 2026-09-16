// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/obd2_trip_features.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';

/// #4159 — the trip aggregate names the stored φ / baro values the fuel
/// math's clamps would have hidden, per signal, among the samples that
/// carried it.

TripSample _s(int sec, {double? lambda, double? baroKpa}) => TripSample(
      timestamp: DateTime.utc(2026, 1, 1, 0, 0, sec),
      speedKmh: 50,
      rpm: 1500,
      lambda: lambda,
      baroKpa: baroKpa,
    );

void main() {
  test('share per signal among the samples carrying it', () {
    final f = Obd2TripFeatures.fromSamples([
      _s(0, lambda: 1.0, baroKpa: 95),
      _s(1, lambda: 1.9, baroKpa: 95),
      _s(2, lambda: 0.3, baroKpa: 30),
      _s(3, lambda: 1.5),
      _s(4), // carries neither — not in either denominator
    ])!;
    expect(f.implausibleShare['lambda'], closeTo(2 / 4, 1e-12));
    expect(f.implausibleShare['baroKpa'], closeTo(1 / 3, 1e-12));
    expect(f.toJson()['implausibleShare'], {'lambda': 0.5, 'baroKpa': 0.333});
  });

  test('a signal the trip never carried has no key', () {
    final f = Obd2TripFeatures.fromSamples([_s(0, lambda: 1.0), _s(1)])!;
    expect(f.implausibleShare, {'lambda': 0.0});
    expect(f.toJson()['implausibleShare'], {'lambda': 0.0});
  });

  test('a trip without φ or baro exports an empty map', () {
    final f = Obd2TripFeatures.fromSamples([_s(0), _s(1)])!;
    expect(f.toJson()['implausibleShare'], isEmpty);
  });
}
