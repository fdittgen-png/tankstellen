// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/live_activity_content.dart';
import 'android_live_activity_notifier.dart';

/// Dart binding for the app-internal iOS Live Activity channel
/// `tankstellen/live_activity` (#3170). The Swift side lives in
/// `ios/Runner/LiveActivityBridge.swift` and mirrors the same channel
/// name and method set.
///
/// Live Activities (Dynamic Island / lock-screen surface) are the
/// iOS-native answer to the Android PiP driving tile — iOS PiP is
/// video-only by OS policy ([PipController]).
///
/// #3722 — ANDROID renders the same content as an ongoing chronometer
/// notification ([AndroidLiveActivityNotifier]): lock-screen/shade tile
/// with a natively ticking elapsed readout. Any other platform stays an
/// inert no-op with [isSupported] false, so call sites need no platform
/// branching of their own (the plugin-seam rule: no `Platform.isIOS`
/// forks in shared code).
///
/// None of the methods ever throw — a missing handler (unit-test
/// engine), a user who disabled Live Activities, or any platform error
/// degrades to "no activity shown", never to a crashed recorder.
class LiveActivityController {
  /// [channel] is injectable so unit tests can supply a mock without a
  /// live platform binding.
  /// The Android notifier is wired automatically on Android (#3722) —
  /// this class is the sanctioned platform-dispatch seam (#3163), so the
  /// provider stays platform-free. Tests inject a fake (or construct on
  /// a non-Android override for the inert path).
  LiveActivityController({
    MethodChannel? channel,
    AndroidLiveActivityNotifier? androidNotifier,
  })  : _channel = channel ?? const MethodChannel('tankstellen/live_activity'),
        _android = androidNotifier ??
            (defaultTargetPlatform == TargetPlatform.android
                ? AndroidLiveActivityNotifier()
                : null);

  final MethodChannel _channel;

  /// #3722 — non-null on Android (wired by the provider); null keeps the
  /// platform an inert no-op (tests, desktop).
  final AndroidLiveActivityNotifier? _android;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android && _android != null;

  /// Whether the running platform can host a live trip surface at all.
  /// iOS Live Activity or the Android ongoing tile (#3722); the OS-level
  /// gates (iOS 16.1+/user toggle, Android 13+ notification permission)
  /// are enforced by the respective platform paths.
  bool get isSupported => _isIos || _isAndroid;

  /// Request a new Live Activity rendering [content] (the
  /// `LiveActivityContent.toChannelMap()` payload). Returns false when
  /// the activity could not be started (unsupported platform, the user
  /// disabled Live Activities, or ActivityKit rejected the request) —
  /// callers treat false as "stay quiet for this trip".
  Future<bool> startActivity(LiveActivityContent content) async {
    if (_isAndroid) return _android!.show(content);
    if (!_isIos) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'start',
            content.toChannelMap(),
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Push fresh [content] onto the running activity. Best-effort: a
  /// failure (no running activity, platform error) is silently dropped —
  /// the next update or the trip end will reconcile.
  Future<void> updateActivity(LiveActivityContent content) async {
    if (_isAndroid) {
      await _android!.show(content); // in-place restyle (onlyAlertOnce)
      return;
    }
    if (!_isIos) return;
    try {
      await _channel.invokeMethod<void>('update', content.toChannelMap());
    } on PlatformException {
      // Best-effort: a failed update just leaves stale content briefly.
    } on MissingPluginException {
      // No native handler (e.g. a unit-test engine) — silently skip.
    }
  }

  /// End and immediately dismiss the activity (trip stopped). Also ends
  /// any activity left over from a previous process so a crash can't
  /// strand a stale surface on the lock screen.
  /// #3724 — release the Android notifier's swipe-resurrect heartbeat
  /// when the owning provider dies (widget tests would otherwise trip
  /// Flutter's pending-timer teardown check; production containers never
  /// dispose this, so it is effectively test-lifecycle hygiene).
  void dispose() {
    _android?.disposeHeartbeat();
  }

  Future<void> endActivity() async {
    if (_isAndroid) {
      await _android!.end();
      return;
    }
    if (!_isIos) return;
    try {
      await _channel.invokeMethod<void>('end');
    } on PlatformException {
      // Best-effort: ActivityKit times stranded activities out itself.
    } on MissingPluginException {
      // No native handler — nothing to end.
    }
  }
}
