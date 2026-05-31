// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// A compact, toggleable icon+label pill used for binary/segmented mode
/// selection — e.g. the search "All stations / Best stops" toggle and the
/// route-map "All / Best" view switch (#2494).
///
/// Collapses the two near-identical `ModeChip` (search) and
/// `RouteViewModeChip` (map) widgets into a single canonical pill. Both
/// hand-rolled their own `BoxDecoration` at differing radii (20 vs 16);
/// this unifies them at [AppRadius.xl] so every selectable pill in the app
/// shares one shape. Selected pills fill with `primaryContainer` and bold
/// the label + tint the icon `primary`; unselected pills are transparent
/// with a faint outline.
class SelectablePill extends StatelessWidget {
  /// Visible label text. Must already be localized by the caller.
  final String label;

  /// Leading glyph rendered before the label.
  final IconData icon;

  /// Whether the pill reads as the active selection.
  final bool selected;

  /// Tap handler — flips the selection in the caller's state.
  final VoidCallback onTap;

  const SelectablePill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: AppRadius.xl,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
