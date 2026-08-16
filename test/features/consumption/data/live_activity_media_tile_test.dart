// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_tap_dispatcher.dart';
import 'package:tankstellen/features/consumption/data/android_live_activity_notifier.dart';
import 'package:tankstellen/features/consumption/data/live_activity_controller.dart';
import 'package:tankstellen/features/consumption/domain/live_activity_content.dart';

/// #3729 — Android media-pill path: the controller talks to the native
/// `tankstellen/live_activity` channel first (MediaSession tile → the
/// lock-screen media pill), degrades to the #3722 notification fallback
/// on any channel failure, and routes the native `tripAction` callback
/// through the same NotificationTapDispatcher round-trip as the
/// notification-action tile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tankstellen/live_activity');

  LiveActivityContent content({bool paused = false}) => LiveActivityContent(
        mode: LiveActivityMode.recording,
        paused: paused,
        startedAtEpochMs: 1000,
        bigFigure: '5.8',
        bigCaption: 'L/100 km',
        isEstimate: false,
        distanceText: '12.3 km',
        pausedLabel: 'Paused',
        recordingLabel: 'Recording trip',
        pauseActionLabel: 'Pause',
        resumeActionLabel: 'Resume',
        stopActionLabel: 'Stop recording',
      );

  late List<MethodCall> nativeCalls;
  late _RecordingNotifier fallback;
  late LiveActivityController controller;

  void mockNative({Object? Function(MethodCall call)? onCall}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call);
      return onCall == null ? true : onCall(call);
    });
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    nativeCalls = <MethodCall>[];
    fallback = _RecordingNotifier();
    controller = LiveActivityController(
      channel: channel,
      androidNotifier: fallback,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('start goes channel-first with the rendered payload; the fallback '
      'notifier stays untouched', () async {
    mockNative();
    expect(await controller.startActivity(content()), isTrue);

    expect(fallback.calls, isEmpty,
        reason: 'a healthy media channel must fully replace the '
            'notification tile — two tiles would be redundant');
    expect(nativeCalls, hasLength(1));
    expect(nativeCalls.single.method, 'start');
    final args = Map<String, Object?>.from(nativeCalls.single.arguments as Map);
    expect(args['title'], 'Recording trip');
    expect(args['body'], '5.8 L/100 km · 12.3 km');
    expect(args['paused'], isFalse);
    expect(args['startedAtEpochMs'], 1000);
    expect(args['pauseLabel'], 'Pause');
    expect(args['resumeLabel'], 'Resume');
    expect(args['stopLabel'], 'Stop recording');
  });

  test('paused update carries the paused title and flag', () async {
    mockNative();
    await controller.updateActivity(content(paused: true));
    final args = Map<String, Object?>.from(nativeCalls.single.arguments as Map);
    expect(args['title'], 'Paused');
    expect(args['paused'], isTrue);
  });

  test('a channel error degrades to the notification fallback — the '
      'recording never loses its tile', () async {
    mockNative(onCall: (_) => throw PlatformException(code: 'boom'));
    expect(await controller.startActivity(content()), isTrue);
    expect(fallback.calls, ['show']);
  });

  test('a false from native (e.g. notifications disabled) also falls '
      'back', () async {
    mockNative(onCall: (_) => false);
    await controller.startActivity(content());
    expect(fallback.calls, ['show']);
  });

  test('end tears down BOTH surfaces: channel end + fallback end', () async {
    mockNative();
    await controller.startActivity(content());
    await controller.endActivity();
    expect(nativeCalls.map((c) => c.method).toList(), ['start', 'end']);
    expect(fallback.calls, ['end'],
        reason: 'a fallback tile from an earlier channel hiccup must not '
            'strand on the lock screen after stop');
  });

  test('native tripAction round-trips into the tap dispatcher as a '
      'trip_action payload', () async {
    mockNative();
    await controller.startActivity(content()); // arms the handler

    final payloads = <String?>[];
    final sub = NotificationTapDispatcher.instance.stream.listen(payloads.add);
    addTearDown(sub.cancel);

    const codec = StandardMethodCodec();
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'tankstellen/live_activity',
      codec.encodeMethodCall(const MethodCall('tripAction', 'trip_pause')),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);

    expect(payloads, ['trip_action:trip_pause'],
        reason: 'the media-pill Pause must reach the SAME listener the '
            'notification-action tile uses');
  });
}

class _RecordingNotifier implements AndroidLiveActivityNotifier {
  final List<String> calls = <String>[];

  @override
  Future<bool> show(LiveActivityContent content) async {
    calls.add('show');
    return true;
  }

  @override
  Future<void> end() async {
    calls.add('end');
  }

  @override
  void disposeHeartbeat() {
    calls.add('disposeHeartbeat');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
