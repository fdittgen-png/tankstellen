// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/station_card_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../station_detail/presentation/widgets/station_brand_helpers.dart';
import '../../providers/all_prices_comparison_model.dart';
import '../../providers/all_prices_table_provider.dart';
import 'all_prices/fuel_comparison_table.dart';

part 'all_prices_station_card_parts.dart';

/// The all-prices station card — a fuel COMPARISON TABLE (#3933,
/// Epic #3925), not a bag of chips.
///
/// The compact list already answers *"where do I fill up my fuel?"*. This
/// card owns the question nothing else can answer: *which fuel, at which
/// station, actually costs me least per 100 km*. So it renders fixed fuel
/// columns in a list-wide stable order (empty cell where the station lacks
/// a grade — never a reflow), each cell carrying the pump price, its delta
/// against the cheapest of the current results, and the cost of 100 km on
/// that fuel for the active vehicle. A verdict line names the winning fuel
/// here and flags the station when it wins the results outright.
///
/// ## No new constructor parameters (the #3933 data seam)
/// `search_results_list.dart` belongs to the sibling #3926 work, so every
/// list-wide input is READ FROM PROVIDERS
/// (`all_prices_table_provider.dart`) rather than threaded in. The legacy
/// [cheapestFlags] / [profileFuelType] arguments are kept exactly as they
/// were — they now act as the fallback for callers that render this card
/// outside a live search (route results, tests).
///
/// ## Degradation
/// With no vehicle or no consumption history the per-100 km number and the
/// verdict disappear on their own (they are null in the model) and the
/// card degrades to an aligned price table with deltas.
class AllPricesStationCard extends ConsumerWidget {
  final Station station;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  /// Legacy per-fuel "cheapest in the visible results" flags. Used only
  /// when [allPricesBestByFuelProvider] has nothing to say (no live search
  /// behind this card) — a flagged fuel then reads as its own reference,
  /// i.e. emphasised with a zero delta.
  final Map<FuelType, bool> cheapestFlags;

  /// The user's preferred fuel from their profile. Used as the fallback
  /// source of "what can this driver actually put in the tank" when no
  /// vehicle profile is active, so cells outside the family still dim.
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
  Widget build(BuildContext context, WidgetRef ref) {
    // #2493 — shared frame via [StationCardShell]. This card carries no
    // accent stripe (its colour lives in the per-fuel cells), so
    // `stripeColor` is left null.
    return StationCardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AllPricesCardHeader(
              station: station,
              title: _hasBrand ? station.brand : station.street,
              statusColor: _statusColor(context),
              isFavorite: isFavorite,
              onFavoriteTap: onFavoriteTap,
            ),
            const SizedBox(height: 2),
            _AllPricesCardAddress(
              address: _hasBrand
                  ? '${station.street}, ${station.postCode} ${station.place}'
                  : '${station.postCode} ${station.place}',
              distanceKm: station.dist,
            ),
            const SizedBox(height: 6),
            FuelComparisonTable(
              comparison: _comparison(ref),
              consumptionUnit: ref
                  .watch(consumptionDisplaySettingProvider)
                  .unit,
            ),
          ],
        ),
      ),
    );
  }

  /// Resolve this station's row against the list-wide column set, best
  /// prices and cost model — falling back to the station's own priced
  /// fuels + [cheapestFlags] when no live search backs the card.
  StationFuelComparison _comparison(WidgetRef ref) {
    final listColumns = ref.watch(allPricesColumnsProvider);
    final columns = listColumns.visible.isEmpty
        ? fallbackColumnsForStation(station)
        : listColumns;

    final listBest = ref.watch(allPricesBestByFuelProvider);
    final best = listBest.isNotEmpty ? listBest : _bestFromFlags();

    final costModel = ref.watch(allPricesFuelCostModelProvider);
    final usable = costModel.usableFuels.isNotEmpty
        ? costModel.usableFuels
        : _familyOf(profileFuelType);

    return buildStationComparison(
      station: station,
      columns: columns,
      bestByFuel: best,
      litersPer100kmByFuel: costModel.litersPer100kmByFuel,
      usableFuels: usable,
      // #2717 — Mexican (mx-) stations render PEMEX grade names.
      countryCode: Countries.countryCodeForStationId(station.id),
    );
  }

  /// The legacy flags re-expressed as a best-price map: a flagged fuel is
  /// its own reference, so it renders emphasised with a zero delta and
  /// every other cell simply has no delta to show.
  Map<FuelType, double> _bestFromFlags() {
    final best = <FuelType, double>{};
    for (final entry in cheapestFlags.entries) {
      if (!entry.value) continue;
      final price = station.priceFor(entry.key);
      if (price != null && price > 0) best[entry.key] = price;
    }
    return best;
  }

  /// The compatibility family of [fuel] — what a driver on that fuel can
  /// physically pump. Empty for a null / wildcard fuel, which means "dim
  /// nothing".
  Set<FuelType> _familyOf(FuelType? fuel) =>
      (fuel == null || fuel == FuelType.all)
      ? const <FuelType>{}
      : compatibleFuelsFor(fuel).toSet();
}
