// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logging/app_log.dart';
import '../logging/error_logger.dart';

/// Configures edge-to-edge display for Android 15+ compatibility.
///
/// Android 15 enforces edge-to-edge: apps must draw behind the system
/// navigation bar and status bar. This class sets transparent system bars
/// and opts in to [SystemUiMode.edgeToEdge].
///
/// Individual screens handle insets via [SafeArea] or
/// [MediaQuery.viewPadding] to avoid content overlapping system bars.
class EdgeToEdge {
  /// The [SystemUiOverlayStyle] used for edge-to-edge display.
  ///
  /// - Status bar: transparent background
  /// - Navigation bar: transparent, no contrast scrim
  static const overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  /// Enables edge-to-edge mode and applies transparent system bar styling.
  ///
  /// Call once during app startup after [WidgetsFlutterBinding.ensureInitialized].
  static void enable() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  /// Restores the app's normal look after a screen went immersive (#3827).
  ///
  /// Every screen that hides the bars has to put them back, and six of them
  /// did it with
  ///
  /// ```dart
  /// SystemChrome.setEnabledSystemUIMode(
  ///   SystemUiMode.manual, overlays: SystemUiOverlay.values);
  /// ```
  ///
  /// which re-shows the bars but leaves edge-to-edge OFF and never re-applies
  /// [overlayStyle]. Android then paints the status bar opaque black, and
  /// because nothing else ever calls [enable] again, that survives leaving the
  /// screen — the whole app stayed black-topped until restart.
  ///
  /// `manual` is not the inverse of `edgeToEdge`; [enable] is. This is that
  /// inverse, in one place, so the seventh screen cannot get it wrong.
  static Future<void> restore() async {
    // #4082 — called on every navigation and branch switch now, so a
    // platform without the channel (tests, desktop) must not turn a
    // self-heal into a crash: log it and carry on.
    try {
      await _restore();
    } catch (e, st) {
      log.warn('EdgeToEdge.restore: system UI call failed',
          error: e, stack: st, layer: ErrorLayer.other);
    }
  }

  static Future<void> _restore() async {
    // #4084 — NO `SystemUiMode.manual` step any more. That step was the
    // one thing in the app that ever left edge-to-edge: Android drops the
    // window's transparent bar for a moment, and Flutter then dedupes the
    // unchanged overlay style and never re-sends it — the black band. It
    // existed to end a sticky immersive mode, and #3843 removed immersive
    // app-wide, so there is nothing to end. #4082 made this run on every
    // navigation, which turned a rare flicker into "a few seconds into the
    // recording form, and it stays". Re-assert edge-to-edge and FORCE the
    // style through: Flutter only sends a style that differs from the last
    // one it sent, so an OS-side reset is invisible to it.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await forceOverlayStyle();
  }

  /// Sends [overlayStyle] even when Flutter believes it is already applied.
  ///
  /// `setSystemUIOverlayStyle` coalesces per microtask and skips a style
  /// equal to the last one it sent; a bump to a distinguishable style,
  /// flushed, then the real one, flushed, defeats that without a platform
  /// API Flutter does not expose.
  static Future<void> forceOverlayStyle() async {
    // Flutter flushes a pending style in a microtask; awaiting one is
    // enough to get each send out, and — unlike a zero-length timer — it
    // needs no frame pump, so a caller in a widget test is not stalled.
    SystemChrome.setSystemUIOverlayStyle(
      overlayStyle.copyWith(statusBarColor: const Color(0x00000001)),
    );
    await Future<void>.microtask(() {});
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    await Future<void>.microtask(() {});
  }
}
