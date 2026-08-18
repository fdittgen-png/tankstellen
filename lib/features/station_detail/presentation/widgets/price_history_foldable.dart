// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import '../../../feature_management/api.dart';
import 'price_history_section.dart';

/// Collapsible wrapper around [PriceHistorySection] (#1957).
///
/// The price-history chart is detail-on-demand and a tall block, so on
/// the station-detail screen it ships **collapsed by default** —
/// `ExpansionTile.initiallyExpanded` defaults to false — keeping the
/// page compact. Tapping the tile reveals the chart + stats.
///
/// Feature.priceHistory finally gates this entry point (2026-08-17
/// review, dead-code finding 6): when the toggle is off the whole
/// foldable disappears from the detail screens. Default-on — behavior
/// unchanged unless the user disables it.
class PriceHistoryFoldable extends ConsumerWidget {
  final String stationId;
  final Station station;

  const PriceHistoryFoldable({
    super.key,
    required this.stationId,
    required this.station,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(enabledFeaturesProvider).contains(Feature.priceHistory);
    if (!enabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(l10n.priceHistory, style: theme.textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [PriceHistorySection(stationId: stationId, station: station)],
      ),
    );
  }
}
