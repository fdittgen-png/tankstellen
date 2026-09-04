// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Reusable empty state widget with icon, title, optional subtitle, and action.
///
/// Replaces 5 ad-hoc empty state implementations across MapScreen,
/// InlineMap, FavoritesScreen, and AlertsScreen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  /// Glyph on the primary action. Defaults to a search glass because the
  /// first empty states (map, favourites) all led to a search; a surface
  /// whose action is something else (add an alert, log a fill-up) passes
  /// its own so the button says what it does (#3951).
  final IconData actionIcon;

  /// Optional key on the primary action button, so a screen test can tap
  /// the action without depending on its label.
  final Key? actionKey;

  /// When true, anchor icon+title+subtitle in the top third of the
  /// viewport and pin the CTA near the bottom. Used by the consumption
  /// and favorites empty states (#1539) where the centred default left
  /// a large visual void on a fresh install. Requires a parent that
  /// hands the widget a bounded height (Expanded / TabBarView).
  final bool topBiased;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.topBiased = false,
    this.actionIcon = Icons.search,
    this.actionKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    final hasAction = actionLabel != null && onAction != null;
    final cta = hasAction
        ? FilledButton.icon(
            key: actionKey,
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel!),
          )
        : null;

    if (topBiased) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            body,
            const Spacer(flex: 5),
            ?cta,
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            if (cta != null) ...[
              const SizedBox(height: 24),
              cta,
            ],
          ],
        ),
      ),
    );
  }
}
