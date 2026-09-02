// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/domain/brand_appearance.dart';
import '../../../../core/domain/brand_registry.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/ev/charging_station.dart';

/// Header card showing status, name, and operator for an EV station.
///
/// #3931 — the trailing glyph used to be the same `Icons.ev_station` for
/// every charging point in the country, so a list of Ionity, Fastned and
/// Allego sites all read identically. It is now the network's own mark:
/// the OpenChargeMap operator title, canonicalised through
/// [BrandRegistry] so every spelling of a network lands on one colour,
/// and falling back to the raw title and then to the neutral charging
/// tile. The operator text line below is unchanged — the mark is a
/// recognition aid, not a replacement for the name.
class EVStationHeaderCard extends StatelessWidget {
  final ChargingStation station;
  final Color evColor;

  const EVStationHeaderCard({
    super.key,
    required this.station,
    required this.evColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final operatorName = station.operator ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: station.isOperational == true
                        ? DarkModeColors.success(context)
                        : DarkModeColors.warning(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  station.isOperational == true
                      ? (l10n.evOperational)
                      : (l10n.evStatusUnknown),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: station.isOperational == true
                        ? DarkModeColors.success(context)
                        : DarkModeColors.warning(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                BrandLogo(
                  brand: BrandRegistry.canonicalize(operatorName) ??
                      operatorName,
                  kind: BrandKind.ev,
                  size: 36,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              station.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (operatorName.isNotEmpty && operatorName != station.name)
              Text(
                operatorName,
                style: theme.textTheme.titleMedium?.copyWith(color: evColor),
              ),
          ],
        ),
      ),
    );
  }
}
