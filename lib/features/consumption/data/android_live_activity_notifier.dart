// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/live_activity_content.dart';

/// #3722 — the ANDROID twin of the iOS Live Activity (#3170): an ongoing
/// chronometer notification on the lock screen / notification shade
/// while a trip records (Samsung surfaces it in the "dynamic content"
/// card area, like a media tile).
///
/// The elapsed readout ticks NATIVELY: `usesChronometer` + `when =
/// startedAtEpochMs` make the OS render "recording since / for" without
/// any update traffic — exactly the ActivityKit `Text(timerInterval:)`
/// trick the Swift widget uses. Distance / consumption refresh rides the
/// [LiveActivityCoordinator]'s existing update cadence with
/// `onlyAlertOnce`, so updates are silent in-place redraws.
///
/// Same never-throw contract as [LiveActivityController]: any platform
/// failure degrades to "no tile", never to a crashed recorder.
class AndroidLiveActivityNotifier {
  /// [plugin] is injectable for tests; the default constructor talks to
  /// the same platform facade [LocalNotificationService] initialized at
  /// startup (tap callback + permission flow live there).
  AndroidLiveActivityNotifier({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Fixed id — at most one live-trip tile exists (mirrors the
  /// single-activity invariant of the iOS side). 3170 = the epic number.
  static const int notificationId = 3170;

  static const String _channelId = 'trip_live';
  // Channel name/description surface only in the SYSTEM settings UI —
  // same English-literal convention as LocalNotificationService's
  // channels.
  static const String _channelName = 'Trip recording status';
  static const String _channelDescription =
      'Ongoing tile while a trip records: elapsed time, distance and '
      'consumption';

  bool _channelCreated = false;

  Future<void> _ensureChannel() async {
    if (_channelCreated) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      // Low: visible on the shade + lock screen, never a heads-up
      // banner or a sound while driving.
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ));
    _channelCreated = true;
  }

  /// Show (or restyle in place) the live tile for [content]. Returns
  /// false when the platform refused — the coordinator then stays quiet
  /// for this trip, mirroring the iOS contract.
  Future<bool> show(LiveActivityContent content) async {
    try {
      await _ensureChannel();
      final render = buildAndroidLiveActivityRender(content);
      await _plugin.show(
        id: notificationId,
        title: render.title,
        body: render.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.low,
            priority: Priority.low,
            category: AndroidNotificationCategory.stopwatch,
            visibility: NotificationVisibility.public,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            playSound: false,
            enableVibration: false,
            showWhen: true,
            when: content.startedAtEpochMs,
            usesChronometer: render.chronometerTicking,
          ),
        ),
      );
      return true;
    } catch (e, st) {
      // Best-effort by contract — a notification failure must never
      // reach the recorder.
      debugPrint('AndroidLiveActivityNotifier: show failed: $e\n$st');
      return false;
    }
  }

  /// Remove the tile (trip stopped, or a stale tile from a dead
  /// process on next launch).
  Future<void> end() async {
    try {
      await _plugin.cancel(id: notificationId);
    } catch (e, st) {
      debugPrint('AndroidLiveActivityNotifier: cancel failed: $e\n$st');
    }
  }
}

/// What the tile shows for one content snapshot — pure and separately
/// testable (the plugin call itself is a thin pass-through).
@immutable
class AndroidLiveActivityRender {
  const AndroidLiveActivityRender({
    required this.title,
    required this.body,
    required this.chronometerTicking,
  });

  final String title;
  final String body;

  /// Paused trips freeze the elapsed readout (the `when` timestamp still
  /// anchors "started at HH:MM" via `showWhen`).
  final bool chronometerTicking;
}

/// Render precedence mirrors the PiP tile / Live Activity exactly:
/// approach mode leads with the station + price, recording mode with the
/// consumption hero; the paused label replaces the title while paused.
AndroidLiveActivityRender buildAndroidLiveActivityRender(
    LiveActivityContent c) {
  final title = c.paused ? c.pausedLabel : c.recordingLabel;
  final parts = <String>[
    if (c.mode == LiveActivityMode.approach) ...[
      if (c.stationName != null && c.stationName!.isNotEmpty) c.stationName!,
      if (c.priceText != null) '${c.priceText} ${c.fuelLabel ?? ''}'.trim(),
      if (c.stationDistanceText != null) c.stationDistanceText!,
    ] else ...[
      '${c.bigFigure} ${c.bigCaption}',
      if (c.distanceText != null) c.distanceText!,
    ],
  ];
  return AndroidLiveActivityRender(
    title: title,
    body: parts.join(' · '),
    chronometerTicking: !c.paused,
  );
}
