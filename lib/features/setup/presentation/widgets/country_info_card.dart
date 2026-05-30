// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/country/country_config.dart';
import '../../../../l10n/app_localizations.dart';
import 'country_status_badge.dart';

/// Setup screen card summarising a [CountryConfig]: flag, name, API data
/// source, the API-key requirement badge, and the supported fuel types.
/// Pulled out of `setup_screen.dart` so the screen no longer carries this
/// 60-line widget block and so the semantics envelope (which announces
/// the entire card as a single sentence to screen readers, instead of
/// reading each detail) can be exercised by widget tests in isolation.
class CountryInfoCard extends StatelessWidget {
  final CountryConfig country;

  const CountryInfoCard({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dataSource =
        country.apiProvider ?? (l10n?.countryInfoDemoSource ?? 'Demo');
    final keyRequirement = country.requiresApiKey
        ? (l10n?.countryInfoApiKeyRequired ?? 'API key required')
        : (l10n?.countryInfoNoKeyNeeded ?? 'Free, no key needed');
    final fuelTypesList = country.fuelTypes.join(', ');
    final semanticLabel = l10n?.countryInfoSemantic(
          country.name,
          dataSource,
          keyRequirement,
          fuelTypesList,
        ) ??
        '${country.name}, data source: $dataSource, $keyRequirement, '
            'fuel types: $fuelTypesList';
    return Semantics(
      label: semanticLabel,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            country.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n?.countryInfoDataSource(dataSource) ??
                                'Data: $dataSource',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  CountryStatusBadge(country: country),
                ],
              ),
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  l10n?.countryInfoFuelTypes(fuelTypesList) ??
                      'Fuel types: $fuelTypesList',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
