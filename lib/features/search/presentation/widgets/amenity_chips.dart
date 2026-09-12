// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_pill.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station_amenity.dart';
import '../../../../core/widgets/amenity_labels.dart';

/// Displays station amenities as compact icon chips.
///
/// Shows each amenity as a small chip with an icon and short label.
/// Designed to fit in tight spaces like station cards and detail headers.
class AmenityChips extends StatelessWidget {
  final Set<StationAmenity> amenities;

  /// Maximum number of chips to display. Extra amenities show a "+N" chip.
  final int maxVisible;

  const AmenityChips({super.key, required this.amenities, this.maxVisible = 4});

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final sorted = amenities.toList();
    final visible = sorted.take(maxVisible).toList();
    final overflow = sorted.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...visible.map(
          (a) => AppPill(icon: amenityIcon(a), label: _localizedLabel(a, l10n)),
        ),
        // #2622 — make the "+N" overflow pill meaningful: a tooltip +
        // accessibility label spell out the hidden amenities by localized
        // name so the count is no longer opaque.
        if (overflow > 0)
          Builder(
            builder: (_) {
              final hiddenNames = sorted
                  .skip(maxVisible)
                  .map((a) => _localizedLabel(a, l10n))
                  .join(', ');
              final message = l10n.amenityMoreTooltip(hiddenNames);
              return Tooltip(
                message: message,
                child: Semantics(
                  label: message,
                  child: AppPill(label: '+$overflow'),
                ),
              );
            },
          ),
      ],
    );
  }

  String _localizedLabel(StationAmenity a, AppLocalizations l10n) =>
      localizedAmenityLabel(a, l10n);
}
