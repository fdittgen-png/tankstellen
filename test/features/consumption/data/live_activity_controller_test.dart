// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/live_activity_controller.dart';

/// Unit coverage for [LiveActivityController] — the Dart side of the
/// `tankstellen/live_activity` channel (#3170). The Live Activity render
/// itself is device-verified; these tests pin the channel contract:
/// method names, payload pass-through, the iOS-only guard, and the
/// never-throws degradation on platform errors (the fault-injection
/// sibling for the class's never-throw doccontract).
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
          .startActivity(<String, Object?>{'mode': 'recording', 'paused': false});

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
        await LiveActivityController().startActivity(const {}),
        isFalse,
      );
    });

    test('startActivity returns false on a platform error (fault injection)',
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'activitykit');
      });
      expect(
        await LiveActivityController().startActivity(const {}),
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
      await controller.updateActivity(<String, Object?>{'bigFigure': '5.8'});
      // Second call hits the injected fault — must not throw.
      await controller.updateActivity(<String, Object?>{'bigFigure': '6.0'});

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
      expect(await controller.startActivity(const {}), isFalse);
      await controller.updateActivity(const {});
      await controller.endActivity();
    });
  });

  group('LiveActivityController off iOS', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('isSupported is false and calls are inert no-ops', () async {
      var invoked = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return true;
      });

      final controller = LiveActivityController();
      expect(controller.isSupported, isFalse);
      expect(await controller.startActivity(const {}), isFalse);
      await controller.updateActivity(const {});
      await controller.endActivity();
      expect(invoked, isFalse,
          reason: 'no channel traffic on a platform without Live Activities');
    });
  });
}
