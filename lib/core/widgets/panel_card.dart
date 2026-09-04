// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/spacing.dart';

/// The **secondary** surface level of the visual grammar (#3948, Epic
/// #3947): a panel of supporting figures — the stat tiles under the tank
/// card, a month-over-month comparison, an alerts summary.
///
/// A panel is `surfaceContainerHighest` with NO outline and NO elevation,
/// so beside a [PrimaryCard] (outlined `surfaceContainerLow`) it reads as
/// ground rather than figure: the eye lands on the primary card first and
/// reads the panel second. See [PrimaryCard] for the full level table.
///
/// Geometry matches the primary card — margin [Spacing.surfaceMargin],
/// padding [Spacing.cardPadding], corner [AppRadius.lg] — so a stack of
/// the two levels keeps one rhythm down the page.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = Spacing.cardPadding,
    this.margin = Spacing.surfaceMargin,
  });

  /// The panel body.
  final Widget child;

  /// Tap handler — when non-null the body sits inside an [InkWell].
  final VoidCallback? onTap;

  /// Inner padding, default [Spacing.cardPadding].
  final EdgeInsetsGeometry padding;

  /// Outer margin, default [Spacing.surfaceMargin].
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Padding(padding: padding, child: child);
    return Card(
      margin: margin,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      child: onTap == null
          ? body
          : InkWell(onTap: onTap, borderRadius: AppRadius.lg, child: body),
    );
  }
}
