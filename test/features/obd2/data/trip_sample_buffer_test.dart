// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/obd2/domain/trip_sample_buffer.dart';

/// #3741 (finding 3) — [TripSampleBuffer.capturedSamples] used to
/// allocate a full `List.unmodifiable` COPY on every access; during a
/// recording the WAL flush and the glide-coach hook read it constantly,
/// so a long trip paid an O(n) allocation per read. It now returns a
/// cached unmodifiable VIEW (invalidated on mutation), and the
/// glide-coach's ".last once per GPS fix" read has a dedicated O(1)
/// [TripSampleBuffer.latestSample]. [TripSampleBuffer.maxCapturedRpm]
/// tracks the running max so the flush no longer loops the buffer.
void main() {
  TripSample sample(int second, {double? rpm}) => TripSample(
        timestamp: DateTime.utc(2026, 7, 1, 8, 0, second),
        speedKmh: 50.0 + second,
        rpm: rpm,
        throttlePercent: 10.0 + second,
      );

  group('TripSampleBuffer zero-copy reads (#3741)', () {
    test('capturedSamples returns the SAME cached view until a mutation',
        () {
      final buffer = TripSampleBuffer()..debugCaptureSample(sample(0));
      final first = buffer.capturedSamples;
      final second = buffer.capturedSamples;
      expect(identical(first, second), isTrue,
          reason: 'repeated reads must not allocate per access');

      buffer.debugCaptureSample(sample(1));
      final third = buffer.capturedSamples;
      expect(identical(second, third), isFalse,
          reason: 'a mutation must invalidate the cached view');
      expect(third, hasLength(2));
    });

    test('the view is unmodifiable and stays LIVE across captures', () {
      final buffer = TripSampleBuffer()..debugCaptureSample(sample(0));
      final view = buffer.capturedSamples;
      expect(() => view.clear(), throwsUnsupportedError);

      // An UnmodifiableListView is a window onto the buffer — a caller
      // holding it across captures sees the new tail (documented; the
      // stop-time persistence paths make their own defensive copies).
      buffer.debugCaptureSample(sample(1));
      expect(view, hasLength(2));
    });

    test('latestSample is null when empty, then tracks the newest capture',
        () {
      final buffer = TripSampleBuffer();
      expect(buffer.latestSample, isNull);

      buffer.debugCaptureSample(sample(0));
      buffer.debugCaptureSample(sample(7));
      expect(buffer.latestSample?.throttlePercent, 17.0);
    });

    test('capturedGpsSampleDiagnostics view is cached + invalidated too',
        () {
      final buffer = TripSampleBuffer();
      final empty = buffer.capturedGpsSampleDiagnostics;
      expect(identical(empty, buffer.capturedGpsSampleDiagnostics), isTrue);

      buffer.recordGpsSampleDiagnostic(
        now: DateTime.utc(2026, 7, 1, 8),
        lifecycleState: 'resumed',
      );
      final after = buffer.capturedGpsSampleDiagnostics;
      expect(identical(empty, after), isFalse);
      expect(after, hasLength(1));
    });

    test('maxCapturedRpm tracks the running max incrementally '
        '(null rpm reads as 0, the #2692 C4-G rule)', () {
      final buffer = TripSampleBuffer();
      expect(buffer.maxCapturedRpm, 0.0);

      buffer.debugCaptureSample(sample(0, rpm: 2200));
      buffer.debugCaptureSample(sample(1)); // GPS-only tick, rpm null
      buffer.debugCaptureSample(sample(2, rpm: 4321));
      buffer.debugCaptureSample(sample(3, rpm: 1800));
      expect(buffer.maxCapturedRpm, 4321.0);
    });

    test('maybeCapture decimation still updates latestSample + maxRpm '
        'only for captured ticks', () {
      final buffer = TripSampleBuffer();
      buffer.maybeCapture(sample(0, rpm: 2000));
      // 400 ms later — dropped by the 950 ms decimation gate.
      buffer.maybeCapture(TripSample(
        timestamp: DateTime.utc(2026, 7, 1, 8, 0, 0, 400),
        speedKmh: 51,
        rpm: 9000,
      ));
      expect(buffer.capturedSamples, hasLength(1));
      expect(buffer.latestSample?.rpm, 2000);
      expect(buffer.maxCapturedRpm, 2000.0,
          reason: 'a decimated-away tick must not feed the running max — '
              'the WAL summary mirrors the persisted buffer');
    });
  });
}
