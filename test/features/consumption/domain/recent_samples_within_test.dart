// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_coaching.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

TripSample _sampleAt(DateTime t) =>
    TripSample(timestamp: t, speedKmh: 50, rpm: 1500);

void main() {
  final base = DateTime(2026, 5, 28, 12, 0, 0);

  group('recentSamplesWithin (#2174)', () {
    test('matches a full .where scan for an in-order stream', () {
      // 1000 samples, 1 Hz.
      final samples = [
        for (var i = 0; i < 1000; i++)
          _sampleAt(base.add(Duration(seconds: i))),
      ];
      final reference = samples.last.timestamp;
      const window = Duration(seconds: 5);

      final got = recentSamplesWithin(samples, window, reference);
      final naive = samples
          .where((s) => s.timestamp.isAfter(reference.subtract(window)))
          .toList();

      expect(got, equals(naive));
      // 5 s window at 1 Hz → the 5 samples strictly after cutoff.
      expect(got.length, 5);
    });

    test('only scans the bounded tail (per-emit cost is O(window))', () {
      // 10 samples over 10 s; cap the scan to the last 3.
      final samples = [
        for (var i = 0; i < 10; i++)
          _sampleAt(base.add(Duration(seconds: i))),
      ];
      final got = recentSamplesWithin(
        samples,
        const Duration(seconds: 30), // would include all 10 by time
        samples.last.timestamp,
        maxScan: 3,
      );
      // Bounded to the last 3 samples even though all 10 are within 30 s.
      expect(got.length, 3);
      expect(got, equals(samples.sublist(7)));
    });

    test('tolerates a mildly out-of-order fix within the scanned tail', () {
      final samples = [
        _sampleAt(base),
        _sampleAt(base.add(const Duration(seconds: 1))),
        _sampleAt(base.add(const Duration(seconds: 3))),
        // Out of order: arrived after the 3 s fix but stamped 2 s.
        _sampleAt(base.add(const Duration(seconds: 2))),
        _sampleAt(base.add(const Duration(seconds: 4))),
      ];
      final got = recentSamplesWithin(
        samples,
        const Duration(seconds: 5),
        base.add(const Duration(seconds: 4)),
      );
      // The reordered 2 s sample is still in the tail and within window.
      expect(got.length, 5);
    });

    test('returns empty when nothing is within the window', () {
      final samples = [
        _sampleAt(base),
        _sampleAt(base.add(const Duration(seconds: 1))),
      ];
      final got = recentSamplesWithin(
        samples,
        const Duration(seconds: 5),
        base.add(const Duration(seconds: 100)),
      );
      expect(got, isEmpty);
    });

    test('handles a buffer shorter than maxScan', () {
      final samples = [_sampleAt(base), _sampleAt(base.add(const Duration(seconds: 1)))];
      final got = recentSamplesWithin(
        samples,
        const Duration(seconds: 5),
        samples.last.timestamp,
        maxScan: 600,
      );
      expect(got.length, 2);
    });
  });
}
