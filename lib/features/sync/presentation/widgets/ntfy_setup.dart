import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/ntfy_service.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// A card widget for the Settings/TankSync section allowing users
/// to enable ntfy.sh push notifications.
class NtfySetupCard extends ConsumerStatefulWidget {
  const NtfySetupCard({super.key});

  @override
  ConsumerState<NtfySetupCard> createState() => _NtfySetupCardState();
}

class _NtfySetupCardState extends ConsumerState<NtfySetupCard> {
  final _ntfyService = NtfyService();
  bool _enabled = false;
  bool _isSendingTest = false;
  bool _isToggling = false;
  bool _initialLoadDone = false;

  String? _topic;

  /// Load the current push_tokens state from Supabase on first build.
  Future<void> _loadInitialState(String userId) async {
    if (_initialLoadDone) return;
    _initialLoadDone = true;

    try {
      final client = TankSyncClient.client;
      if (client == null) return;

      final rows = await client
          .from('push_tokens')
          .select('enabled')
          .eq('user_id', userId)
          .limit(1);

      if (rows.isNotEmpty && mounted) {
        setState(() {
          _enabled = rows.first['enabled'] as bool? ?? false;
        });
      }
    } catch (e) {
      debugPrint('NtfySetupCard: failed to load push_tokens state: $e');
    }
  }

  /// Persist the toggle state in the push_tokens table.
  Future<void> _setEnabled(bool value, String userId) async {
    setState(() => _isToggling = true);
    try {
      final client = TankSyncClient.client;
      if (client == null) return;

      if (value) {
        final topic = _ntfyService.generateTopic(userId);
        await client.from('push_tokens').upsert({
          'user_id': userId,
          'ntfy_topic': topic,
          'enabled': true,
        }, onConflict: 'user_id');
      } else {
        await client.from('push_tokens').update({
          'enabled': false,
        }).eq('user_id', userId);
      }

      if (mounted) {
        setState(() => _enabled = value);
      }
    } catch (e) {
      debugPrint('NtfySetupCard: failed to update push_tokens: $e');
      if (mounted) {
        SnackBarHelper.showError(context, AppLocalizations.of(context)?.pushUpdateFailed ?? 'Failed to update push notification setting');
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncConfig = ref.watch(syncStateProvider);
    final userId = syncConfig.userId;

    if (userId != null && _topic == null) {
      _topic = _ntfyService.generateTopic(userId);
    }

    // Load persisted state from Supabase once we have a userId.
    if (userId != null) {
      _loadInitialState(userId);
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
              value: _enabled,
              secondary: _isToggling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onChanged: userId != null && !_isToggling
                  ? (value) => _setEnabled(value, userId)
                  : null,
            ),
            if (_enabled && _topic != null) ...[
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
                        'https://ntfy.sh/$_topic',
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
                          ClipboardData(text: 'https://ntfy.sh/$_topic'));
                      SnackBarHelper.show(context, AppLocalizations.of(context)?.topicUrlCopied ?? 'Topic URL copied');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _isSendingTest
                    ? null
                    : () async {
                        setState(() => _isSendingTest = true);
                        final success =
                            await _ntfyService.sendTestNotification(_topic!);
                        if (mounted) {
                          setState(() => _isSendingTest = false);
                          final l10n = AppLocalizations.of(context);
                          if (success) {
                            SnackBarHelper.showSuccess(context, l10n?.testNotificationSent ?? 'Test notification sent!');
                          } else {
                            SnackBarHelper.showError(context, l10n?.testNotificationFailed ?? 'Failed to send test notification');
                          }
                        }
                      },
                icon: _isSendingTest
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
