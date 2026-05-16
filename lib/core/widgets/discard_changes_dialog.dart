import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Confirm dialog shown when the user tries to leave a form that has
/// unsaved changes (#1693 — Forms & Input UX).
///
/// Returns `true` when the user chooses to discard and leave, `false`
/// when they dismiss the dialog or choose to keep editing. Callers
/// pair this with a `PopScope` (`canPop: !isDirty`) so the system back
/// gesture and an explicit close button both route through it.
Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l?.discardChangesTitle ?? 'Discard changes?'),
      content: Text(
        l?.discardChangesBody ??
            'You have unsaved changes. Leaving now will discard them.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l?.discardChangesKeepEditing ?? 'Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l?.discardChangesConfirm ?? 'Discard'),
        ),
      ],
    ),
  );
  return result ?? false;
}
