// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/data/live_activity_controller.dart';
import 'package:tankstellen/features/trips/domain/live_activity_content.dart';

/// Unit coverage for [LiveActivityController] — the Dart side of the
/// `tankstellen/live_activity` channel (#3170). The Live Activity render
/// itself is device-verified; these tests pin the channel contract:
/// method names, payload pass-through, the iOS-only guard, and the
/// never-throws degradation on platform errors (the fault-injection
/// sibling for the class's never-throw doccontract).

LiveActivityContent _content({bool paused = false}) => LiveActivityContent(
      mode: LiveActivityMode.recording,
      paused: paused,
      startedAtEpochMs: 1000000,
      bigFigure: '5.8',
      bigCaption: 'L/100 km',
      isEstimate: false,
      distanceText: null,
      pausedLabel: 'Paused',
      recordingLabel: 'Recording trip',
      pauseActionLabel: 'Pause',
      resumeActionLabel: 'Resume',
      stopActionLabel: 'Stop recording',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tankstellen/live_activity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('LiveActivityController on iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('isSupported is true', () {
      expect(LiveActivityController().isSupported, isTrue);
    });

    test('startActivity invokes start with the content payload and returns '
        'the native result', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      final controller = LiveActivityController();
      final ok = await controller
          .startActivity(_content());

      expect(ok, isTrue);
      expect(calls.single.method, 'start');
      expect(
        calls.single.arguments,
        containsPair('mode', 'recording'),
      );
    });

    test('startActivity returns false when the native side declines',
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      expect(
        await LiveActivityController().startActivity(_content()),
        isFalse,
      );
    });

    test('startActivity returns false on a platform error (fault injection)',
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'activitykit');
      });
      expect(
        await LiveActivityController().startActivity(_content()),
        isFalse,
      );
    });

    test('updateActivity invokes update and swallows platform errors',
        () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (calls.length > 1) throw PlatformException(code: 'gone');
        return null;
      });

      final controller = LiveActivityController();
      await controller.updateActivity(_content());
      // Second call hits the injected fault — must not throw.
      await controller.updateActivity(_content());

      expect(calls.map((c) => c.method), everyElement('update'));
      expect(calls.first.arguments, containsPair('bigFigure', '5.8'));
    });

    test('endActivity invokes end and swallows platform errors', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        throw PlatformException(code: 'gone');
      });

      await LiveActivityController().endActivity();
      expect(calls.single.method, 'end');
    });

    test('all methods survive a missing native handler '
        '(MissingPluginException fault)', () async {
      // No mock handler installed → MissingPluginException path.
      final controller = LiveActivityController();
      expect(await controller.startActivity(_content()), isFalse);
      await controller.updateActivity(_content());
      await controller.endActivity();
    });
  });

  group('LiveActivityController off iOS', () {
    // #3722 — Android is now a SUPPORTED platform (ongoing-tile twin);
    // fuchsia stands in for "no live surface exists here".
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia);

    test('isSupported is false and calls are inert no-ops', () async {
      var invoked = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return true;
      });

      final controller = LiveActivityController();
      expect(controller.isSupported, isFalse);
      expect(await controller.startActivity(_content()), isFalse);
      await controller.updateActivity(_content());
      await controller.endActivity();
      expect(invoked, isFalse,
          reason: 'no channel traffic on a platform without Live Activities');
    });
  });
}
