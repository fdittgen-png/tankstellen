import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_providers.dart';
import '../../l10n/app_localizations.dart';

/// A one-time dismissible help banner for contextual onboarding.
///
/// Shows a blue container with an icon, message, and "Got it" button.
/// Once dismissed, the flag is persisted via [SettingsStorage] so the
/// banner never reappears.
class HelpBanner extends ConsumerStatefulWidget {
  /// Storage key used to persist the "shown" flag.
  final String storageKey;

  /// Icon displayed on the left.
  final IconData icon;

  /// The help message text.
  final String message;

  const HelpBanner({
    super.key,
    required this.storageKey,
    required this.icon,
    required this.message,
  });

  @override
  ConsumerState<HelpBanner> createState() => _HelpBannerState();
}

class _HelpBannerState extends ConsumerState<HelpBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkIfShouldShow);
  }

  void _checkIfShouldShow() {
    final settings = ref.read(settingsStorageProvider);
    final shown = settings.getSetting(widget.storageKey);
    if (shown != true && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    final settings = ref.read(settingsStorageProvider);
    await settings.putSetting(widget.storageKey, true);
    if (mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: theme.colorScheme.onPrimaryContainer, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _dismiss,
            child: Text(l?.swipeTutorialDismiss ?? 'Got it'),
          ),
        ],
      ),
    );
  }
}
