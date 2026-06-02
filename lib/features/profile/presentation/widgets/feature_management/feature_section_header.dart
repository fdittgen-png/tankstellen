// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/domain/feature_category.dart';

/// Section header for one [FeatureCategory] in the Feature management
/// screen (#2681). Renders a bold titleMedium title above a bodySmall
/// subtitle, mirroring the heading at the top of the Conso card so the
/// category sections read as one consistent hierarchy.
///
/// All copy comes from `AppLocalizations` (HARD RULE #1); the inline
/// fallbacks only fire in test fixtures that supply a null localisations
/// object.
class FeatureSectionHeader extends StatelessWidget {
  final FeatureCategory category;

  const FeatureSectionHeader({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      key: Key('featureSectionHeader_${category.name}'),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(l, category),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _subtitle(l, category),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _title(AppLocalizations? l, FeatureCategory c) {
    switch (c) {
      case FeatureCategory.finding:
        return l?.featureGroupTitle_finding ?? 'Finding & map';
      case FeatureCategory.prices:
        return l?.featureGroupTitle_prices ?? 'Prices & alerts';
      case FeatureCategory.radar:
        return l?.featureGroupTitle_radar ?? 'Fuel Station Radar';
      case FeatureCategory.consumption:
        // The consumption section reuses the renamed Conso group title.
        return l?.consoFeatureGroupTitle ?? 'Consumption';
      case FeatureCategory.sync:
        return l?.featureGroupTitle_sync ?? 'Sync & backup';
      case FeatureCategory.input:
        return l?.featureGroupTitle_input ?? 'Input & scanning';
      case FeatureCategory.developer:
        return l?.featureGroupTitle_developer ?? 'Developer & experimental';
    }
  }

  String _subtitle(AppLocalizations? l, FeatureCategory c) {
    switch (c) {
      case FeatureCategory.finding:
        return l?.featureGroupDescription_finding ??
            'Where to fuel up or charge — search, map, routing.';
      case FeatureCategory.prices:
        return l?.featureGroupDescription_prices ??
            'Price drops, history, and reporting.';
      case FeatureCategory.radar:
        return l?.featureGroupDescription_radar ??
            'Live price nudges as you drive.';
      case FeatureCategory.consumption:
        // The consumption section reuses the renamed Conso group subtitle.
        return l?.consoFeatureGroupDescription ??
            'Track your consumption — manual fill-ups, or '
                'automatic OBD2 trip recording.';
      case FeatureCategory.sync:
        return l?.featureGroupDescription_sync ??
            'Keep your data across devices.';
      case FeatureCategory.input:
        return l?.featureGroupDescription_input ??
            'Helpers for logging fill-ups.';
      case FeatureCategory.developer:
        return l?.featureGroupDescription_developer ??
            'Power-user and contributor tools.';
    }
  }
}
