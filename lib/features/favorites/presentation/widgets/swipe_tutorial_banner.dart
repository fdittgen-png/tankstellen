import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// A dismissable banner that teaches first-time users about swipe gestures
/// on favorite station cards.
///
/// Shows once per install. The "shown" flag is persisted via [SettingsStorage]
/// so the banner never reappears after the user taps "Got it".
class SwipeTutorialBanner extends ConsumerStatefulWidget {
  const SwipeTutorialBanner({super.key});

  @override
  ConsumerState<SwipeTutorialBanner> createState() =>
      _SwipeTutorialBannerState();
}

class _SwipeTutorialBannerState extends ConsumerState<SwipeTutorialBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkIfShouldShow);
  }

  void _checkIfShouldShow() {
    final settings = ref.read(settingsStorageProvider);
    final shown = settings.getSetting(StorageKeys.swipeTutorialShown);
    if (shown != true && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    final settings = ref.read(settingsStorageProvider);
    await settings.putSetting(StorageKeys.swipeTutorialShown, true);
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      label: l10n?.swipeTutorialMessage ??
          'Swipe right to navigate, swipe left to remove',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.swipe,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.swipeTutorialMessage ??
                    'Swipe right to navigate, swipe left to remove',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _dismiss,
              child: Text(
                l10n?.swipeTutorialDismiss ?? 'Got it',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
