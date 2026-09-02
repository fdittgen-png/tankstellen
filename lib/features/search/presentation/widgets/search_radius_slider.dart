// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Title row + slider for the search radius (km). Pulled out of
/// `search_criteria_screen.dart` so the screen's `build` method stays
/// readable and the slider can be exercised in isolation by widget tests.
///
/// #3927 — a slider alone makes the four radii people actually use a
/// drag-and-squint exercise, so the common values are also one tap away
/// as preset chips under the track. Presets outside `[minKm, maxKm]` are
/// not offered: `SearchRadius.set` clamps to 25 km, so a 50 km chip would
/// silently land on 25 and lie about what it did.
class SearchRadiusSlider extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;
  final double minKm;
  final double maxKm;

  /// The radii offered as one-tap chips, filtered to the slider's range.
  static const List<int> presetsKm = [5, 10, 25, 50];

  const SearchRadiusSlider({
    super.key,
    required this.radiusKm,
    required this.onChanged,
    this.minKm = 1,
    this.maxKm = 25,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final divisions = (maxKm - minKm).round();
    final rounded = radiusKm.round();
    final presets = presetsKm
        .where((km) => km >= minKm && km <= maxKm)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.searchRadius}:', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text('$rounded km', style: theme.textTheme.titleSmall),
          ],
        ),
        // #1962 — shrink the slider's reaction overlay so the control
        // takes far less vertical space in the compact criteria form
        // (the default 24 dp overlay inflates the row to ~48 dp).
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: radiusKm.clamp(minKm, maxKm),
            min: minKm,
            max: maxKm,
            divisions: divisions,
            label: '$rounded km',
            onChanged: onChanged,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final km in presets)
              ChoiceChip(
                key: ValueKey('criteria-radius-preset-$km'),
                label: Text('$km km'),
                selected: rounded == km,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onChanged(km.toDouble()),
              ),
          ],
        ),
      ],
    );
  }
}
