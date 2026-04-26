import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/profile_provider.dart';

/// GPS position management section for the profile/settings screen.
///
/// Displays the current GPS position status, allows manual GPS updates,
/// and provides toggles for auto-update and auto-switch profile.
class LocationSectionWidget extends ConsumerWidget {
  const LocationSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeProfile = ref.watch(activeProfileProvider);
    final l = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGpsStatus(context, ref, theme, l),
            const SizedBox(height: 12),
            _buildAutoUpdateToggle(ref, theme, activeProfile, l),
            const Divider(),
            _buildAutoSwitchToggle(ref, theme, l),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStatus(BuildContext context, WidgetRef ref, ThemeData theme,
      AppLocalizations? l) {
    final userPos = ref.watch(userPositionProvider);

    if (userPos != null) {
      final diff = DateTime.now().difference(userPos.updatedAt);
      final age = diff.inMinutes < 60
          ? '${diff.inMinutes} min'
          : diff.inHours < 24
              ? '${diff.inHours} h'
              : '${diff.inDays} d';

      return Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${userPos.source} ($age)',
                style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _confirmClearGps(context, ref, l),
            tooltip: l?.delete ?? 'Clear',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _updateGps(context, ref),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.my_location,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tap to update GPS position',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'GPS position is acquired automatically when you search. '
          'You can also update it manually here.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoUpdateToggle(WidgetRef ref, ThemeData theme,
      dynamic activeProfile, AppLocalizations? l) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l?.autoUpdatePosition ?? 'Auto-update position',
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        l?.autoUpdateDescription ?? 'Refresh GPS position before each search',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: activeProfile?.autoUpdatePosition ?? false,
      onChanged: (value) {
        if (activeProfile != null) {
          final updated = activeProfile.copyWith(autoUpdatePosition: value);
          ref.read(profileRepositoryProvider).updateProfile(updated);
          ref.invalidate(allProfilesProvider);
          ref.invalidate(activeProfileProvider);
        }
      },
    );
  }

  Widget _buildAutoSwitchToggle(
      WidgetRef ref, ThemeData theme, AppLocalizations? l) {
    final autoSwitch = ref.watch(autoSwitchProfileProvider);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l?.autoSwitchProfile ?? 'Auto-switch profile',
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        l?.autoSwitchDescription ??
            'Automatically switch profile when crossing borders',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: autoSwitch,
      onChanged: (value) {
        ref.read(autoSwitchProfileProvider.notifier).set(value);
      },
    );
  }

  Future<void> _confirmClearGps(
      BuildContext context, WidgetRef ref, AppLocalizations? l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l?.delete ?? 'Clear GPS position'),
        content: const Text(
          'Clear the stored GPS position? '
          'You can update it again at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l?.delete ?? 'Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(userPositionProvider.notifier).clear();
    }
  }

  Future<void> _updateGps(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userPositionProvider.notifier).updateFromGps();
    } catch (e, st) { // ignore: unused_catch_stack
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(
            context, '${l10n?.gpsError ?? "GPS error"}: $e');
      }
    }
  }
}
