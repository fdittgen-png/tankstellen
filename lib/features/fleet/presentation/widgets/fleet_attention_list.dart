// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/fleet_attention.dart';
import '../../providers/fleet_manager_providers.dart';

/// The "Needs attention" list (#4216).
///
/// Every line is about a VEHICLE or about the DATA — never about a
/// person. #4214 rules out manager-facing driver scores, so this list
/// has no employee names, no ordering of people and no residual
/// attributed to anyone; a high cost per km is a car to look at.
///
/// An empty list says so rather than disappearing: "nothing needs
/// attention" is information, and a section that vanishes leaves the
/// manager wondering whether it ran.
class FleetAttentionList extends ConsumerWidget {
  const FleetAttentionList({super.key, required this.items});

  final List<FleetAttentionItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text(l.fleetManagerAttentionNone,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(item.kind),
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(_labelFor(context, ref, l, item),
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// A glyph beside every line, so the list is not colour-coded: the
  /// icon plus the sentence carry the meaning, and neither depends on
  /// hue (the kinds are not a severity ramp).
  IconData _iconFor(FleetAttentionKind kind) => switch (kind) {
        FleetAttentionKind.costPerKmOutlier => Icons.trending_up,
        FleetAttentionKind.lowMeasuredCoverage => Icons.rule_outlined,
        FleetAttentionKind.noDistanceEvidence => Icons.speed_outlined,
        FleetAttentionKind.co2NotCalculated => Icons.eco_outlined,
        FleetAttentionKind.mixedCurrency => Icons.currency_exchange_outlined,
        FleetAttentionKind.rowsSuppressed => Icons.shield_outlined,
      };

  String _labelFor(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    FleetAttentionItem item,
  ) {
    final id = item.fleetVehicleId;
    final name = id == null
        ? ''
        : ref.watch(fleetVehicleRowByIdProvider(id))?.displayName ??
            l.fleetManagerVehicleUnnamed(id);
    return switch (item.kind) {
      FleetAttentionKind.costPerKmOutlier =>
        l.fleetManagerAttentionCostOutlier(name),
      FleetAttentionKind.lowMeasuredCoverage =>
        l.fleetManagerAttentionLowCoverage(name),
      FleetAttentionKind.noDistanceEvidence =>
        l.fleetManagerAttentionNoDistance(name),
      FleetAttentionKind.co2NotCalculated => l.fleetManagerAttentionCo2(name),
      FleetAttentionKind.mixedCurrency =>
        l.fleetManagerAttentionMixedCurrency,
      FleetAttentionKind.rowsSuppressed => l.fleetManagerAttentionSuppressed(
          _suppressedCount(ref),
        ),
    };
  }

  int _suppressedCount(WidgetRef ref) =>
      ref.watch(fleetPeriodKpisProvider).asData?.value?.suppressedCount ?? 0;
}
