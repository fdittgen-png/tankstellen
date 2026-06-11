// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/live_activity_controller.dart';
import 'package:tankstellen/features/consumption/data/live_activity_coordinator.dart';
import 'package:tankstellen/features/consumption/domain/live_activity_content.dart';

/// Decision-table coverage for [LiveActivityCoordinator] (#3170):
/// start / update / end transitions, the ActivityKit cadence throttle
/// (routine vs transition gaps), the failed-start veto, and the
/// fault-injection sibling for the `apply` never-throws doccontract.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeLiveActivityController controller;
  late DateTime now;
  late LiveActivityCoordinator coordinator;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    controller = _FakeLiveActivityController();
    now = DateTime(2026, 6, 10, 12);
    coordinator =
        LiveActivityCoordinator(controller: controller, clock: () => now);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  LiveActivityContent content({
    LiveActivityMode mode = LiveActivityMode.recording,
    bool paused = false,
    String bigFigure = '5.8',
    String? distanceText,
    String? stationName,
    String? priceText,
  }) =>
      LiveActivityContent(
        mode: mode,
        paused: paused,
        startedAtEpochMs: 1000000,
        bigFigure: bigFigure,
        bigCaption: 'L/100 km',
        isEstimate: false,
        distanceText: distanceText,
        pausedLabel: 'Paused',
        stationName: stationName,
        priceText: priceText,
      );

  group('lifecycle', () {
    test('null content while idle does nothing', () async {
      await coordinator.apply(null);
      expect(controller.calls, isEmpty);
    });

    test('first content starts the activity once; identical content is '
        'never re-sent', () async {
      final c = content();
      await coordinator.apply(c);
      now = now.add(const Duration(minutes: 5));
      await coordinator.apply(c);
      await coordinator.apply(c);

      expect(controller.calls, ['start']);
      expect(coordinator.isActive, isTrue);
    });

    test('null content after a start ends the activity (once)', () async {
      await coordinator.apply(content());
      await coordinator.apply(null);
      await coordinator.apply(null);

      expect(controller.calls, ['start', 'end']);
      expect(coordinator.isActive, isFalse);
    });

    test('a new trip after an end starts a fresh activity', () async {
      await coordinator.apply(content());
      await coordinator.apply(null);
      await coordinator.apply(content(bigFigure: '7.0'));

      expect(controller.calls, ['start', 'end', 'start']);
    });
  });

  group('cadence throttle', () {
    test('routine drift (distance/figure) below the 30 s gap is skipped',
        () async {
      await coordinator.apply(content(distanceText: '1.0 km'));
      now = now.add(const Duration(seconds: 29));
      await coordinator.apply(content(distanceText: '1.2 km'));

      expect(controller.calls, ['start']);
    });

    test('routine drift at/after the 30 s gap is sent', () async {
      await coordinator.apply(content(distanceText: '1.0 km'));
      now = now.add(LiveActivityCoordinator.minRoutineGap);
      await coordinator.apply(content(distanceText: '1.2 km'));

      expect(controller.calls, ['start', 'update']);
      expect(
        controller.lastUpdatePayload,
        containsPair('distanceText', '1.2 km'),
      );
    });

    test('the throttle window restarts from the last SENT update', () async {
      await coordinator.apply(content(distanceText: '1.0 km'));
      now = now.add(LiveActivityCoordinator.minRoutineGap);
      await coordinator.apply(content(distanceText: '1.2 km'));
      now = now.add(const Duration(seconds: 10));
      await coordinator.apply(content(distanceText: '1.4 km'));

      expect(controller.calls, ['start', 'update']);
    });

    test('a transition (pause flip) bypasses the routine gap but honours '
        'the 2 s floor', () async {
      await coordinator.apply(content());
      now = now.add(const Duration(seconds: 1));
      await coordinator.apply(content(paused: true));
      expect(controller.calls, ['start'],
          reason: 'sub-2 s transition is debounced — the next emit retries');

      now = now.add(const Duration(seconds: 1));
      await coordinator.apply(content(paused: true));
      expect(controller.calls, ['start', 'update']);
    });

    test('a mode flip (radar lead) is a transition', () async {
      await coordinator.apply(content());
      now = now.add(const Duration(seconds: 3));
      await coordinator.apply(content(
        mode: LiveActivityMode.approach,
        stationName: 'ARAL',
        priceText: '1.78 €',
      ));

      expect(controller.calls, ['start', 'update']);
      expect(controller.lastUpdatePayload, containsPair('mode', 'approach'));
    });

    test('a station change within approach mode is a transition', () async {
      await coordinator.apply(content(
        mode: LiveActivityMode.approach,
        stationName: 'ARAL',
        priceText: '1.78 €',
      ));
      now = now.add(const Duration(seconds: 3));
      await coordinator.apply(content(
        mode: LiveActivityMode.approach,
        stationName: 'Shell',
        priceText: '1.75 €',
      ));

      expect(controller.calls, ['start', 'update']);
    });
  });

  group('failed-start veto', () {
    test('a declined start silences the coordinator for the rest of the '
        'trip; the next trip retries', () async {
      controller.startResult = false;

      await coordinator.apply(content());
      now = now.add(const Duration(minutes: 5));
      await coordinator.apply(content(bigFigure: '7.0'));
      expect(controller.calls, ['start'],
          reason: 'no 4×/s retry spam against a definitive OS "no"');
      expect(coordinator.isActive, isFalse);

      // Trip ends (nothing to end natively), next trip tries again.
      await coordinator.apply(null);
      controller.startResult = true;
      await coordinator.apply(content());
      expect(controller.calls, ['start', 'start']);
    });
  });

  group('never-throws (fault injection)', () {
    test('a throwing start is swallowed — apply completes normally',
        () async {
      controller.throwOn = 'start';
      await expectLater(coordinator.apply(content()), completes);
      expect(coordinator.isActive, isFalse);
    });

    test('a throwing update is swallowed — apply completes normally',
        () async {
      await coordinator.apply(content());
      controller.throwOn = 'update';
      now = now.add(const Duration(minutes: 1));
      await expectLater(
        coordinator.apply(content(bigFigure: '7.0')),
        completes,
      );
    });

    test('a throwing end is swallowed — apply completes normally', () async {
      await coordinator.apply(content());
      controller.throwOn = 'end';
      await expectLater(coordinator.apply(null), completes);
      expect(coordinator.isActive, isFalse);
    });
  });

  group('off-iOS', () {
    test('isSupported false → apply is a pure no-op', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = LiveActivityCoordinator(
        controller: _FakeLiveActivityController(supported: false),
        clock: () => now,
      );
      await android.apply(content());
      await android.apply(null);
      expect(android.isActive, isFalse);
    });
  });
}

/// Records the call sequence; configurable result + per-method fault
/// injection so the coordinator's never-throws contract has a real
/// throwing seam to be tested against.
class _FakeLiveActivityController extends LiveActivityController {
  _FakeLiveActivityController({this.supported = true});

  final bool supported;
  final List<String> calls = [];
  Map<String, Object?>? lastUpdatePayload;
  bool startResult = true;
  String? throwOn;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> startActivity(Map<String, Object?> content) async {
    if (throwOn == 'start') throw StateError('injected start fault');
    calls.add('start');
    return startResult;
  }

  @override
  Future<void> updateActivity(Map<String, Object?> content) async {
    if (throwOn == 'update') throw StateError('injected update fault');
    calls.add('update');
    lastUpdatePayload = content;
  }

  @override
  Future<void> endActivity() async {
    if (throwOn == 'end') throw StateError('injected end fault');
    calls.add('end');
  }
}
