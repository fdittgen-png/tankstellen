import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/settings_menu_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../glide_coach/data/traffic_signal_repository.dart';
import '../../../glide_coach/providers/glide_coach_settings_provider.dart';
import '../../../profile/presentation/widgets/gamification_settings_tile.dart';
import '../../providers/haptic_eco_coach_provider.dart';

/// Consumption / driving settings group on the profile screen.
///
/// Surfaced under the Conso-tab-aliased "Consumption" foldable, this
/// section composes everything the user might want to tune for the
/// vehicle they are currently driving:
///   1. **My vehicles** (battery, connectors, charging prefs).
///   2. **Fuel club cards** (per-litre discounts).
///   3. **Real-time eco coaching** (haptic when over-driving on cruise).
///   4. **Show achievements & scores** (master gamification opt-out —
///      badges, scores, achievement tab).
///
/// The first two were standalone `SettingsMenuTile`s on the Settings
/// page; pulling them inside one foldable that matches the "Conso" tab
/// label keeps the per-vehicle controls clustered (#1122 follow-up).
///
/// Default of the eco-coach toggle is **off** —
/// `HapticEcoCoachEnabled` reads the persisted Hive setting, which is
/// null for first-launch users and only flips to true after an
/// explicit tap.
class DrivingSettingsSection extends ConsumerWidget {
  const DrivingSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final enabled = ref.watch(hapticEcoCoachEnabledProvider);
    // #1517 / #1520 — gate the Loyalty tile by the new
    // [Feature.loyaltyCards] flag. Default-off; only the
    // `AppProfile.full` preset turns it on, so Basic + Medium users
    // never see the Fuel club cards entry-point in Settings.
    final loyaltyOn =
        ref.watch(featureFlagsProvider).contains(Feature.loyaltyCards);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // #1568 — "My vehicles" tile moved up to Settings root so the
        // entry-point is discoverable without expanding the Conso
        // foldable. The fuel-club + eco-coach + gamification toggles
        // stay clustered here.
        if (loyaltyOn)
          SettingsMenuTile(
            key: const Key('consoleFuelClubCardsTile'),
            icon: Icons.card_membership,
            title: l?.loyaltyMenuTitle ?? 'Fuel club cards',
            subtitle: l?.loyaltyMenuSubtitle ??
                'Apply per-litre discounts from Total, Aral, Shell, …',
            onTap: () => context.push('/loyalty-settings'),
          ),
        SwitchListTile(
          key: const Key('hapticEcoCoachToggle'),
          value: enabled,
          title: Text(
            l?.hapticEcoCoachSettingTitle ?? 'Real-time eco coaching',
          ),
          subtitle: Text(
            l?.hapticEcoCoachSettingSubtitle ??
                'Gentle haptic + on-screen tip when you floor it '
                    'during cruise',
            style: theme.textTheme.bodySmall,
          ),
          onChanged: (v) =>
              ref.read(hapticEcoCoachEnabledProvider.notifier).set(v),
          contentPadding: EdgeInsets.zero,
        ),
        // #1125 phase 3b — glide-coach beta opt-in. The entire tile is
        // wrapped in `if (kGlideCoachEnabled)` so it stays invisible in
        // production: even users who would happily try it cannot enable
        // a half-baked feature until the master flag flips after a
        // driving-test cohort. When the flag flips, the toggle appears
        // here without any further UI work.
        if (kGlideCoachEnabled) const _GlideCoachToggleTile(),
        const GamificationSettingsTile(),
      ],
    );
  }
}

/// Beta opt-in tile for the glide-coach haptic (#1125 phase 3b).
///
/// Rendered only when the compile-time master flag
/// [`kGlideCoachEnabled`] is true; the call site in
/// [DrivingSettingsSection] gates visibility via `if (kGlideCoachEnabled)`.
/// Keeping the widget itself in this file (rather than in the
/// glide_coach feature folder) avoids importing presentation widgets
/// from a feature whose UI surface doesn't exist yet, and matches the
/// pattern of [GamificationSettingsTile] / [HapticEcoCoach toggle] —
/// each toggle co-locates with the section it belongs to.
class _GlideCoachToggleTile extends ConsumerWidget {
  const _GlideCoachToggleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final settings = ref.watch(glideCoachSettingsProvider);
    return SwitchListTile(
      key: const Key('glideCoachToggle'),
      value: settings.enabled,
      title: Text(l?.glideCoachBetaTitle ?? 'Glide-coach beta (experimental)'),
      subtitle: Text(
        l?.glideCoachBetaSubtitle ??
            'Subtle haptic when slowing down ahead of a red light. '
                'Off by default — distraction risk.',
        style: theme.textTheme.bodySmall,
      ),
      onChanged: (v) => ref
          .read(glideCoachSettingsProvider.notifier)
          .setEnabled(v),
      contentPadding: EdgeInsets.zero,
    );
  }
}
