import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/profile_repository.dart';
import '../../providers/profile_provider.dart';

/// GPS position management section for the profile/settings screen.
///
/// Displays the current GPS position status, allows manual GPS updates,
/// and provides toggles for auto-update and auto-switch profile.
class LocationSectionWidget extends ConsumerStatefulWidget {
  const LocationSectionWidget({super.key});

  @override
  ConsumerState<LocationSectionWidget> createState() =>
      _LocationSectionWidgetState();
}

class _LocationSectionWidgetState
    extends ConsumerState<LocationSectionWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeProfile = ref.watch(activeProfileProvider);
    final l = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGpsStatus(theme, l),
            const SizedBox(height: 12),
            _buildAutoUpdateToggle(theme, activeProfile, l),
            const Divider(),
            _buildAutoSwitchToggle(theme, l),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStatus(ThemeData theme, AppLocalizations? l) {
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
            onPressed: () => _confirmClearGps(l),
            tooltip: l?.delete ?? 'Clear',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _updateGps(),
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

  Widget _buildAutoUpdateToggle(
      ThemeData theme, dynamic activeProfile, AppLocalizations? l) {
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

  Widget _buildAutoSwitchToggle(ThemeData theme, AppLocalizations? l) {
    final settings = ref.read(settingsStorageProvider);
    final autoSwitch =
        settings.getSetting(StorageKeys.autoSwitchProfile) as bool? ?? false;

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
        ref
            .read(settingsStorageProvider)
            .putSetting(StorageKeys.autoSwitchProfile, value);
        setState(() {});
      },
    );
  }

  Future<void> _confirmClearGps(AppLocalizations? l) async {
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

  Future<void> _updateGps() async {
    try {
      await ref.read(userPositionProvider.notifier).updateFromGps();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(context, '${l10n?.gpsError ?? "GPS error"}: $e');
      }
    }
  }
}
