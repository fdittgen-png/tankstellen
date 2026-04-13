import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/link_device_provider.dart';

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  // Text controller stays local — guideline is to keep controllers in the
  // widget even after lifting business state into a provider.
  final _codeController = TextEditingController();

  String? get _myId => TankSyncClient.client?.auth.currentUser?.id;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.linkDeviceScreenTitle ?? 'Link Device'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThisDeviceCard(myId: _myId),
          const SizedBox(height: 16),
          _ImportFromDeviceCard(codeController: _codeController),
          const SizedBox(height: 16),
          const _HowItWorksCard(),
        ],
      ),
    );
  }
}

/// Card showing the current device's anonymous user id with a copy button.
class _ThisDeviceCard extends StatelessWidget {
  final String? myId;

  const _ThisDeviceCard({required this.myId});

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

/// Card with the code input field and the "Import data" button. Needs
/// access to the parent's TextEditingController (kept local to the widget
/// state for lifecycle reasons) and the linkDeviceController provider.
class _ImportFromDeviceCard extends ConsumerWidget {
  final TextEditingController codeController;

  const _ImportFromDeviceCard({required this.codeController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final uiState = ref.watch(linkDeviceControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.linkDeviceImportSectionTitle ??
                      'Import from another device',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.linkDeviceImportDescription ??
                  'Enter the device code from your other device to import its favorites and alerts.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            // ListenableBuilder so the submit button enables/disables
            // based on the local TextEditingController without rebuilding
            // the whole screen.
            ListenableBuilder(
              listenable: codeController,
              builder: (context, _) {
                final hasText = codeController.text.isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText:
                            l10n?.linkDeviceCodeFieldLabel ?? 'Device code',
                        hintText: l10n?.linkDeviceCodeFieldHint ??
                            'Paste the UUID from other device',
                        prefixIcon: const Icon(Icons.key, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: (hasText && !uiState.isLinking)
                          ? () => ref
                              .read(linkDeviceControllerProvider.notifier)
                              .linkDevice(codeController.text)
                          : null,
                      icon: uiState.isLinking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync),
                      label: Text(
                          l10n?.linkDeviceImportButton ?? 'Import data'),
                    ),
                  ],
                );
              },
            ),
            if (uiState.result != null) ...[
              const SizedBox(height: 12),
              Text(
                uiState.result!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: uiState.isError ? Colors.red : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Explanation card describing how the merge works step-by-step.
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

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
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.linkDeviceHowItWorksTitle ?? 'How it works',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.linkDeviceHowItWorksBody ??
                  '1. On Device A: copy the device code above\n'
                      '2. On Device B: paste it in the "Device code" field\n'
                      '3. Tap "Import data" to merge favorites and alerts\n'
                      '4. Both devices will have all combined data\n\n'
                      'Each device keeps its own anonymous identity. '
                      'Data is merged, not moved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
