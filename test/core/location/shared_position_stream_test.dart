// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';

/// Unit guards for the #2646 shared, refcounted broadcast position source.
///
/// The defect: `GpsOnlyRecordingPipeline` and the live `ApproachDetector`
/// each opened their OWN `Geolocator.getPositionStream()` in the same frame.
/// That single platform EventChannel can only feed one listener, so the
/// recorder starved the detector — it never left `ApproachIdle`, the radar
/// candidate list stayed empty, and swipe was a no-op.
///
/// The fix routes every *trip* consumer through one underlying subscription,
/// multiplexed via a broadcast controller, so they all receive every fix.
/// These tests pin:
///   - two consumers on the shared source both receive the same Position
///     (the race regression guard);
///   - the underlying platform subscription opens on the first listener and
///     closes on the last (battery cost-bound preserved);
///   - the latest fix is replayed to a late joiner;
///   - the per-call `getPositionStream` (movement detection) is UNCHANGED —
///     each call still opens its own independent subscription.
Position _pos(double lat, double lng, {double speed = 10}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 6, 1, 9),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 0,
    );

/// Fake wrapper that counts how many distinct underlying [getPositionStream]
/// subscriptions are opened, and lets the test push fixes into the most
/// recently opened one. Each `getPositionStream` call returns an independent
/// single-subscription controller — exactly the single-channel model the
/// production EventChannel exposes (a second concurrent listener does NOT
/// share the first's fixes).
class _CountingGeolocator extends GeolocatorWrapper {
  int openCount = 0;
  int liveSubscriptions = 0;
  final List<StreamController<Position>> _controllers = [];

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    openCount++;
    late final StreamController<Position> ctl;
    ctl = StreamController<Position>(
      onListen: () => liveSubscriptions++,
      onCancel: () {
        liveSubscriptions--;
        _controllers.remove(ctl);
      },
    );
    _controllers.add(ctl);
    return ctl.stream;
  }

  /// Push a fix into every currently-open underlying controller.
  void emit(Position p) {
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) c.add(p);
    }
  }

  Future<void> dispose() async {
    for (final c in List.of(_controllers)) {
      if (!c.isClosed) await c.close();
    }
  }
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  group('GeolocatorWrapper.sharedPositionStream (#2646)', () {
    late _CountingGeolocator geo;

    setUp(() => geo = _CountingGeolocator());
    tearDown(() => geo.dispose());

    test(
        'two consumers both receive the SAME fix over ONE underlying '
        'subscription (the race regression guard)', () async {
      const settings = LocationSettings(accuracy: LocationAccuracy.high);

      final a = <Position>[];
      final b = <Position>[];
      // Model the production seam: the recorder subscribes, then the
      // detector subscribes a frame later — both off the shared source.
      final subA = geo.sharedPositionStream(locationSettings: settings).listen(
            a.add,
          );
      await _pump();
      final subB = geo.sharedPositionStream(locationSettings: settings).listen(
            b.add,
          );
      await _pump();

      // Exactly ONE underlying platform subscription backs both consumers.
      expect(geo.openCount, 1,
          reason: 'both trip consumers must multiplex onto ONE channel');
      expect(geo.liveSubscriptions, 1);

      geo.emit(_pos(52.5, 13.4));
      await _pump();

      // BOTH consumers see the fix. On the pre-#2646 two-raw-streams design
      // the second consumer would be starved here.
      expect(a, hasLength(1), reason: 'recorder receives the fix');
      expect(b, hasLength(1),
          reason: 'detector must receive the SAME fix, not be starved');
      expect(a.single.latitude, 52.5);
      expect(b.single.latitude, 52.5);

      await subA.cancel();
      await subB.cancel();
    });

    test('underlying subscription opens on first listener, closes on last',
        () async {
      final s = geo.sharedPositionStream();
      // Lazy: no platform subscription until someone listens.
      expect(geo.openCount, 0);
      expect(geo.liveSubscriptions, 0);

      final sub1 = s.listen((_) {});
      await _pump();
      expect(geo.openCount, 1, reason: 'first listener opens the channel');
      expect(geo.liveSubscriptions, 1);

      final sub2 = geo.sharedPositionStream().listen((_) {});
      await _pump();
      expect(geo.openCount, 1, reason: 'second listener reuses the channel');
      expect(geo.liveSubscriptions, 1);

      await sub1.cancel();
      await _pump();
      expect(geo.liveSubscriptions, 1,
          reason: 'one consumer left — channel stays open');

      await sub2.cancel();
      await _pump();
      expect(geo.liveSubscriptions, 0,
          reason: 'last listener gone → underlying subscription cancelled '
              '(battery cost-bound preserved between trips)');
    });

    test('a late joiner is replayed the most recent fix', () async {
      final first = <Position>[];
      final sub1 =
          geo.sharedPositionStream().listen(first.add);
      await _pump();

      geo.emit(_pos(48.1, 11.6, speed: 20));
      await _pump();
      expect(first, hasLength(1));

      // A consumer that joins AFTER the first fix must still receive it so
      // the detector leaves ApproachIdle immediately rather than waiting for
      // the next sample.
      final late = <Position>[];
      final sub2 = geo.sharedPositionStream().listen(late.add);
      await _pump();

      expect(late, hasLength(1),
          reason: 'late joiner must be seeded the latest fix');
      expect(late.single.latitude, 48.1);

      await sub1.cancel();
      await sub2.cancel();
    });

    test(
        'the channel re-opens for a new trip after the last consumer left '
        '(no stale closed bus)', () async {
      final sub1 = geo.sharedPositionStream().listen((_) {});
      await _pump();
      await sub1.cancel();
      await _pump();
      expect(geo.liveSubscriptions, 0);

      // A second trip later: a fresh consumer must re-open the underlying
      // subscription off the SAME multiplexer (the broadcast bus is reused).
      final got = <Position>[];
      final sub2 = geo.sharedPositionStream().listen(got.add);
      await _pump();
      expect(geo.openCount, 2, reason: 'a new trip re-opens the channel');
      geo.emit(_pos(50.9, 6.9));
      await _pump();
      expect(got, hasLength(1));

      await sub2.cancel();
    });

    test(
        'the per-call getPositionStream (movement detection) is UNCHANGED — '
        'each call opens its OWN independent subscription', () async {
      // Non-trip callers must keep the bare per-call behaviour: two listeners
      // = two underlying subscriptions, not a shared one.
      final sub1 = geo.getPositionStream().listen((_) {});
      final sub2 = geo.getPositionStream().listen((_) {});
      await _pump();

      expect(geo.openCount, 2,
          reason: 'per-call stream must NOT be multiplexed — movement '
              'detection keeps its own subscription');
      expect(geo.liveSubscriptions, 2);

      await sub1.cancel();
      await sub2.cancel();
    });
  });
}
