// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_tap_dispatcher.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../data/android_live_activity_notifier.dart';
import 'trip_recording_provider.dart';

part 'trip_tile_action_listener_provider.g.dart';

/// #3724 — routes the Android recording tile's action buttons onto the
/// SAME [TripRecording] methods the in-app controls call — zero
/// duplicated control logic. Action taps arrive as synthetic
/// `trip_action:<id>` payloads on the app-wide
/// [NotificationTapDispatcher] stream (wired in
/// LocalNotificationService).
///
/// Also sweeps a stale tile at startup: the plain notification outlives
/// a killed process, and this listener's init runs on every launch —
/// the LiveActivitySync/coordinator pair then re-shows it if (and only
/// if) a trip is actually recording.
@Riverpod(keepAlive: true)
void tripTileActionListener(Ref ref) {
  final sub =
      NotificationTapDispatcher.instance.stream.listen((payload) {
    if (payload == null ||
        !payload.startsWith(AndroidLiveActivityNotifier.actionPayloadPrefix)) {
      return;
    }
    final action = payload
        .substring(AndroidLiveActivityNotifier.actionPayloadPrefix.length);
    BreadcrumbCollector.add('trip tile action', detail: action);
    final recorder = ref.read(tripRecordingProvider.notifier);
    switch (action) {
      case AndroidLiveActivityNotifier.actionPause:
        recorder.pause();
      case AndroidLiveActivityNotifier.actionResume:
        recorder.resume();
      case AndroidLiveActivityNotifier.actionStop:
        unawaited(recorder.stopAndSaveAutomatic());
      default:
        // Unknown action id — ignore (forward-compat with future ids).
        break;
    }
  });
  ref.onDispose(sub.cancel);
}
