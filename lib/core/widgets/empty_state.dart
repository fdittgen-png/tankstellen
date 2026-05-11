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
            onPressed: onAction,
            icon: const Icon(Icons.search),
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
