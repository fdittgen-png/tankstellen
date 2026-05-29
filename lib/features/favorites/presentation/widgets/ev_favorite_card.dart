// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_station.dart';

/// Card for an EV charging station in the favorites list.
///
/// Uses the canonical [ChargingStation] type (unified in #560) with
/// the typed [EvConnector] instead of the previous free-form search
/// side [Connector].
///
/// #2229 — shares the fuel `StationCard`'s frame (margins, elevation,
/// shape, leading status dot, title/operator/distance block, right
/// detail column) so both favorite cards have one silhouette; the only
/// visual difference is the left accent stripe — [crystalBlue] here vs
/// the grey `FuelType.all` stripe on fuel cards.
class EvFavoriteCard extends StatelessWidget {
  /// Crystal-blue accent (#2143) — cool, glassy, distinct from the
  /// muted-teal `FuelTypeElectric` (#3B8079). Used for both the kW
  /// headline and (since #2229) the left accent stripe that marks the
  /// card as EV, without borrowing the fuel palette.
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

    final availableLabel = l10n?.evStatusAvailable ?? 'available';
    // Screen-reader parity with the fuel card's semantic label: the
    // visual cards are intentionally identical except for the marker
    // colour (#2229), so a11y leans on this label to convey "EV".
    final semanticLabel = [
      station.name,
      if (operatorName.isNotEmpty) operatorName,
      '${maxPower.round()} kW',
      '$available/$total $availableLabel',
    ].join(', ');

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Card(
        // #2229 — same frame as the fuel `StationCard` so both favorite
        // cards share one silhouette; the only difference is the left
        // accent stripe colour (blue here vs grey for FuelType.all fuel
        // cards).
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        clipBehavior: Clip.antiAlias,
        elevation: theme.brightness == Brightness.dark ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: crystalBlue, width: 4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _EvStatusDot(available: available),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        station.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (operatorName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          operatorName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (station.dist > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          PriceFormatter.formatDistance(station.dist),
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _EvDetailColumn(
                  maxPowerKw: maxPower,
                  available: available,
                  total: total,
                  connectorTypes: connectorTypes,
                  availableLabel: availableLabel,
                  onFavoriteTap: onFavoriteTap,
                  removeFavoriteTooltip:
                      l10n?.removeFavorite ?? 'Remove from favorites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Leading availability dot — green when at least one connector is free,
/// grey otherwise. Mirrors the fuel `StationCard`'s `_StatusColumn` dot
/// so the two favorite cards share an identical leading silhouette
/// (#2229).
class _EvStatusDot extends StatelessWidget {
  final int available;

  const _EvStatusDot({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: available > 0 ? DarkModeColors.success(context) : Colors.grey,
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
