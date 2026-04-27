import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/gamification_enabled_provider.dart';
import '../../providers/profile_provider.dart';

/// Settings-screen toggle for the master gamification opt-out (#1194).
///
/// Persists by mutating the active [UserProfile.gamificationEnabled]
/// flag through [activeProfileProvider]. The watch on
/// [gamificationEnabledProvider] keeps the switch reactive — toggling
/// it elsewhere (e.g. from a future "first-run" interstitial) flips
/// the visible switch immediately.
///
/// Renders nothing when no profile is loaded yet — the wrapping
/// settings screen guards profile creation up-front, but a paranoid
/// null check keeps test fixtures that omit the profile from
/// throwing.
class GamificationSettingsTile extends ConsumerWidget {
  const GamificationSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) return const SizedBox.shrink();
    final enabled = ref.watch(gamificationEnabledProvider);

    return SwitchListTile(
      key: const Key('gamificationToggle'),
      value: enabled,
      title: Text(
        l?.profileGamificationToggleTitle ?? 'Show achievements & scores',
      ),
      subtitle: Text(
        l?.profileGamificationToggleSubtitle ??
            'When off, badges, scores and trophy icons are hidden across '
                'the app.',
        style: theme.textTheme.bodySmall,
      ),
      onChanged: (v) {
        final updated = profile.copyWith(gamificationEnabled: v);
        ref.read(activeProfileProvider.notifier).updateProfile(updated);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
