import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Join existing database step: QR scan or manual URL+key entry.
class WizardJoinExisting extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController keyController;
  final Widget keyField;
  final VoidCallback onScanQr;
  final VoidCallback? onContinue;

  const WizardJoinExisting({
    super.key,
    required this.urlController,
    required this.keyController,
    required this.keyField,
    required this.onScanQr,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            l10n?.syncWizardJoinExistingTitle ?? 'Join an existing database',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // QR Scanner
        FilledButton.icon(
          onPressed: onScanQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l10n?.syncWizardScanQrCode ?? 'Scan QR Code'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.syncWizardAskOwnerQr ??
              'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n?.syncOrDivider ?? 'or')),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 24),

        // Manual entry
        Text(l10n?.syncWizardEnterManuallyTitle ?? 'Enter manually',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          decoration: InputDecoration(
            labelText: l10n?.syncWizardSupabaseUrlLabel ?? 'Supabase URL',
            hintText: l10n?.syncWizardSupabaseUrlHint ??
                'https://your-project.supabase.co',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
            helperText: l10n?.syncWizardUrlHelperText ??
                'Whitespace and line breaks removed automatically',
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        keyField,
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onContinue,
          child: Text(l10n?.continueButton ?? 'Continue'),
        ),
      ],
    );
  }
}
