// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_station.dart';

/// Compact card for an EV charging station in the favorites list.
///
/// Uses the canonical [ChargingStation] type (unified in #560) with
/// the typed [EvConnector] instead of the previous free-form search
/// side [Connector].
class EvFavoriteCard extends StatelessWidget {
  /// Crystal-blue accent (#2143) — cool, glassy, distinct from the
  /// muted-teal `FuelTypeElectric` (#3B8079). Pairs the EV card's
  /// right-side detail column with the fuel cards' price column
  /// without borrowing their fuel palette.
  static const Color crystalBlue = Color(0xFF4FC3F7);

  final ChargingStation station;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const EvFavoriteCard({
    super.key,
    required this.station,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final operatorName = station.operator ?? '';
    final connectors = station.connectors;
    final available = connectors
        .where((c) => c.status == ConnectorStatus.available)
        .length;
    final total = connectors.length;
    final maxPower = connectors.isEmpty
        ? 0.0
        : connectors.map((c) => c.maxPowerKw).reduce((a, b) => a > b ? a : b);
    final connectorTypes = connectors
        .map((c) => c.rawType ?? c.type.label)
        .toSet()
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.ev_station, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (operatorName.isNotEmpty)
                      Text(
                        operatorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EvDetailColumn(
                maxPowerKw: maxPower,
                available: available,
                total: total,
                connectorTypes: connectorTypes,
                availableLabel:
                    l10n?.evStatusAvailable ?? 'available',
                onFavoriteTap: onFavoriteTap,
                removeFavoriteTooltip:
                    l10n?.removeFavorite ?? 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// #2143 — Right-side detail column for [EvFavoriteCard]. Mirrors the
/// layout of `_StationPriceColumn` (big headline + star, then detail
/// rows) but swaps the price for the station's max-power kW and uses
/// the crystal-blue accent.
class _EvDetailColumn extends StatelessWidget {
  final double maxPowerKw;
  final int available;
  final int total;
  final List<String> connectorTypes;
  final String availableLabel;
  final VoidCallback? onFavoriteTap;
  final String removeFavoriteTooltip;

  const _EvDetailColumn({
    required this.maxPowerKw,
    required this.available,
    required this.total,
    required this.connectorTypes,
    required this.availableLabel,
    required this.onFavoriteTap,
    required this.removeFavoriteTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.bolt,
              size: 16,
              color: EvFavoriteCard.crystalBlue,
            ),
            const SizedBox(width: 2),
            Text(
              '${maxPowerKw.round()} kW',
              style: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: EvFavoriteCard.crystalBlue,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.star, color: Colors.amber, size: 22),
                onPressed: onFavoriteTap,
                tooltip: removeFavoriteTooltip,
              ),
            ),
          ],
        ),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.power,
                  size: 12,
                  color: available > 0
                      ? DarkModeColors.success(context)
                      : Colors.grey,
                ),
                const SizedBox(width: 3),
                Text(
                  '$available/$total $availableLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: available > 0
                        ? DarkModeColors.success(context)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        if (connectorTypes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              connectorTypes.join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
