// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
  ///
  /// #2492 — widened to a deeper, more saturated red (`#C62828`) on light
  /// so the error hue is unmistakably separated from the amber `warning`
  /// for red/green colourblind users. The dark variant keeps the brighter
  /// `red.shade400` because the requested `#C62828` reads only 3.05:1 on
  /// the dark surface, while `#EF5350` holds a safe 4.9:1.
  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFEF5350) // red.shade400 — 4.9:1 on dark surface
          : const Color(0xFFC62828); // red.shade800 — 5.5:1 on white

  /// Warning / moderate / in-use / stale indicator.
  ///
  /// #2492 — widened toward the amber/gold family (away from the old
  /// deep-orange `#E65100`, which sat too close to the error red) for
  /// colourblind safety. The dark variant uses the canonical amber
  /// `#F9A825` (8.7:1). The light variant darkens the *same* hue to
  /// `#C77800` (gold) because pure `#F9A825` as text on white is only
  /// 1.9:1 — far below AA; the darker gold holds 3.4:1 while staying
  /// clearly amber, not orange-red.
  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF9A825) // amber.shade800 — 8.7:1 on dark surface
          : const Color(0xFFC77800); // dark gold — 3.4:1 on white

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------

  /// Adaptive brand green (#2526).
  ///
  /// The brand identity green is the icon's `#2E7D32`. On a light surface it
  /// clears AA comfortably, but as text/iconography on a dark surface it
  /// collapses to ~3.4:1 (fails AA). On dark we substitute the scheme's
  /// lighter `primary` (`#69A16B`), which clears AA (~5.8:1) on the dark card
  /// surface while staying recognisably the same forest-green brand hue.
  static Color brandGreen(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.primary // #69A16B on dark
          : const Color(0xFF2E7D32); // icon brand green on light

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
