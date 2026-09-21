// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/obd2/data/session/trip_run_state.dart';

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
  // Every distinct underlying open's settings, in order (#2766 — lets a test
  // assert the recorder's fine settings reach the shared upstream).
  final List<LocationSettings?> openedSettings = [];

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    openCount++;
    openedSettings.add(locationSettings);
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

/// #4353 — the deliverable of this slice: a fake platform that reproduces
/// `geolocator_android`'s `_positionStream` CACHE.
///
/// A fake that hands back a fresh stream on every `getPositionStream` call
/// passes against the bug and proves nothing. The real plugin does this:
///
/// ```dart
/// // geolocator_android-5.0.3/lib/src/geolocator_android.dart:169-171
/// if (_positionStream != null) { return _positionStream!; }
/// ...
/// // :207-212 — the ONLY place the cache is cleared
/// return incoming.asBroadcastStream(onCancel: (subscription) {
///   subscription.cancel();
///   _positionStream = null;
/// });
/// ```
///
/// So a re-open that OVERLAPS the old cancel is handed the previous
/// caller's stream at the previous caller's `locationSettings` — the new
/// settings are dropped on the floor, silently. That is the whole defect:
/// the recorder's fine, foreground-service-promoted profile never reaches
/// the platform and the trip keeps recording on the detector's coarse,
/// unprotected one. [cacheHits] counts exactly that event.
///
/// [cancelGate] models a platform that takes time to acknowledge the
/// teardown (the old stream keeps delivering until it does), and
/// [failNextOpen] a platform that refuses to start a replacement.
class _CachingGeolocator extends GeolocatorWrapper {
  /// Every upstream the platform really opened, in order.
  final List<_FakeUpstream> opened = [];

  /// Opens served from the cached `_positionStream` instead — i.e. every
  /// time the requested settings were silently discarded.
  int cacheHits = 0;

  /// The plugin's `_positionStream` field.
  _FakeUpstream? _cached;

  /// While non-null, every cancel blocks on it before it is acknowledged.
  Completer<void>? cancelGate;

  /// Makes the next open throw (a platform that refuses to start).
  Object? failNextOpen;

  int get openCount => opened.length;
  List<LocationSettings?> get openedSettings =>
      [for (final u in opened) u.settings];
  int get liveSubscriptions => opened.where((u) => u.listening).length;

  /// The settings the LIVE platform stream is actually running with.
  LocationSettings? get appliedSettings => _cached?.settings;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    final cached = _cached;
    if (cached != null) {
      cacheHits++;
      return cached.stream;
    }
    final fail = failNextOpen;
    if (fail != null) {
      failNextOpen = null;
      Error.throwWithStackTrace(fail, StackTrace.current);
    }
    final up = _FakeUpstream(this, locationSettings);
    opened.add(up);
    _cached = up;
    return up.stream;
  }

  void _clearCache(_FakeUpstream up) {
    if (identical(_cached, up)) _cached = null;
  }

  Future<void> dispose() async {
    for (final u in opened) {
      await u.close();
    }
  }
}

/// One platform stream the fake opened. The test can keep pushing into a
/// RETIRED one to prove the generation fence holds.
class _FakeUpstream {
  _FakeUpstream(this._owner, this.settings);

  final _CachingGeolocator _owner;
  final LocationSettings? settings;
  final StreamController<Position> _ctl =
      StreamController<Position>.broadcast();

  bool listening = false;
  bool cancelled = false;

  Stream<Position> get stream => _GatedStream(this);

  void emit(Position p) {
    if (!_ctl.isClosed) _ctl.add(p);
  }

  void emitError(Object e) {
    if (!_ctl.isClosed) _ctl.addError(e, StackTrace.empty);
  }

  Future<void> close() async {
    if (!_ctl.isClosed) await _ctl.close();
  }
}

class _GatedStream extends Stream<Position> {
  _GatedStream(this._up);

  final _FakeUpstream _up;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<Position> listen(
    void Function(Position)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _up.listening = true;
    return _GatedSubscription(
      _up,
      _up._ctl.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      ),
    );
  }
}

