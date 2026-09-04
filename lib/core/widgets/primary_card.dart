// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/spacing.dart';

/// The **primary** surface level of the visual grammar (#3948, Epic #3947):
/// the ONE thing a screen is about — the tank level, the tank report, a
/// station in the results.
///
/// Before the grammar every card was a filled `Card` on a filled page of
/// almost the same tone, separated by a 2 dp shadow, so nothing on any
/// screen read as primary. The grammar gives the page three levels:
///
/// | Level | Widget | Fill | Edge | Elevation |
/// | --- | --- | --- | --- | --- |
/// | page | `Scaffold` | `surface` | — | — |
/// | primary | [PrimaryCard] | `surfaceContainerLow` | 1 dp `outlineVariant` | none |
/// | secondary | [PanelCard] | `surfaceContainerHighest` | none | none |
///
/// Elevation is reserved for things that float (FAB, sheets, snackbars),
/// so neither card casts a shadow — the outline is what makes the primary
/// card the figure and the panel the ground.
///
/// Geometry: outer margin [Spacing.surfaceMargin] (12 / 8), inner padding
/// [Spacing.cardPadding] (16), corner [AppRadius.lg]. Pass
/// `padding: EdgeInsets.zero` for a full-bleed body (a list, a table) and
/// let the body own its own padding.
///
/// [onTap] wraps the body in an [InkWell] sharing the card's radius, so a
/// tappable primary card ripples inside its own corners.
class PrimaryCard extends StatelessWidget {
  const PrimaryCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = Spacing.cardPadding,
    this.margin = Spacing.surfaceMargin,
  });

  /// The card body.
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
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: onTap == null
          ? body
          : InkWell(onTap: onTap, borderRadius: AppRadius.lg, child: body),
    );
  }
}
