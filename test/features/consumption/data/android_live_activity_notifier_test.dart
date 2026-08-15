// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/android_live_activity_notifier.dart';
import 'package:tankstellen/features/consumption/data/live_activity_controller.dart';
import 'package:tankstellen/features/consumption/domain/live_activity_content.dart';

/// #3722 — the Android ongoing-tile twin of the iOS Live Activity.
LiveActivityContent _content({
  LiveActivityMode mode = LiveActivityMode.recording,
  bool paused = false,
  String? distanceText = '12.3 km',
  String? stationName,
  String? priceText,
  String? fuelLabel,
  String? stationDistanceText,
}) =>
    LiveActivityContent(
      mode: mode,
      paused: paused,
      startedAtEpochMs: 1723700000000,
      bigFigure: '5.8',
      bigCaption: 'L/100 km',
      isEstimate: false,
      distanceText: distanceText,
      pausedLabel: 'Trip paused',
      recordingLabel: 'Recording trip',
      stationName: stationName,
      priceText: priceText,
      fuelLabel: fuelLabel,
      stationDistanceText: stationDistanceText,
    );

void main() {
  group('buildAndroidLiveActivityRender (#3722)', () {
    test('recording mode: localized title, consumption hero + distance, '
        'ticking chronometer', () {
      final r = buildAndroidLiveActivityRender(_content());
      expect(r.title, 'Recording trip');
      expect(r.body, '5.8 L/100 km · 12.3 km');
      expect(r.chronometerTicking, isTrue);
    });

    test('paused: the localized paused label replaces the title and the '
        'chronometer freezes', () {
      final r = buildAndroidLiveActivityRender(_content(paused: true));
      expect(r.title, 'Trip paused');
      expect(r.chronometerTicking, isFalse);
    });

    test('approach mode leads with station + price + distance, mirroring '
        'the PiP precedence', () {
      final r = buildAndroidLiveActivityRender(_content(
        mode: LiveActivityMode.approach,
        stationName: 'Total Sète',
        priceText: '0,899 €',
        fuelLabel: 'E85',
        stationDistanceText: '2,5 km',
      ));
      expect(r.title, 'Recording trip');
      expect(r.body, 'Total Sète · 0,899 € E85 · 2,5 km');
    });

    test('warm-up recording with no distance keeps a clean single-part '
        'body', () {
      final r = buildAndroidLiveActivityRender(_content(distanceText: null));
      expect(r.body, '5.8 L/100 km');
    });
  });

  group('LiveActivityController Android dispatch (#3722)', () {
    test('start/update/end route to the notifier on Android and report '
        'its result', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final notifier = _RecordingNotifier();
      final controller = LiveActivityController(androidNotifier: notifier);

      expect(controller.isSupported, isTrue);
      expect(await controller.startActivity(_content()), isTrue);
      await controller.updateActivity(_content(paused: true));
      await controller.endActivity();
      expect(notifier.calls, ['show', 'show', 'end']);
      expect(notifier.lastContent?.paused, isTrue);
    });

    test('a non-Android, non-iOS platform stays the documented inert '
        'no-op', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final controller = LiveActivityController();
      expect(controller.isSupported, isFalse);
      expect(await controller.startActivity(_content()), isFalse);
    });
  });

  group('never-throws contract (#3722 fault injection)', () {
    test('a throwing plugin is swallowed — show returns false, end '
        'completes normally', () async {
      final notifier =
          AndroidLiveActivityNotifier(plugin: _ThrowingPlugin());
      await expectLater(notifier.show(_content()), completes);
      expect(await notifier.show(_content()), isFalse,
          reason: 'a notification failure must never reach the recorder');
      await expectLater(notifier.end(), completes);
    });
  });

  test('recordingLabel is NOT part of the iOS channel map — the Swift '
      'ContentState lock-step stays untouched (#3722)', () {
    expect(_content().toChannelMap().containsKey('recordingLabel'), isFalse);
  });
}

/// Every plugin call throws — drives the never-throw boundary.
class _ThrowingPlugin implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('injected plugin fault');
}

class _RecordingNotifier extends AndroidLiveActivityNotifier {
  final List<String> calls = [];
  LiveActivityContent? lastContent;

  @override
  Future<bool> show(LiveActivityContent content) async {
    calls.add('show');
    lastContent = content;
    return true;
  }

  @override
  Future<void> end() async {
    calls.add('end');
  }
}
