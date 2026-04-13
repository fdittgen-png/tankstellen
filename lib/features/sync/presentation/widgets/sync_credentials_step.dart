import 'package:flutter/material.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../l10n/app_localizations.dart';

/// Credentials input step for private/join-existing sync modes.
///
/// Shows QR scan button (join-existing) and URL + key text fields.
class SyncCredentialsStep extends StatelessWidget {
  final SyncMode selectedMode;
  final TextEditingController urlController;
  final TextEditingController keyController;
  final bool showKey;
  final VoidCallback onToggleKeyVisibility;
  final VoidCallback onScanQr;
  final VoidCallback? onContinue;
  final VoidCallback onChanged;

  const SyncCredentialsStep({
    super.key,
    required this.selectedMode,
    required this.urlController,
    required this.keyController,
    required this.showKey,
    required this.onToggleKeyVisibility,
    required this.onScanQr,
    required this.onContinue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final keyLen = keyController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedMode == SyncMode.joinExisting) ...[
          FilledButton.icon(
            onPressed: onScanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n?.syncWizardScanQrCode ?? 'Scan QR Code'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 6),
          Text(
            l10n?.syncWizardAskOwnerQrShort ??
                'Ask the database owner to show their QR code',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n?.syncWizardOrEnterManually ??
                    'or enter manually')),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
        ],

        if (selectedMode == SyncMode.private) ...[
          Text(
            l10n?.syncCredentialsPrivateHint ??
                'Enter your Supabase project credentials. You can find them in your dashboard under Settings > API.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
        ],

        TextField(
          controller: urlController,
          decoration: InputDecoration(
            labelText:
                l10n?.syncCredentialsDatabaseUrlLabel ?? 'Database URL',
            hintText: l10n?.syncWizardSupabaseUrlHint ??
                'https://your-project.supabase.co',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link, size: 18),
            isDense: true,
          ),
          maxLines: 1,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: keyController,
          decoration: InputDecoration(
            labelText:
                l10n?.syncCredentialsAccessKeyLabel ?? 'Access Key',
            hintText: l10n?.syncCredentialsAccessKeyHint ??
                'eyJhbGciOiJIUzI1NiIs...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.key, size: 18),
            isDense: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (keyLen > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('$keyLen', style: TextStyle(fontSize: 10,
                      color: keyLen >= 200 ? Colors.green : Colors.orange)),
                  ),
                IconButton(
                  icon: Icon(showKey ? Icons.visibility_off : Icons.visibility, size: 18),
                  tooltip: showKey
                      ? (l10n?.hideKey ?? 'Hide key')
                      : (l10n?.showKey ?? 'Show key'),
                  onPressed: onToggleKeyVisibility,
                ),
              ],
            ),
          ),
          obscureText: !showKey,
          maxLines: showKey ? 3 : 1,
          style: TextStyle(fontSize: showKey ? 10 : 13),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onContinue,
          child: Text(l10n?.continueButton ?? 'Continue'),
        ),
      ],
    );
  }
}
