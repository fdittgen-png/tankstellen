// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // #3841 — leave immersive in TWO steps, deliberately.
    //
    // The status-bar COLOUR is already transparent everywhere (FlexColorScheme
    // pins it on every theme), so the black band users saw was never a colour:
    // it is what shows BEHIND a transparent bar when the app is not drawing
    // there. That is `immersiveSticky` still being in force.
    //
    // `setEnabledSystemUIMode(edgeToEdge)` alone does not reliably clear the
    // STICKY immersive flags — sticky mode is designed to re-hide the bars, so
    // asking for a different mode can leave the app in the transient-overlay
    // state Android draws as a dark scrim. Explicitly restoring the overlays
    // first ends immersive for certain; the second call then re-establishes
    // edge-to-edge so the app draws behind the bars again.
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }
}
