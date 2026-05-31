// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

/// Canonical corner-radius tokens (`docs/design/DESIGN_SYSTEM.md`, "Radius
/// scale").
///
/// Reuse these instead of writing `BorderRadius.circular(12)` inline. The
/// raw `radius*` doubles are the pixel values; the `AppRadius.*` getters
/// return the matching [BorderRadius.circular] for direct use in
/// `decoration:` / `borderRadius:` / `shape:` slots.
///
/// | Token | px | Use for |
/// | --- | --- | --- |
/// | `sm`  | 4  | Tight corners: small chips, dense inputs |
/// | `md`  | 8  | Default filled card (Material 3 filled-card rule) |
/// | `lg`  | 12 | Elevated card / sheet — matches the theme `cardRadius: 12` |
/// | `xl`  | 16 | Dialog + bottom-sheet corner |
/// | `xxl` | 24 | Hero surfaces (onboarding tiles, splash) |
///
/// The canonical card radius is [lg] (12), matching what
/// `flex_color_scheme` already applies to every `Card`.
abstract class AppRadius {
  /// Tight corners — small chips, dense inputs.
  static const double radiusSm = 4;

  /// Default filled card (Material 3 filled-card rule).
  static const double radiusMd = 8;

  /// Elevated card / sheet rounding — matches the theme `cardRadius: 12`.
  static const double radiusLg = 12;

  /// Dialog + bottom-sheet corner.
  static const double radiusXl = 16;

  /// Hero surfaces (onboarding tiles, splash).
  static const double radiusXxl = 24;

  /// `BorderRadius.circular(4)` — tight corners.
  static BorderRadius get sm => BorderRadius.circular(radiusSm);

  /// `BorderRadius.circular(8)` — default filled card.
  static BorderRadius get md => BorderRadius.circular(radiusMd);

  /// `BorderRadius.circular(12)` — canonical card / sheet radius.
  static BorderRadius get lg => BorderRadius.circular(radiusLg);

  /// `BorderRadius.circular(16)` — dialog + bottom-sheet corner.
  static BorderRadius get xl => BorderRadius.circular(radiusXl);

  /// `BorderRadius.circular(24)` — hero surfaces.
  static BorderRadius get xxl => BorderRadius.circular(radiusXxl);
}
