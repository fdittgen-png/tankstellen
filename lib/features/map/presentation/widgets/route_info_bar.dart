// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact info bar showing route distance, duration, station count, and action buttons.
class RouteInfoBar extends StatelessWidget {
  final double distanceKm;
  final double durationMinutes;
  final String stationCountLabel;
  final VoidCallback onSaveRoute;
  final VoidCallback onOpenInMaps;

  const RouteInfoBar({
    super.key,
    required this.distanceKm,
    required this.durationMinutes,
    required this.stationCountLabel,
    required this.onSaveRoute,
    required this.onOpenInMaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.route, size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            // #3982 - the distance follows the country's unit and the
            // duration's abbreviation comes from ARB, as everywhere else
            // since #3993.
            '${UnitFormatter.formatDistance(distanceKm, fractionDigits: 0)}'
            ' \u00b7 ${formatTravelDuration(l10n, durationMinutes)}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(stationCountLabel, style: theme.textTheme.labelSmall),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.bookmark_add, size: 14),
            tooltip: l10n.saveRoute,
            onPressed: onSaveRoute,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            iconSize: 14,
          ),
          IconButton(
            icon: const Icon(Icons.navigation, size: 14),
            tooltip: l10n.openInMaps,
            onPressed: onOpenInMaps,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            iconSize: 14,
          ),
        ],
      ),
    );
  }
}
