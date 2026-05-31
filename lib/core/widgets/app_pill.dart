// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// A small, static (non-toggleable) labelled badge — the canonical shape
/// for connector / amenity / count pills that sit on cards and detail
/// headers (#2494).
///
/// Several widgets hand-rolled the same tiny `Container` + `BoxDecoration`
/// at differing radii to render an icon+label badge. [AppPill] gives them
/// one reusable shape at [AppRadius.sm] (the dense-chip token) so badges
/// across the app read consistently. Colours default to the
/// `surfaceContainerHighest` / `onSurfaceVariant` neutral pair but can be
/// overridden for semantic pills (e.g. a coloured connector badge).
///
/// Unlike [SelectablePill] this carries no selection state and no tap
/// handler — it is a passive label. Reach for [SelectablePill] when the
/// pill toggles a mode.
class AppPill extends StatelessWidget {
  /// Visible label text. Must already be localized by the caller.
  final String label;

  /// Optional leading glyph. When null the pill is label-only.
  final IconData? icon;

  /// Pill fill colour. Defaults to `colorScheme.surfaceContainerHighest`.
  final Color? background;

  /// Icon + text colour. Defaults to `colorScheme.onSurfaceVariant`.
  final Color? foreground;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foreground ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
