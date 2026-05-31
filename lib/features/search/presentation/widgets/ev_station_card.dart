// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/station_card_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/ev_price.dart';
import '../../domain/entities/search_result_item.dart';
import 'ev_connector_chips.dart';

class EVStationCard extends StatelessWidget {
  final EVStationResult result;
  final VoidCallback? onTap;

  /// Whether this charging station is favourited (#1896). When
  /// [onFavoriteTap] is non-null the card renders a favourite star,
  /// matching the fuel result cards.
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const EVStationCard({
    super.key,
    required this.result,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final station = result.station;
    final maxPower = result.maxPowerKW;
    final connectors = result.connectorTypes;

    // #1785 — show a structured per-kWh / per-session price; free and
    // unclassifiable `usageCost` strings degrade to the raw value.
    final evPrice = EvPrice.parse(station.usageCost);
    final priceLabel =
        evPrice.label(
          perKwhUnit: l10n?.refuelUnitPerKwh ?? '/kWh',
          perSessionUnit: l10n?.refuelUnitPerSession ?? '/session',
        ) ??
        station.usageCost;

    // #2493 — shared frame via [StationCardShell]; the EV accent (stripe,
    // ev-station glyph, kW headline, price label) is the single canonical
    // [FuelColors.evAccent] crystal-blue, replacing the old teal `#009688`
    // + muted-teal `FuelType.electric` stripe divergence.
    return StationCardShell(
      onTap: onTap,
      stripeColor: FuelColors.evAccent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Status indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: station.isOperational == true
                        ? DarkModeColors.success(context)
                        : DarkModeColors.warning(context),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.ev_station,
                    size: 14,
                    color: FuelColors.evAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Station info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (station.operator?.isNotEmpty ?? false)
                        ? station.operator!
                        : station.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if ((station.address ?? '').isNotEmpty)
                    Text(
                      station.address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${station.postCode ?? ''} ${station.place ?? ''}'.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        PriceFormatter.formatDistance(station.dist),
                        style: theme.textTheme.bodySmall,
                      ),
                      if (priceLabel != null && priceLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            priceLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: FuelColors.evAccent,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Power + connectors
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Max power
                Text(
                  maxPower > 0 ? '${maxPower.round()} kW' : '--',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FuelColors.evAccent,
                  ),
                ),
                const SizedBox(height: 4),
                // Connector type chips
                EvConnectorChips(connectors: connectors),
              ],
            ),
            // #1896 — favourite star, matching the fuel result cards.
            if (onFavoriteTap != null)
              IconButton(
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                color: isFavorite ? DarkModeColors.warning(context) : null,
                tooltip: l10n?.favorites ?? 'Favorites',
                visualDensity: VisualDensity.compact,
                onPressed: onFavoriteTap,
              ),
          ],
        ),
      ),
    );
  }
}
