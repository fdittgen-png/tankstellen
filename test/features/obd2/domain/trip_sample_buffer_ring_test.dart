// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3878 — the capture buffer is a WAL-backed live ring: it releases only
// what is on disk, never below the live window, keeps whole-trip facts
// (count, first timestamp, max rpm) and hands the flush the unwritten
// tail by ABSOLUTE index.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/domain/trip_sample_buffer.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';

TripSample _s(int i) => TripSample(
      timestamp: DateTime(2026, 8, 29, 8).add(Duration(seconds: i)),
      speedKmh: 50,
      rpm: 1000.0 + i,
    );

void main() {
  test('releases only written samples older than the live window', () {
    final b = TripSampleBuffer();
    const total = TripSampleBuffer.kLiveWindow + 300;
    for (var i = 0; i < total; i++) {
      b.debugCaptureSample(_s(i));
    }
    expect(b.capturedTotal, total);
    expect(b.capturedSamples.length, total, reason: 'nothing written yet');

    // The flush wrote the first 100: only those may go, and they do not
    // matter for the window yet (window holds the last 900).
    b.releaseWritten(100);
    expect(b.capturedSamples.length, total - 100);
    expect(b.capturedTotal, total);

    // Everything written: the ring shrinks to the live window exactly.
    b.releaseWritten(total);
    expect(b.capturedSamples.length, TripSampleBuffer.kLiveWindow);
    expect(b.capturedSamples.first.rpm, 1000.0 + 300,
        reason: 'the oldest kept sample is total - window');
    expect(b.latestSample!.rpm, 1000.0 + total - 1);
    expect(b.maxCapturedRpm, 1000.0 + total - 1,
        reason: 'whole-trip facts survive the release');
    expect(b.firstCapturedAt, _s(0).timestamp);
  });

  test('capturedSince hands the unwritten tail by absolute index', () {
    final b = TripSampleBuffer();
    for (var i = 0; i < 1200; i++) {
      b.debugCaptureSample(_s(i));
    }
    b.releaseWritten(1000);
    expect(b.capturedSince(1000).length, 200);
    expect(b.capturedSince(1000).first.rpm, 1000.0 + 1000);
    expect(b.capturedSince(1200), isEmpty);
    // Asking for an index already released is clamped to what is left.
    expect(b.capturedSince(0).length, 1200 - (1200 - 900));
  });

  test('a broken WAL (never released) keeps everything, as before', () {
    final b = TripSampleBuffer();
    for (var i = 0; i < 2000; i++) {
      b.debugCaptureSample(_s(i));
    }
    expect(b.capturedSamples.length, 2000);
  });
}
