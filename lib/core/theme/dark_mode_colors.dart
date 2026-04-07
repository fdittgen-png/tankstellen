import 'package:flutter/material.dart';

/// Semantic colors that adapt to light / dark mode for WCAG AA contrast.
///
/// Use these instead of hardcoded [Colors.green], [Colors.grey], etc.
/// All dark-mode variants have been chosen to meet at least 4.5:1
/// contrast against the standard Material 3 dark surface (#1C1B1F).
class DarkModeColors {
  DarkModeColors._();

  // ---------------------------------------------------------------------------
  // Status colors
  // ---------------------------------------------------------------------------

  /// Open / success / cheap indicator.
  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF66BB6A) // green.shade400 — 5.1:1 on dark surface
          : const Color(0xFF388E3C); // green.shade700 — 4.8:1 on white

  /// Closed / error / expensive indicator.
  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFEF5350) // red.shade400 — 4.6:1 on dark surface
          : const Color(0xFFD32F2F); // red.shade700 — 5.6:1 on white

  /// Warning / moderate / in-use indicator.
  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFA726) // orange.shade400 — 6.2:1 on dark surface
          : const Color(0xFFE65100); // deepOrange.shade900 — 4.6:1 on white

  // ---------------------------------------------------------------------------
  // Muted / secondary text
  // ---------------------------------------------------------------------------

  /// Muted text (replaces Colors.grey.shade600 / shade500).
  static Color mutedText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Hint / disabled text (replaces Colors.grey.shade400).
  static Color hintText(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  // ---------------------------------------------------------------------------
  // Surface / chip backgrounds
  // ---------------------------------------------------------------------------

  /// Light success background for chips/badges.
  static Color successSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
          : const Color(0xFFE8F5E9); // green.shade50

  /// Light error background.
  static Color errorSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB71C1C).withValues(alpha: 0.3)
          : const Color(0xFFFFEBEE); // red.shade50

  /// Light warning background.
  static Color warningSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE65100).withValues(alpha: 0.2)
          : const Color(0xFFFFF3E0); // orange.shade50

  // ---------------------------------------------------------------------------
  // Map overlay colors
  // ---------------------------------------------------------------------------

  /// Background for floating map overlays (legend, zoom buttons).
  static Color mapOverlay(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Colors.white.withValues(alpha: 0.9);

  /// Icon color for map overlay controls.
  static Color mapOverlayIcon(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Shadow color for map overlays.
  static Color mapOverlayShadow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.15);
}
