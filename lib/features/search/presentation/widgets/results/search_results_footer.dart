// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/country/country_config.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/radar_search_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/search_screen_ui_provider.dart';
import '../demo_mode_banner.dart';

/// The footer under the results list (#3926).
///
/// Two things moved down here so the top of the screen could shrink to two
/// rows:
///
///  * the **price-arrow legend**. The ↓ / – / ↑ glyph beside each card
///    price is NOT a time trend — `priceTierOf()` classifies the price
///    inside the CURRENT result set (bottom / middle / top third of the
///    listed stations' price range for the selected fuel), so the legend is
///    worded against this list, not against yesterday.
///  * the **open-data attribution** ("🇫🇷 France — Prix-Carburants
///    (gouv.fr) ↗"), which was the first of six stacked chrome strips above
///    the first station card. The CC BY / Licence Ouverte / OGL / IODL
///    licences mandate a *visible* credit, not a specific position, so it
///    is rendered as a pinned footer row (never scrolled away) rather than
///    as a list item.
///
/// The demo-mode MaterialBanner branch of [DemoModeBanner] stays at the top
/// of the screen — it is a call to action ("turn on live prices"), not an
/// attribution — so this footer renders the banner only in its attribution
/// branches.
class SearchResultsFooter extends ConsumerWidget {
  const SearchResultsFooter({
    super.key,
    required this.country,
    required this.corridorCountryCodes,
  });

  final CountryConfig country;

  /// #2622 — every country a cross-border route search actually queried.
  final Set<String> corridorCountryCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showsAttribution =
        corridorCountryCodes.length > 1 || !country.requiresApiKey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PriceArrowLegend(),
        if (showsAttribution)
          DemoModeBanner(
            country: country,
            corridorCountryCodes: corridorCountryCodes,
          ),
      ],
    );
  }
}

/// One line explaining the card price arrows. Rendered only when arrows can
/// actually appear: the compact card view (the all-prices view has no tier
/// glyph) with at least two stations to compare.
class _PriceArrowLegend extends ConsumerWidget {
  const _PriceArrowLegend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(allPricesViewEnabledProvider)) {
      return const SizedBox.shrink();
    }
    final radarActive = ref.watch(radarSearchProvider.select((s) => s.active));
    final count = radarActive
        ? ref.watch(
            radarSearchProvider.select((s) => s.stations.value?.length ?? 0),
          )
        : ref.watch(
            searchStateProvider.select((s) => s.value?.data.length ?? 0),
          );
    if (count < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      key: const Key('price_arrow_legend'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Text(
        AppLocalizations.of(context).searchPriceArrowLegend,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
