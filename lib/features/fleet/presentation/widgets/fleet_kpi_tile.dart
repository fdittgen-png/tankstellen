// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/domain/fleet/claim_class.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import 'fleet_figure.dart';

/// One fleet KPI as a stat tile (#4216).
///
/// A stat tile rather than a chart, deliberately: a single headline
/// number has no shape to plot, and a sparkline behind it would be a
/// second, unlabelled encoding of data the period does not contain.
/// What the tile does carry is everything #4216 asks a KPI to expose —
/// the figure, its claim class, the caveat its provenance requires and
/// the sample count it rests on.
///
/// The value text wears an ink token, never a series colour: a figure
/// is text, and colouring it would make identity depend on hue.
class FleetKpiTile extends StatelessWidget {
  const FleetKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.claim,
    this.caveat,
    this.samples,
  });

  /// What the number is, from ARB.
  final String label;

  /// The formatted figure — already qualified by [fleetFigure], so an
  /// estimate arrives carrying its `≈` and an absence arrives as "Not
  /// calculated".
  final String value;

  /// What the figure may be used for (#4219).
  final ClaimClass claim;

  /// The provenance caveat, when the value has one.
  final String? caveat;

  /// How many observations it rests on; null hides the line.
  final int? samples;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppText.label(context)),
            const SizedBox(height: Spacing.sm),
            Text(value, style: AppText.title(context)),
            const SizedBox(height: Spacing.xs),
            Text(fleetClaimLabel(l, claim), style: AppText.label(context)),
            if (caveat case final String text)
              Text(text, style: AppText.label(context)),
            if (samples case final int n)
              Text(l.fleetManagerSamples(n), style: AppText.label(context)),
          ],
        ),
      ),
    );
  }
}

/// One vehicle's magnitude beside the others (#4216).
///
/// A horizontal bar, one measure, one axis: the comparison is "which
/// vehicle costs most per km", and a second series or a second scale
/// would make that question harder rather than richer. The fill is one
/// hue from the colour scheme — magnitude is encoded by LENGTH, so hue
/// carries no information and must not pretend to.
///
/// Every bar is directly labelled, so identity never depends on colour
/// and no legend is needed. A [fraction] of null is a vehicle with no
/// figure: the track is drawn empty and the label says why, rather
/// than a zero-length bar that reads as "cheapest".
class FleetComparisonBar extends StatelessWidget {
  const FleetComparisonBar({
    super.key,
    required this.name,
    required this.value,
    required this.fraction,
    this.subtitle,
    this.onTap,
  });

  /// The organisation's own name for the vehicle.
  final String name;

  /// The already-formatted, already-qualified figure.
  final String value;

  /// 0..1 of the largest bar in the group, or null when there is no
  /// figure to draw.
  final double? fraction;

  /// The suppression or data-quality line under the bar.
  final String? subtitle;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: Spacing.md),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ClipRRect(
              borderRadius: AppRadius.sm,
              child: LinearProgressIndicator(
                value: fraction ?? 0,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary),
              ),
            ),
            if (subtitle case final String text) ...[
              const SizedBox(height: Spacing.xs),
              Text(text, style: AppText.label(context)),
            ],
          ],
        ),
      ),
    );
  }
}
