// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../country/country_provider.dart';
import '../../theme/dark_mode_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../country_service_registry.dart';

/// Small, non-intrusive footer crediting the active country's upstream
/// fuel-price provider (#2270, child of Epic #2249).
///
/// Several of the open-data sources we consume require **visible** attribution
/// — Tankerkönig (CC BY 4.0), France Prix Carburants (Licence Ouverte 2.0),
/// the UK CMA feeds (Open Government Licence v3.0), Italy's MIMIT
/// osservaprezzi (IODL 2.0). The provider name + licence are recorded as data
/// on each country's [FuelServicePolicy]; this widget renders the required
/// credit line for whichever country is currently active.
///
/// The `Source:` label is localised; the provider and licence names are
/// rendered verbatim from the policy (they are proper nouns / licence
/// identifiers, not translatable strings).
///
/// Renders [SizedBox.shrink] when the active country has no registered policy
/// (e.g. the demo / unsupported-country fallback), so it never shows an empty
/// or half-filled credit.
class DataSourceAttribution extends ConsumerWidget {
  const DataSourceAttribution({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(activeCountryProvider);
    final policy = CountryServiceRegistry.policyFor(country.code);
    if (policy == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Source + licence names are data (proper nouns / licence ids), not ARB.
    final source = policy.attribution; // i18n-ignore: data source name
    final license = policy.license; // i18n-ignore: data licence name

    final label = l10n?.dataSourceAttribution(source, license) ??
        'Source: $source ($license)';
    final semanticLabel =
        l10n?.dataSourceAttributionSemantic(source, license) ??
            'Fuel price data provided by $source, licensed under $license.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 12,
            color: DarkModeColors.mutedText(context),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              semanticsLabel: semanticLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DarkModeColors.mutedText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
