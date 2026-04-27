import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Destructive-action confirmation dialog for the η_v calibration
/// reset (#815). The caller decides what to do with the returned
/// bool — this widget only asks the user.
class VeResetConfirmDialog {
  VeResetConfirmDialog._();

  /// Returns `true` only when the user explicitly taps the reset
  /// action. Cancel / barrier dismiss / back-button all return
  /// `null`, which callers should treat as "do nothing".
  static Future<bool?> show(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l?.veResetConfirmTitle ?? 'Reset volumetric efficiency?',
        ),
        content: Text(
          l?.veResetConfirmBody ??
              'This will discard the learned per-vehicle calibration '
                  'and restore the default value (0.85).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l?.veResetAction ?? 'Reset volumetric efficiency',
            ),
          ),
        ],
      ),
    );
  }
}
