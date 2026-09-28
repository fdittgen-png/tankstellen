// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/location/foreground_fix_tracker.dart';
import 'package:tankstellen/core/location/position_fix_policy.dart';
import 'package:tankstellen/core/time/app_clock.dart';

/// #4432 — the route map's device dot is only as honest as the fix
/// behind it. These pin the tracker's contract: a sample is judged by
/// its OWN timestamp (so the shared stream's replay of an old fix never
/// passes as current), an accepted fix expires with nothing newer, and
/// stop/dispose really release the subscription.
Position _fix(double lat, double lng, DateTime at, {double accuracy = 12}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: at,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

class _StepClock implements AppClock {
  _StepClock(this.instant);
  DateTime instant;
  @override
  DateTime now() => instant;
}

void main() {
  final t0 = DateTime(2026, 3, 11, 14, 30);
  const belley = LatLng(45.7594, 5.6842);

  late _StepClock clock;
  // Cancelled through the tracker — that is what these tests assert.
  // ignore: close_sinks
  late StreamController<Position> source;
  late int opens;
  late int cancels;
  late ForegroundFixTracker tracker;

  setUp(() {
    clock = _StepClock(t0);
    opens = 0;
    cancels = 0;
    tracker = ForegroundFixTracker(
      // A fresh single-subscription source per open, like the platform.
      open: () {
        opens++;
        // The tracker owns the subscription; cancelling it is the test.
        // ignore: close_sinks
        source = StreamController<Position>(onCancel: () => cancels++);
        return source.stream;
      },
      clock: clock,
    );
  });

  test('a fresh sample becomes the fix, with its accuracy', () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(belley.latitude, belley.longitude, t0));
      async.flushMicrotasks();

      expect(tracker.fix.value?.position, belley);
      expect(tracker.fix.value?.accuracyMeters, 12);
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });

  test('a replayed / cached sample older than the bound is never current',
      () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(belley.latitude, belley.longitude,
          t0.subtract(kRouteOriginMaxFixAge + const Duration(seconds: 1))));
      async.flushMicrotasks();

      expect(tracker.fix.value, isNull);
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });

  test('a too-coarse sample is not shown as a position', () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(belley.latitude, belley.longitude, t0,
          accuracy: kRouteOriginMaxAccuracyMeters + 1));
      async.flushMicrotasks();

      expect(tracker.fix.value, isNull);
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });

  test('an out-of-order older sample does not replace a newer one', () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(45.80, 5.70, t0));
      source.add(_fix(45.70, 5.60, t0.subtract(const Duration(seconds: 20))));
      async.flushMicrotasks();

      expect(tracker.fix.value?.position, const LatLng(45.80, 5.70));
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });

  test('an accepted fix expires once it ages past the bound, and a newer '
      'one restores it', () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(belley.latitude, belley.longitude, t0));
      async.flushMicrotasks();
      expect(tracker.fix.value, isNotNull);

      // Still current right at the bound.
      clock.instant = t0.add(kRouteOriginMaxFixAge);
      async.elapse(kRouteOriginMaxFixAge);
      expect(tracker.fix.value, isNotNull);

      // One second later, with nothing newer: gone.
      clock.instant = t0.add(kRouteOriginMaxFixAge + const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 1));
      expect(tracker.fix.value, isNull);

      source.add(_fix(45.80, 5.70, clock.instant));
      async.flushMicrotasks();
      expect(tracker.fix.value?.position, const LatLng(45.80, 5.70));
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });

  test('stop releases the subscription; start re-opens it', () {
    fakeAsync((async) {
      tracker.start();
      expect(tracker.isListening, isTrue);
      expect(opens, 1);

      unawaited(tracker.stop());
      async.flushMicrotasks();
      expect(tracker.isListening, isFalse);
      expect(cancels, 1);

      tracker.start();
      expect(opens, 2);
      expect(tracker.isListening, isTrue);
      unawaited(tracker.dispose());
      async.flushMicrotasks();
      expect(cancels, 2);
    });
  });

  test('revalidate after a long pause drops a fix that aged out', () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(belley.latitude, belley.longitude, t0));
      async.flushMicrotasks();
      unawaited(tracker.stop());
      async.flushMicrotasks();

      // The app comes back ten minutes later; the timer may not have run.
      clock.instant = t0.add(const Duration(minutes: 10));
      tracker.revalidate();

      expect(tracker.fix.value, isNull);
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });

  test('a stream error is logged, not fatal, and the fix survives', () {
    fakeAsync((async) {
      tracker.start();
      source.add(_fix(belley.latitude, belley.longitude, t0));
      source.addError(StateError('platform hiccup'));
      async.flushMicrotasks();

      expect(tracker.fix.value?.position, belley);
      expect(tracker.isListening, isTrue);
      unawaited(tracker.dispose());
      async.flushMicrotasks();
    });
  });
}
