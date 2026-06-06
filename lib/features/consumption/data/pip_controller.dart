// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart binding for the app-internal Picture-in-Picture channel
/// `tankstellen/pip` (#1884). The Kotlin side lives on `MainActivity`
/// — PiP is Activity-bound — and mirrors the same channel name.
///
/// PiP is an Android-only capability (iOS PiP is restricted to video
/// playback and cannot host arbitrary app UI). On every other platform
/// every method is an inert no-op and [isSupported] is false, so call
/// sites need no platform branching of their own.
class PipController {
  /// [channel] is injectable so widget tests can supply a mock without
  /// a live platform binding.
  PipController({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('tankstellen/pip') {
    if (isSupported) {
      _channel.setMethodCallHandler(_onNativeCall);
    }
  }

  final MethodChannel _channel;
  final StreamController<bool> _modeController =
      StreamController<bool>.broadcast();

  /// Emits true when the OS moves the app into a PiP tile and false
  /// when it restores to full screen.
  Stream<bool> get pipModeChanges => _modeController.stream;

  /// Whether the running platform can host an app-UI PiP tile.
  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Request an immediate move into a PiP tile. Returns false when PiP
  /// could not be entered (unsupported platform, API < 26, or the
  /// activity is in a state that forbids the transition).
  Future<bool> enterPip() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('enterPip') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Bring the app back to the foreground in full screen (#2964).
  ///
  /// Tapping the body of the floating PiP tile calls this so the user can
  /// restore the full app with a single tap — the native side reorders the
  /// EXISTING task to the front (preserving the live recording / engine
  /// state) and the OS leaves PiP. Returns false on an unsupported platform
  /// or when the native reorder could not be performed; the tile then simply
  /// stays in PiP (the system expand control remains available).
  Future<bool> bringToFront() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('bringToFront') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Tell the native layer whether to auto-enter PiP when the user
  /// leaves the app (Home / Recents). The recording screen enables
  /// this only while a trip is recording, so leaving the app from an
  /// unrelated screen never shrinks the wrong UI into the tile.
  Future<void> setAutoEnterEnabled(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setAutoEnter', enabled);
    } on PlatformException {
      // Best-effort: a failed opt-in just means no auto-PiP.
    } on MissingPluginException {
      // No native handler (e.g. a unit-test engine) — silently skip.
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onPipModeChanged') {
      _modeController.add(call.arguments == true);
    }
    return null;
  }

  /// Release the channel handler and close the mode stream. Call from
  /// the owning widget's `dispose`.
  void dispose() {
    if (isSupported) {
      _channel.setMethodCallHandler(null);
    }
    _modeController.close();
  }
}
