import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Profile-edit slider for the user's preferred default search radius
/// (1–25 km). Renders a "Radius:" label, the [Slider] itself, and a
/// trailing "X km" readout that mirrors the current value.
///
/// Pulled out of `profile_edit_sheet.dart` so the sheet's `build` method
/// drops the inline `Row` block and so the slider's range, division
/// count, and value mirroring can be exercised by widget tests in
/// isolation.
class ProfileRadiusSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const ProfileRadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text('${l10n?.defaultRadius ?? "Radius"}:'),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 25,
            divisions: 24,
            label: '${value.round()} km',
            onChanged: onChanged,
          ),
        ),
        Text('${value.round()} km'),
      ],
    );
  }
}
