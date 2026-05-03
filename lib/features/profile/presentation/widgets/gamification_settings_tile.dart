import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/gamification_enabled_provider.dart';
import '../../providers/profile_provider.dart';

/// Settings-screen toggle for the master gamification opt-out (#1194).
///
/// As of #1373 phase 3b mutation goes through the central
/// `featureFlagsProvider` system via [gamificationEnabledProvider.set].
/// The watch on [gamificationEnabledProvider] keeps the switch reactive
/// — toggling it elsewhere (e.g. from a future "first-run" interstitial)
/// flips the visible switch immediately.
///
/// Renders nothing when no profile is loaded yet — the wrapping
/// settings screen guards profile creation up-front, but a paranoid
/// null check keeps test fixtures that omit the profile from
/// throwing. The guard is no longer functionally required after the
/// 3b migration (the feature flag store is independent of the active
/// profile), but it minimises blast radius for the wider Settings
/// screen and existing test fixtures that depend on this null-guard
/// behaviour.
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
        ref.read(gamificationEnabledProvider.notifier).set(v);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
