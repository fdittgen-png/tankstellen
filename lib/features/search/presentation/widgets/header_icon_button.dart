// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// #3366 — a small primary-tinted icon button used in the search-results
/// row (list/all-prices view toggle, filters). Extracted so the siblings
/// share one definition (and the [AppRadius] token) instead of repeating
/// the Semantics + InkWell + Padding + Icon scaffold.
///
/// #3926 — every one of them now carries a [Tooltip] as well as its
/// accessibility label (the old header showed three bare glyphs with
/// neither), and can hang a count [badgeCount] off the glyph so an active
/// filter set is visible without opening anything.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
    this.tooltip,
    this.badgeCount,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  /// Long-press / hover text. Defaults to [semanticsLabel].
  final String? tooltip;

  /// When greater than zero, a Material [Badge] carrying the number is
  /// drawn on the glyph.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final count = badgeCount ?? 0;
    final Widget glyph = Icon(
      icon,
      size: 18,
      color: Theme.of(context).colorScheme.primary,
    );
    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip ?? semanticsLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: count > 0
                ? Badge.count(count: count, child: glyph)
                : glyph,
          ),
        ),
      ),
    );
  }
}
