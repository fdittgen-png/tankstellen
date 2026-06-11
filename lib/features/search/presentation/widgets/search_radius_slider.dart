// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Title row + slider for the search radius (km). Pulled out of
/// `search_criteria_screen.dart` so the screen's `build` method stays
/// readable and the slider can be exercised in isolation by widget tests.
class SearchRadiusSlider extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;
  final double minKm;
  final double maxKm;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.searchRadius}:', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text('${radiusKm.round()} km', style: theme.textTheme.titleSmall),
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
            label: '${radiusKm.round()} km',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
