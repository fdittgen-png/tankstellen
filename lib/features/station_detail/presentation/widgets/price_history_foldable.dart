// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
import 'price_history_section.dart';

/// Collapsible wrapper around [PriceHistorySection] (#1957).
///
/// The price-history chart is detail-on-demand and a tall block, so on
/// the station-detail screen it ships **collapsed by default** —
/// `ExpansionTile.initiallyExpanded` defaults to false — keeping the
/// page compact. Tapping the tile reveals the chart + stats.
class PriceHistoryFoldable extends StatelessWidget {
  final String stationId;
  final Station station;

  const PriceHistoryFoldable({
    super.key,
    required this.stationId,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          l10n?.priceHistory ?? 'Price History',
          style: theme.textTheme.titleMedium,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          PriceHistorySection(stationId: stationId, station: station),
        ],
      ),
    );
  }
}
