import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Outcome of the fill-up variance prompt (#1401 phase 7b).
///
/// Returned by [showFillUpVarianceDialog] to the save flow so the
/// caller can decide what value to persist:
/// - [keepUser]: keep the litres the user typed (or the dialog was
///   dismissed — same effect).
/// - [useAdapter]: replace the user-entered litres with the adapter-
///   derived delta `(after - before)`.
enum FillUpVarianceChoice { keepUser, useAdapter }

/// Shows the "Doesn't match adapter reading" confirmation dialog
/// (#1401 phase 7b). Pre-formatted [userL] / [adapterL] strings are
/// passed through verbatim — callers control the locale-aware
/// formatting (decimal separator, precision) before calling.
///
/// Returns the user's choice. A dismiss (tapping the scrim or the
/// back button) resolves to [FillUpVarianceChoice.keepUser]; the
/// caller's save flow proceeds with the user's value when it sees
/// either `keepUser` or no override.
Future<FillUpVarianceChoice> showFillUpVarianceDialog({
  required BuildContext context,
  required String userL,
  required String adapterL,
}) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<FillUpVarianceChoice>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          l?.fillUpReconciliationVarianceDialogTitle ??
              "Doesn't match adapter reading",
        ),
        content: Text(
          l?.fillUpReconciliationVarianceDialogBody(userL, adapterL) ??
              'Your entry: $userL L. Adapter says: $adapterL L (delta from '
                  'before/after fuel-level capture). Use adapter value?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              FillUpVarianceChoice.keepUser,
            ),
            child: Text(
              l?.fillUpReconciliationVarianceDialogKeepMine ??
                  'Keep my entry',
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              FillUpVarianceChoice.useAdapter,
            ),
            child: Text(
              l?.fillUpReconciliationVarianceDialogUseAdapter ??
                  'Use adapter value',
            ),
          ),
        ],
      );
    },
  );
  return result ?? FillUpVarianceChoice.keepUser;
}