class _GatedSubscription implements StreamSubscription<Position> {
  _GatedSubscription(this._up, this._inner);

  final _FakeUpstream _up;
  final StreamSubscription<Position> _inner;

  @override
  Future<void> cancel() async {
    // The platform takes time to acknowledge the teardown; until it does,
    // the retired stream is still wired up and still delivering.
    final gate = _up._owner.cancelGate;
    if (gate != null) await gate.future;
    await _inner.cancel();
    _up.listening = false;
    _up.cancelled = true;
    // geolocator_android clears `_positionStream` ONLY here.
    _up._owner._clearCache(_up);
  }

  @override
  Future<E> asFuture<E>([E? value]) => _inner.asFuture<E>(value);

  @override
  bool get isPaused => _inner.isPaused;

  @override
  void onData(void Function(Position)? handleData) =>
      _inner.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();
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

  // #2766 — the recorder's fine, foreground-service-promoted settings must
  // WIN the cadence on the shared upstream regardless of subscription order.
  group('GeolocatorWrapper.sharedPositionStream recording cadence (#2766)', () {
    late _CountingGeolocator geo;
    setUp(() => geo = _CountingGeolocator());
    tearDown(() => geo.dispose());

    // The fine recording settings the recorder passes; identity-distinct from
    // the detector's coarse settings so the source can tell them apart.
    final fine = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 1),
      distanceFilter: 0,
    );
    const coarse = LocationSettings(accuracy: LocationAccuracy.high);

    test('recorder first → upstream opens with the fine recording settings',
        () async {
      final sub = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();

      expect(geo.openCount, 1);
      expect(geo.openedSettings.single, same(fine),
          reason: "recorder's fine settings open the upstream");

      await sub.cancel();
    });

    test(
        'detector first (coarse) THEN recorder joins → upstream RE-OPENS at '
        'the fine cadence, so the recording cadence wins', () async {
      // The detector opens the channel first with coarse settings.
      final subDetector = geo
          .sharedPositionStream(locationSettings: coarse)
          .listen((_) {});
      await _pump();
      expect(geo.openCount, 1);
      expect(geo.openedSettings.single, same(coarse));

      // The recorder joins a frame later, marked recording: the upstream must
      // re-open with the FINE settings so the trace stays ~1 s, not ~5 s.
      final got = <Position>[];
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen(got.add);
      await _pump();

      expect(geo.openCount, 2, reason: 'recorder forces a re-open');
      expect(geo.openedSettings.last, same(fine),
          reason: 'the re-opened upstream carries the fine recording settings');
      // Only the fine subscription is live now (the coarse one was cancelled).
      expect(geo.liveSubscriptions, 1);

      // Both consumers keep receiving fixes off the re-opened upstream.
      geo.emit(_pos(52.5, 13.4));
      await _pump();
      expect(got, hasLength(1), reason: 'recorder still receives fixes');

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test('a coarse late joiner does NOT downgrade an already-fine upstream',
        () async {
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();
      expect(geo.openCount, 1);

      // The detector joins later with coarse settings — it must NOT re-open
      // the upstream (the recorder's fine cadence stays authoritative).
      final subDetector = geo
          .sharedPositionStream(locationSettings: coarse)
          .listen((_) {});
      await _pump();

      expect(geo.openCount, 1, reason: 'no re-open for a coarse joiner');
      expect(geo.openedSettings.single, same(fine));

      await subRecorder.cancel();
      await subDetector.cancel();
    });
  });

