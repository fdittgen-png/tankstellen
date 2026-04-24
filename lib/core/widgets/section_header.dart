import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Canonical section heading — one widget for every inline
/// "section title" in the app.
///
/// Collapses the 60+ inline `textTheme.titleMedium.copyWith(...)` calls
/// scattered across feature screens into one shape with a fixed padding,
/// font weight, and optional subtitle / leading icon / trailing action.
///
/// See `docs/design/DESIGN_SYSTEM.md` §"SectionHeader" for the contract.
class SectionHeader extends StatelessWidget {
  /// Required — rendered in the `sectionHeader` text role
  /// (`titleMedium` weight 600 in `onSurface`).
  final String title;

  /// Optional second line in the `sectionSubhead` role (`bodySmall` in
  /// `onSurfaceVariant`).
  final String? subtitle;

  /// Optional right-aligned action (TextButton, IconButton with a
  /// tooltip, chip, …).
  final Widget? trailing;

  /// Optional small (16 dp) primary-tinted icon before the title.
  final IconData? leadingIcon;

  /// Outer padding — defaults to
  /// `EdgeInsets.fromLTRB(Spacing.xl, Spacing.lg, Spacing.xl, Spacing.sm)`
  /// per the design-system spec. Override with [EdgeInsets.zero] when
  /// the header is nested inside a card that already provides its own
  /// outer padding.
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leadingIcon,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.xl,
      Spacing.lg,
      Spacing.xl,
      Spacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: Spacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
