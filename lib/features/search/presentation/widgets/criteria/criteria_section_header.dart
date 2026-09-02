// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// The criteria sheet's section eyebrow (#3548, promoted to its own file
/// by #3927 so the brand group can label itself the same way as the fuel
/// and amenity groups).
///
/// Letter-spaced, medium-weight `onSurfaceVariant` label instead of a plain
/// `titleSmall`, so section starts scan as structure rather than body text.
/// Style only — the string itself is the localized label.
class CriteriaSectionHeader extends StatelessWidget {
  const CriteriaSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