  // #4353 — the promotion must be APPLIED, not merely requested. Every test
  // here runs against [_CachingGeolocator], which reproduces the plugin's
  // `_positionStream` cache; the pre-fix `_reopenUpstream` (open-new, then
  // `unawaited(old.safeCancel())`) fails the first four of them.
  group('shared upstream replacement (#4353)', () {
    late _CachingGeolocator geo;
    setUp(() => geo = _CachingGeolocator());
    tearDown(() => geo.dispose());

    final fine = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 1),
      distanceFilter: 0,
    );
    final finer = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: const Duration(milliseconds: 500),
      distanceFilter: 0,
    );
    const coarse = LocationSettings(accuracy: LocationAccuracy.high);

    test(
        'a foreground-only consumer opened the channel first: the recorder '
        'gets an ACTUAL settings upgrade, not the cached coarse stream',
        () async {
      final subDetector =
          geo.sharedPositionStream(locationSettings: coarse).listen((_) {});
      await _pump();
      expect(geo.appliedSettings, same(coarse));

      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();

      // Pre-fix this is the red line: the overlapping re-open was served
      // from the plugin cache, so `cacheHits` was 1, `openCount` stayed 1
      // and the platform kept running the detector's coarse settings.
      expect(geo.cacheHits, 0,
          reason: 'the re-open must happen AFTER the old cancel cleared the '
              "plugin's _positionStream cache");
      expect(geo.openCount, 2);
      expect(geo.appliedSettings, same(fine),
          reason: 'the platform stream actually runs the recording settings');
      expect(geo.liveSubscriptions, 1, reason: 'exactly one upstream');

      final d = geo.sharedPositionDiagnostics;
      expect(d.effective, same(fine));
      expect(d.requested, same(fine));
      expect(d.inFlight, isFalse);

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test(
        'concurrent promotions coalesce into ONE upstream at the LATEST '
        'aggregate requirement', () async {
      final subDetector =
          geo.sharedPositionStream(locationSettings: coarse).listen((_) {});
      await _pump();

      // Two recording consumers join in the SAME frame with different
      // requirements — the second must win, and there must be no
      // intermediate upstream at the first one's settings.
      final subA = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      final subB = geo
          .sharedPositionStream(locationSettings: finer, recording: true)
          .listen((_) {});
      await _pump();
      await _pump();

      expect(geo.openCount, 2,
          reason: 'coarse + one replacement; the promotions coalesced');
      expect(geo.appliedSettings, same(finer));
      expect(geo.liveSubscriptions, 1);
      expect(geo.sharedPositionDiagnostics.inFlight, isFalse);

      await subDetector.cancel();
      await subA.cancel();
      await subB.cancel();
    });

    test(
        'a slow cancel holds the replacement open: nothing is re-opened, and '
        'diagnostics report requested-but-not-applied', () async {
      final subDetector =
          geo.sharedPositionStream(locationSettings: coarse).listen((_) {});
      await _pump();

      final gate = Completer<void>();
      geo.cancelGate = gate;

      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();

      expect(geo.openCount, 1, reason: 'no re-open before the cancel lands');
      var d = geo.sharedPositionDiagnostics;
      expect(d.requested, same(fine));
      expect(d.effective, isNull,
          reason: 'mid-handover: the fine profile is NOT applied yet');
      expect(d.inFlight, isTrue);

      geo.cancelGate = null;
      gate.complete();
      await _pump();

      expect(geo.openCount, 2);
      d = geo.sharedPositionDiagnostics;
      expect(d.effective, same(fine));
      expect(d.inFlight, isFalse);

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test(
        'a failed replacement is explicit: the error reaches the consumer '
        'and the profile stays requested-but-NOT-applied', () async {
      // Both consumers share one bus, so both see the failure — nobody is
      // left believing a fine stream is running.
      final detectorErrors = <Object>[];
      final subDetector = geo
          .sharedPositionStream(locationSettings: coarse)
          .listen((_) {}, onError: detectorErrors.add);
      await _pump();

      geo.failNextOpen = StateError('platform refused to start');

      final errors = <Object>[];
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {}, onError: errors.add);
      await _pump();

      expect(errors, hasLength(1), reason: 'the failure is surfaced, not eaten');
      expect(errors.single, isA<StateError>());
      expect(detectorErrors, hasLength(1));
      expect(geo.openCount, 1, reason: 'only the original coarse open');
      expect(geo.liveSubscriptions, 0, reason: 'the old upstream WAS cancelled');
      final d = geo.sharedPositionDiagnostics;
      expect(d.requested, same(fine));
      expect(d.effective, isNull, reason: 'nothing is applied — say so');
      expect(d.inFlight, isFalse);

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test(
        'a late data / error / done from the REPLACED stream never reaches '
        'the session', () async {
      final subDetector =
          geo.sharedPositionStream(locationSettings: coarse).listen((_) {});
      await _pump();
      final stale = geo.opened.single;

      final gate = Completer<void>();
      geo.cancelGate = gate;

      final got = <Position>[];
      final errors = <Object>[];
      var done = false;
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen(got.add, onError: errors.add, onDone: () => done = true);
      await _pump();

      // The retired stream is still wired up while the platform takes its
      // time acknowledging the cancel. None of this may land.
      stale.emit(_pos(1, 1));
      stale.emitError(StateError('late error from a retired generation'));
      await stale.close();
      await _pump();

      expect(got, isEmpty, reason: 'a fix from a replaced generation is stale');
      expect(errors, isEmpty);
      expect(done, isFalse, reason: 'a retired stream may not close the bus');

      geo.cancelGate = null;
      gate.complete();
      await _pump();

      expect(geo.appliedSettings, same(fine));
      expect(geo.sharedPositionDiagnostics.effective, same(fine),
          reason: 'the late done must not have cleared the NEW generation');

      // And the new generation still delivers.
      geo.opened.last.emit(_pos(52.5, 13.4));
      await _pump();
      expect(got, hasLength(1));

      await subDetector.cancel();
      await subRecorder.cancel();
    });

    test(
        'stop during promotion: no upstream is re-opened, nothing leaks, and '
        "#4344's alive fence answers false", () async {
      final run = TripRunState()..begin();

      final subDetector =
          geo.sharedPositionStream(locationSettings: coarse).listen((_) {});
      await _pump();

      final gate = Completer<void>();
      geo.cancelGate = gate;

      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();
      expect(geo.sharedPositionDiagnostics.inFlight, isTrue);

      // The trip stops while the promotion is still in flight.
      final promotion = Future<void>(() async {
        geo.cancelGate = null;
        gate.complete();
        await _pump();
      });
      await subRecorder.cancel();
      await subDetector.cancel();
      run.end();

      expect(await run.alive(promotion), isFalse,
          reason: 'the continuation must create nothing more (#4344)');
      await _pump();

      expect(geo.openCount, 1, reason: 'a stopped trip re-opens nothing');
      expect(geo.liveSubscriptions, 0, reason: 'no leaked subscription');
      final d = geo.sharedPositionDiagnostics;
      expect(d.requested, isNull);
      expect(d.effective, isNull);
      expect(d.inFlight, isFalse);
    });

    test(
        'dropping a NON-recording subscriber never downgrades the profile',
        () async {
      final subRecorder = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();
      final subDetector =
          geo.sharedPositionStream(locationSettings: coarse).listen((_) {});
      await _pump();
      expect(geo.openCount, 1, reason: 'a coarse joiner never re-configures');

      // Navigating away from the radar must not touch the trip's cadence.
      await subDetector.cancel();
      await _pump();

      expect(geo.openCount, 1, reason: 'no re-open on a coarse leave');
      expect(geo.appliedSettings, same(fine));
      expect(geo.sharedPositionDiagnostics.effective, same(fine));

      await subRecorder.cancel();
    });

    test('a platform stream that ENDS clears the applied profile', () async {
      final sub = geo
          .sharedPositionStream(locationSettings: fine, recording: true)
          .listen((_) {});
      await _pump();
      expect(geo.sharedPositionDiagnostics.effective, same(fine));

      await geo.opened.single.close();
      await _pump();

      final d = geo.sharedPositionDiagnostics;
      expect(d.requested, same(fine),
          reason: 'the requirement stands — the platform dropped it');
      expect(d.effective, isNull,
          reason: 'nothing is applied any more; the journal must not claim '
              'the recording profile is live');

      await sub.cancel();
    });
  });
}
