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
            Text(
              '${l10n?.searchRadius ?? "Radius"}:',
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              '${radiusKm.round()} km',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        Slider(
          value: radiusKm.clamp(minKm, maxKm),
          min: minKm,
          max: maxKm,
          divisions: divisions,
          label: '${radiusKm.round()} km',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
