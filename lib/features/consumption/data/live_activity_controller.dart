// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart binding for the app-internal iOS Live Activity channel
/// `tankstellen/live_activity` (#3170). The Swift side lives in
/// `ios/Runner/LiveActivityBridge.swift` and mirrors the same channel
/// name and method set.
///
/// Live Activities (Dynamic Island / lock-screen surface) are the
/// iOS-native answer to the Android PiP driving tile — iOS PiP is
/// video-only by OS policy ([PipController]). On every other platform
/// every method here is an inert no-op and [isSupported] is false, so
/// call sites need no platform branching of their own (the plugin-seam
/// rule: no `Platform.isIOS` forks in shared code).
///
/// None of the methods ever throw — a missing handler (unit-test
/// engine), a user who disabled Live Activities, or any platform error
/// degrades to "no activity shown", never to a crashed recorder.
class LiveActivityController {
  /// [channel] is injectable so unit tests can supply a mock without a
  /// live platform binding.
  LiveActivityController({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('tankstellen/live_activity');

  final MethodChannel _channel;

  /// Whether the running platform can host a Live Activity at all.
  /// iOS-only; the OS-level gate (iOS ≥ 16.1 + the user's per-app
  /// Live Activities toggle) is checked natively by [startActivity].
  bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  /// Request a new Live Activity rendering [content] (the
  /// `LiveActivityContent.toChannelMap()` payload). Returns false when
  /// the activity could not be started (unsupported platform, the user
  /// disabled Live Activities, or ActivityKit rejected the request) —
  /// callers treat false as "stay quiet for this trip".
  Future<bool> startActivity(Map<String, Object?> content) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('start', content) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Push fresh [content] onto the running activity. Best-effort: a
  /// failure (no running activity, platform error) is silently dropped —
  /// the next update or the trip end will reconcile.
  Future<void> updateActivity(Map<String, Object?> content) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('update', content);
    } on PlatformException {
      // Best-effort: a failed update just leaves stale content briefly.
    } on MissingPluginException {
      // No native handler (e.g. a unit-test engine) — silently skip.
    }
  }

  /// End and immediately dismiss the activity (trip stopped). Also ends
  /// any activity left over from a previous process so a crash can't
  /// strand a stale surface on the lock screen.
  Future<void> endActivity() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('end');
    } on PlatformException {
      // Best-effort: ActivityKit times stranded activities out itself.
    } on MissingPluginException {
      // No native handler — nothing to end.
    }
  }
}
