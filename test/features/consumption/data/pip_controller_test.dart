// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/pip_controller.dart';

/// Unit coverage for [PipController] — the Dart side of the
/// app-internal `tankstellen/pip` channel (#1884). The PiP mode
/// transition itself is device-verified; these tests pin the channel
/// contract: method names, arguments, the Android-only guard, and the
/// native → Dart mode stream.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tankstellen/pip');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('PipController on Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('isSupported is true', () {
      final pip = PipController();
      addTearDown(pip.dispose);
      expect(pip.isSupported, isTrue);
    });

    test('enterPip invokes the enterPip method and returns its result',
        () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      final pip = PipController();
      addTearDown(pip.dispose);

      expect(await pip.enterPip(), isTrue);
      expect(calls.single.method, 'enterPip');
    });

    test('enterPip returns false when the platform call fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'state');
      });

      final pip = PipController();
      addTearDown(pip.dispose);

      expect(await pip.enterPip(), isFalse);
    });

    test('bringToFront invokes the bringToFront method and returns its result',
        () async {
      // #2964 — tapping the floating PiP tile body restores the full app.
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      final pip = PipController();
      addTearDown(pip.dispose);

      expect(await pip.bringToFront(), isTrue);
      expect(calls.single.method, 'bringToFront');
    });

    test('bringToFront returns false when the platform call fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'noLaunchIntent');
      });

      final pip = PipController();
      addTearDown(pip.dispose);

      expect(await pip.bringToFront(), isFalse);
    });

    test('setAutoEnterEnabled forwards the flag to setAutoEnter', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

      final pip = PipController();
      addTearDown(pip.dispose);

      await pip.setAutoEnterEnabled(true);
      await pip.setAutoEnterEnabled(false);

      expect(calls.map((c) => c.method), everyElement('setAutoEnter'));
      expect(calls.map((c) => c.arguments), [true, false]);
    });

    test('a native onPipModeChanged call surfaces on pipModeChanges',
        () async {
      final pip = PipController();
      addTearDown(pip.dispose);

      final emitted = <bool>[];
      final sub = pip.pipModeChanges.listen(emitted.add);

      await _sendNativeCall(messenger, const MethodCall('onPipModeChanged', true));
      await _sendNativeCall(
          messenger, const MethodCall('onPipModeChanged', false));

      expect(emitted, [true, false]);
      await sub.cancel();
    });
  });

  group('PipController off Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('isSupported is false and calls are inert no-ops', () async {
      var invoked = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        invoked = true;
        return null;
      });

      final pip = PipController();
      addTearDown(pip.dispose);

      expect(pip.isSupported, isFalse);
      expect(await pip.enterPip(), isFalse);
      expect(await pip.bringToFront(), isFalse);
      await pip.setAutoEnterEnabled(true);
      expect(invoked, isFalse,
          reason: 'no platform channel traffic on a non-PiP platform');
    });
  });
}

/// Dispatch a native → Dart [MethodCall] to the `tankstellen/pip`
/// channel, exercising the handler [PipController] installs.
Future<void> _sendNativeCall(
  BinaryMessenger messenger,
  MethodCall call,
) async {
  // `handlePlatformMessage` is deprecated for production code, but the
  // deprecation notice itself points tests here — it is the sanctioned
  // way to drive a channel's incoming method-call handler from a test.
  // ignore: deprecated_member_use
  await messenger.handlePlatformMessage(
    'tankstellen/pip',
    const StandardMethodCodec().encodeMethodCall(call),
    (_) {},
  );
}
