// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'section_header.dart';

/// Canonical grouped-content card used across every screen body.
///
/// One card, one elevation, one radius, one padding — replaces the
/// 80+ raw `Card(...)` call sites with ad-hoc elevation/margin/color
/// flagged in the #923 audit.
///
/// Visual contract (see `docs/design/DESIGN_SYSTEM.md` §"SectionCard"):
///
///   * Elevation follows the theme's `cardTheme.elevation` (#2488):
///     light = 0 (tint-only), eco/dark = 1 dp. A hairline
///     `surfaceContainerHighest` outline guarantees a card↔scaffold delta
///     on every theme — most importantly on dark, where a 1 dp shadow is
///     faint, and on light, where there is no shadow at all.
///   * `color: colorScheme.surfaceContainerLow` — in the de-inverted eco
///     ramp (#2488) the scaffold is the lightest (near-white) base surface
///     and the card carries the gentle green container tint, the canonical
///     Material direction (same as light/dark) rather than the old inverted
///     deep-green scaffold.
///   * Corner radius is 12 px (`AppRadius.lg`), matching the global theme
///     (`FlexColorScheme.subThemesData.cardRadius`).
///   * Default inner padding = `Spacing.cardPadding`.
///   * Default outer margin = `EdgeInsets.zero` so the host `ListView`
///     / `Column` owns card-to-card spacing.
///
/// When [title] is non-null the card renders an internal
/// [SectionHeader] at the top followed by a small gap and the [child].
class SectionCard extends StatelessWidget {
  /// Optional card header title. When null the card has no built-in
  /// header — consumers can place their own leading widget inside
  /// [child].
  final String? title;

  /// Optional sub-title rendered under [title].
  final String? subtitle;

  /// Optional icon rendered by the internal [SectionHeader].
  final IconData? leadingIcon;

  /// Accent color forwarded to the header icon. Defaults to
  /// `colorScheme.primary` when null.
  final Color? accent;

  /// The card body. Required.
  final Widget child;

  /// Inner padding — defaults to `Spacing.cardPadding`
  /// (`EdgeInsets.all(16)`). Override when a card hosts a
  /// full-bleed list (then pass `EdgeInsets.zero` and let the list
  /// owner add its own padding).
  final EdgeInsets padding;

  /// Outer margin — defaults to `EdgeInsets.zero` so the host
  /// scrollable owns card-to-card spacing.
  final EdgeInsets margin;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leadingIcon,
    this.accent,
    this.padding = Spacing.cardPadding,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // #2488 — honour the theme's card elevation (eco/dark = 1 dp,
    // light = 0). On dark a 1 dp shadow is faint, and on light there is
    // no shadow at all, so a hairline `surfaceContainerHighest` outline
    // guarantees a card↔scaffold delta on every theme. The 12 px radius
    // is inherited from FlexColorScheme's global `cardRadius`.
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: theme.cardTheme.elevation ?? 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.surfaceContainerHighest),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              SectionHeader(
                title: title!,
                subtitle: subtitle,
                leadingIcon: leadingIcon,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
