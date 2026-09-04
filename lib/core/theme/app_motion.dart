// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

/// Reduced-motion guard for the app's in-app animations (#2972).
///
/// Reads the OS accessibility "remove animations" / "reduce motion" setting
/// (iOS: Settings → Accessibility → Motion → Reduce Motion; Android:
/// Settings → Accessibility → Remove animations) via Flutter's
/// [MediaQueryData.disableAnimations] flag, surfaced as
/// [MediaQuery.disableAnimationsOf].
///
/// This is an OS-driven flag ONLY — there is intentionally no in-app toggle
/// and no new user-facing string. Motion-using widgets short-circuit to their
/// END-STATE (final frame, no controller run) when [enabled] returns false,
/// so a motion-sensitive user gets the same information with zero movement.
///
/// Added as a tiny additive layer on the Epic-#2487 design system so every
/// animated widget gates the same way:
///
/// ```dart
/// if (AppMotion.enabled(context)) {
///   _controller.forward(from: 0);
/// }
/// // else: render the end-state directly.
/// ```
class AppMotion {
  AppMotion._();

  /// True when the OS has NOT requested reduced motion — i.e. it is fine to
  /// run decorative animations. False when the user enabled the platform
  /// "remove animations" / "reduce motion" setting; callers must then render
  /// the animation's end-state without kicking a controller.
  static bool enabled(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);

  /// Duration of a **selection** state change — a chip turning
  /// `primaryContainer`, a pill filling, a card gaining its accent (#3948).
  /// Matches Material's theme-change beat (200 ms) and the existing
  /// `SelectablePill` transition, so every selectable surface settles in
  /// the same rhythm.
  static const Duration selection = Duration(milliseconds: 200);

  /// [selection], or [Duration.zero] when the OS asked for reduced motion —
  /// hand this straight to an `AnimatedContainer` / `AnimatedSwitcher` so
  /// the end-state is still reached, just without the tween.
  static Duration selectionDuration(BuildContext context) =>
      enabled(context) ? selection : Duration.zero;
}
