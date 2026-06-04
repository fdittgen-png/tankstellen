// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';

import 'shared_receipt_intent.dart';

/// GMS-free bridge to the native inbound-share receiver (#2735).
///
/// Replaces the `share_handler` plugin, which was dropped because pulling a
/// third-party share plugin risked dragging Google Play Services into the
/// F-Droid build. This talks to an in-repo `ShareIntentChannel.kt` registered
/// on `MainActivity` — the SAME app-internal channel pattern as
/// `Obd2ClassicPlugin` / `BackgroundAdapterChannel` / `PublicFileExporterChannel`,
/// so there is no external Gradle artefact and nothing to audit out of the
/// fdroid dex.
///
/// Two channels, mirroring the others:
///   * `tankstellen/share_intent/methods` — `getInitialShare()` returns the
///     `ACTION_SEND` payload that cold-launched the activity (or `null`);
///   * `tankstellen/share_intent/events` — a `Stream` that emits one decoded
///     [SharedReceiptIntent] per warm share (app already running).
///
/// The class is abstract with a default platform-backed [instance] so the
/// listener can be unit-tested by injecting a fake — the same test seam the
/// old `ShareHandlerPlatform` offered, minus the plugin.
abstract class ShareIntentChannel {
  /// The cold-launch share the OS handed the freshly-started activity, or
  /// `null` when the app wasn't launched from a share. Consumed once.
  Future<SharedReceiptIntent?> getInitialShare();

  /// Warm shares delivered while the app is already running.
  Stream<SharedReceiptIntent> get shareStream;

  /// The production, platform-channel-backed implementation.
  static final ShareIntentChannel instance = _PlatformShareIntentChannel();
}

class _PlatformShareIntentChannel implements ShareIntentChannel {
  static const _methods = MethodChannel('tankstellen/share_intent/methods');
  static const _events = EventChannel('tankstellen/share_intent/events');

  @override
  Future<SharedReceiptIntent?> getInitialShare() async {
    final raw = await _methods.invokeMethod<Object?>('getInitialShare');
    return SharedReceiptIntent.fromPlatform(raw);
  }

  @override
  Stream<SharedReceiptIntent> get shareStream => _events
      .receiveBroadcastStream()
      .map(SharedReceiptIntent.fromPlatform)
      .where((intent) => intent != null)
      .cast<SharedReceiptIntent>();
}
