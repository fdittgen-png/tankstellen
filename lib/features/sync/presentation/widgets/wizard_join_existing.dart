// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
          l10n.syncWizardJoinExistingTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // QR Scanner
        FilledButton.icon(
          onPressed: onScanQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(l10n.syncWizardScanQrCode),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.syncWizardAskOwnerQr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.syncOrDivider),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),

        // Manual entry
        Text(
          l10n.syncWizardEnterManuallyTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: urlController,
          decoration: InputDecoration(
            labelText: l10n.syncWizardSupabaseUrlLabel,
            hintText: l10n.syncWizardSupabaseUrlHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
            helperText: l10n.syncWizardUrlHelperText,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        keyField,
        const SizedBox(height: 24),
        FilledButton(onPressed: onContinue, child: Text(l10n.continueButton)),
      ],
    );
  }
}
