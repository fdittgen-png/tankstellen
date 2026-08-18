// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// The ONE icon-header info-card skeleton the sync auth / link-device
/// card family shares: a [Card] with a 16 px padding, an
/// `icon + title` header row, an optional secondary [body] paragraph
/// (bodySmall, onSurfaceVariant), and optional extra [children]
/// rendered below.
///
/// Feature boundary: primitives + widgets only — callers keep their
/// own providers, controllers, and localized strings.
class InfoCard extends StatelessWidget {
  final IconData icon;

  /// Header icon size — the family uses 18–20 px.
  final double iconSize;

  /// Header icon tint; null inherits the ambient [IconTheme].
  final Color? iconColor;

  /// Card fill; null keeps the theme's default card color.
  final Color? cardColor;

  final String title;

  /// Header text style; defaults to `titleSmall` + bold.
  final TextStyle? titleStyle;

  /// Wrap the title in an [Expanded] so long text ellipsizes/wraps
  /// instead of overflowing the header row.
  final bool expandTitle;

  /// Optional secondary paragraph under the header (bodySmall,
  /// onSurfaceVariant) — the family's shared body treatment.
  final String? body;

  /// Extra content below the header/body (interactive rows, inputs…).
  final List<Widget> children;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.iconSize = 20,
    this.iconColor,
    this.cardColor,
    this.titleStyle,
    this.expandTitle = false,
    this.body,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTitleStyle = titleStyle ??
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);
    final titleText = Text(title, style: effectiveTitleStyle);

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: iconSize, color: iconColor),
                const SizedBox(width: 8),
                if (expandTitle) Expanded(child: titleText) else titleText,
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}
