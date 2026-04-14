import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Card showing the current device's anonymous user id (the value the
/// other device pastes into its "Device code" field). Includes a copy
/// button when an id is available.
///
/// Pulled out of `link_device_screen.dart` so the screen drops the
/// inline 78-line `_ThisDeviceCard` private widget and so this card can
/// be exercised by widget tests in isolation.
class LinkDeviceThisDeviceCard extends StatelessWidget {
  final String? myId;

  const LinkDeviceThisDeviceCard({super.key, required this.myId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.linkDeviceThisDeviceLabel ?? 'This device',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.linkDeviceShareCodeHint ??
                  'Share this code with your other device:',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      myId ??
                          (l10n?.linkDeviceNotConnected ?? 'Not connected'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  if (myId != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip:
                          l10n?.linkDeviceCopyCodeTooltip ?? 'Copy code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: myId!));
                        SnackBarHelper.show(
                          context,
                          AppLocalizations.of(context)?.deviceCodeCopied ??
                              'Device code copied',
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
