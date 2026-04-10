import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/ntfy_setup_provider.dart';

/// A card widget for the Settings/TankSync section allowing users
/// to enable ntfy.sh push notifications.
///
/// State lives in [ntfySetupControllerProvider]; this widget only renders.
class NtfySetupCard extends ConsumerWidget {
  const NtfySetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncConfig = ref.watch(syncStateProvider);
    final userId = syncConfig.userId;
    final state = ref.watch(ntfySetupControllerProvider);
    final notifier = ref.read(ntfySetupControllerProvider.notifier);

    // Derive topic and load persisted state once we have a userId.
    if (userId != null) {
      if (state.topic == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.ensureTopic(userId);
        });
      }
      if (!state.initialLoadDone) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.loadInitialState(userId);
        });
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Push Notifications (ntfy.sh)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable ntfy.sh push'),
              subtitle: const Text('Receive price alerts via ntfy.sh'),
              value: state.enabled,
              secondary: state.isToggling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onChanged: userId != null && !state.isToggling
                  ? (value) async {
                      final ok = await notifier.setEnabled(value, userId);
                      if (!ok && context.mounted) {
                        SnackBarHelper.showError(
                          context,
                          AppLocalizations.of(context)?.pushUpdateFailed ??
                              'Failed to update push notification setting',
                        );
                      }
                    }
                  : null,
            ),
            if (state.enabled && state.topic != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Topic URL',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'https://ntfy.sh/${state.topic}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy topic URL',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: 'https://ntfy.sh/${state.topic}'));
                      SnackBarHelper.show(
                        context,
                        AppLocalizations.of(context)?.topicUrlCopied ??
                            'Topic URL copied',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: state.isSendingTest
                    ? null
                    : () async {
                        final success = await notifier.sendTestNotification();
                        if (!context.mounted) return;
                        final l10n = AppLocalizations.of(context);
                        if (success) {
                          SnackBarHelper.showSuccess(
                            context,
                            l10n?.testNotificationSent ??
                                'Test notification sent!',
                          );
                        } else {
                          SnackBarHelper.showError(
                            context,
                            l10n?.testNotificationFailed ??
                                'Failed to send test notification',
                          );
                        }
                      },
                icon: state.isSendingTest
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Send test notification'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Install the ntfy app from F-Droid to receive push notifications on your device.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            if (userId == null) ...[
              const SizedBox(height: 8),
              Text(
                'Connect TankSync first to enable push notifications.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
