import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Safety disclaimer shown on first activation of driving mode.
///
/// The user must acknowledge the disclaimer before entering driving mode.
class SafetyDisclaimerDialog extends StatelessWidget {
  const SafetyDisclaimerDialog({super.key});

  /// Shows the safety disclaimer and returns true if the user accepted.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SafetyDisclaimerDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 48,
        color: theme.colorScheme.error,
      ),
      title: Text(l10n?.drivingSafetyTitle ?? 'Safety Notice'),
      content: Text(
        l10n?.drivingSafetyMessage ??
            'Do not operate the app while driving. '
                'Pull over to a safe location before interacting with the screen. '
                'The driver is responsible for safe operation of the vehicle at all times.',
        style: theme.textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n?.drivingSafetyAccept ?? 'I understand'),
        ),
      ],
    );
  }
}
