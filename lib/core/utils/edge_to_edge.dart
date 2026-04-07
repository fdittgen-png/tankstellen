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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }
}
