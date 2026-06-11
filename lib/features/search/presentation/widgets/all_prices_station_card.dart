// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../core/widgets/station_card_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../station_detail/presentation/widgets/station_brand_helpers.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';

part 'all_prices_station_card_parts.dart';

/// A detailed station card that shows ALL available fuel prices.
///
/// Designed for the all-prices list view, similar to Essence&Co.
/// Shows station name, address, distance, status, and color-coded
/// badges for every available fuel type with prices.
class AllPricesStationCard extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final Map<FuelType, bool> cheapestFlags;

  /// The user's preferred fuel type from their profile.
  /// When provided, the matching fuel badge is rendered larger and with a
  /// thicker border to make it visually dominant.
  final FuelType? profileFuelType;

  const AllPricesStationCard({
    super.key,
    required this.station,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.cheapestFlags = const {},
    this.profileFuelType,
  });

  /// Defers to the shared [hasRealBrand] helper so the search card and
  /// the detail screen agree on what counts as a brand (#2061). The
  /// helper excludes the legacy `'Station'` sentinel and
  /// `BrandRegistry.independentLabel` (`'Independent'` from #482).
  /// `'Autoroute'` is a synthetic motorway tag, not a real brand, so
  /// the card keeps that exclusion on top.
  bool get _hasBrand => hasRealBrand(station) && station.brand != 'Autoroute';

  /// #3198 — tri-state status colour: green when known-open, red when
  /// known-closed, neutral muted when the source gave no signal.
  Color _statusColor(BuildContext context) => switch (station.isOpen) {
        true => DarkModeColors.success(context),
        false => DarkModeColors.error(context),
        null => DarkModeColors.mutedText(context),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #2493 — shared frame via [StationCardShell]. This card carries no
    // accent stripe (its colour lives in the per-fuel badges), so
    // `stripeColor` is left null. The leading status dot is 12px to match
    // the shared grammar used by the other three cards.
    return StationCardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: status dot + name + distance + favorite
            Row(
              children: [
                // Status indicator — #3198 tri-state: unknown renders the
                // neutral muted dot, never the red "closed" one.
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                // Station name
                Expanded(
                  child: Text(
                    _hasBrand ? station.brand : station.street,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status badge — #3198 tri-state (Open / Closed / Unknown).
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    switch (station.isOpen) {
                      true => l10n?.open ?? 'Open',
                      false => l10n?.closed ?? 'Closed',
                      null => l10n?.openStateUnknown ?? 'Unknown',
                    },
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Favorite button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : null,
                    ),
                    // #2974 — selection tick on the favourite toggle (the same
                    // everyday tap haptic as the compact card). selectionClick
                    // only; fires only on the discrete star tap, never scroll.
                    onPressed: onFavoriteTap == null
                        ? null
                        : () {
                            unawaited(HapticFeedback.selectionClick());
                            onFavoriteTap!();
                          },
                    tooltip: isFavorite
                        ? (l10n?.removeFavorite ?? 'Remove from favorites')
                        : (l10n?.addFavorite ?? 'Add to favorites'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Address + distance row
            Row(
              children: [
                const SizedBox(width: 18), // Align with name
                Expanded(
                  child: Text(
                    _hasBrand
                        ? '${station.street}, ${station.postCode} ${station.place}'
                        : '${station.postCode} ${station.place}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  PriceFormatter.formatDistance(station.dist),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Fuel price badges
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _buildFuelBadges(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFuelBadges(BuildContext context) {
    final badges = <Widget>[];

    // #2717 — resolve the station's country so Mexican (mx-) stations show
    // PEMEX grade names (Magna/Premium); every other country falls through
    // to the language-neutral fuel code unchanged.
    final cc = Countries.countryCodeForStationId(station.id);

    final fuelEntries = <(FuelType, double?, String)>[
      (FuelType.e5, station.e5, fuelDisplayLabel(FuelType.e5, countryCode: cc)),
      (FuelType.e10, station.e10,
          fuelDisplayLabel(FuelType.e10, countryCode: cc)),
      (FuelType.e98, station.e98,
          fuelDisplayLabel(FuelType.e98, countryCode: cc)),
      (FuelType.diesel, station.diesel,
          fuelDisplayLabel(FuelType.diesel, countryCode: cc)),
      (FuelType.dieselPremium, station.dieselPremium,
          fuelDisplayLabel(FuelType.dieselPremium, countryCode: cc)),
      (FuelType.e85, station.e85,
          fuelDisplayLabel(FuelType.e85, countryCode: cc)),
      (FuelType.lpg, station.lpg,
          fuelDisplayLabel(FuelType.lpg, countryCode: cc)),
      (FuelType.cng, station.cng,
          fuelDisplayLabel(FuelType.cng, countryCode: cc)),
    ];

    for (final (fuelType, price, label) in fuelEntries) {
      // Only show fuels that are available or explicitly listed as unavailable
      final isUnavailable = station.unavailableFuels.contains(
        fuelType.apiValue,
      );
      if (price == null && !isUnavailable) continue;

      badges.add(
        _FuelBadge(
          label: label,
          price: price,
          fuelType: fuelType,
          isUnavailable: isUnavailable,
          isCheapest: cheapestFlags[fuelType] ?? false,
          isProfileFuel:
              profileFuelType != null &&
              profileFuelType!.apiValue == fuelType.apiValue,
        ),
      );
    }

    return badges;
  }
}
