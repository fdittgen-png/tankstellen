import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Small text badge ("(detected)" / "(détecté)") shown beneath a
/// vehicle profile field when its current value matches the
/// corresponding `detectedX` field on the [VehicleProfile] (#1399).
///
/// Renders nothing (`SizedBox.shrink`) when [show] is false so callers
/// can drop the widget into their layout unconditionally and let the
/// boolean drive visibility — keeps the call sites visually clean.
class DetectedFromVinBadge extends StatelessWidget {
  /// Whether to render the badge. False collapses the widget to an
  /// empty box.
  final bool show;

  const DetectedFromVinBadge({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        l?.vehicleDetectedFromVinBadge ?? '(detected)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
