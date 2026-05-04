import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../sync/providers/baseline_sync_enabled_provider.dart';
import '../../../providers/privacy_data_provider.dart';
import 'privacy_data_row.dart';

/// Card describing what (if anything) is mirrored to the TankSync server.
class SyncedDataCard extends StatelessWidget {
  final PrivacyDataSnapshot snapshot;

  const SyncedDataCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined,
                    size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  l?.privacySyncedData ?? 'Cloud sync (TankSync)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!snapshot.syncEnabled)
              _SyncDisabledBanner(theme: theme, l: l)
            else
              _SyncEnabledBody(theme: theme, l: l, snapshot: snapshot),
          ],
        ),
      ),
    );
  }
}

class _SyncDisabledBanner extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations? l;

  const _SyncDisabledBanner({required this.theme, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l?.privacySyncDisabled ??
                  'Cloud sync is disabled. All data stays on this device only.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncEnabledBody extends ConsumerWidget {
  final ThemeData theme;
  final AppLocalizations? l;
  final PrivacyDataSnapshot snapshot;

  const _SyncEnabledBody({
    required this.theme,
    required this.l,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = snapshot.syncUserId;
    final baselineSyncOn = ref.watch(baselineSyncEnabledProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrivacyDataRow(
          icon: Icons.sync,
          label: l?.privacySyncMode ?? 'Sync mode',
          value: snapshot.syncMode ?? '-',
        ),
        PrivacyDataRow(
          icon: Icons.perm_identity,
          label: l?.privacySyncUserId ?? 'User ID',
          value: userId != null ? '${userId.substring(0, 8)}...' : '-',
        ),
        const SizedBox(height: 8),
        Text(
          l?.privacySyncDescription ??
              'When sync is enabled, favorites, alerts, ignored stations, and ratings are also stored on the TankSync server.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // #780 phase 3 — opt-in toggle for per-vehicle baseline sync.
        // Default false; flips to true only when the user explicitly
        // enables it here.
        SwitchListTile(
          key: const Key('syncBaselinesToggle'),
          value: baselineSyncOn,
          title: Text(
            l?.syncBaselinesToggleTitle ?? 'Share learned vehicle profiles',
          ),
          subtitle: Text(
            l?.syncBaselinesToggleSubtitle ??
                'Upload per-vehicle consumption baselines so a second device can reuse them.',
            style: theme.textTheme.bodySmall,
          ),
          onChanged: (v) async {
            await ref.read(baselineSyncEnabledProvider.notifier).set(v);
          },
          contentPadding: EdgeInsets.zero,
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/data-transparency'),
          icon: const Icon(Icons.visibility, size: 18),
          label: Text(l?.privacyViewServerData ?? 'View server data'),
        ),
      ],
    );
  }
}
