// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/app_profile_provider.dart';
import '../../../feature_management/domain/app_profile.dart';

/// Settings-screen "Use mode" selector (#1519 / #1517).
///
/// Renders four cards — the three preset profiles
/// ([AppProfile.basic] / [AppProfile.medium] / [AppProfile.full]) plus a
/// fourth read-only [AppProfile.custom] card that surfaces the user's
/// current state when they've toggled features outside any preset.
/// Tapping a preset card calls [ActiveAppProfile.select] which both
/// persists the choice and applies the corresponding flag bundle to
/// `featureFlagsProvider`.
///
/// Sits at the very top of `ProfileScreen` (above the existing Profile
/// section) because it gates everything else: changing the use-mode
/// re-derives which other Settings sections (Consumption, Loyalty,
/// Vehicles, Achievements) are visible at all.
class UseModeSection extends ConsumerWidget {
  const UseModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final activeProfile = ref.watch(activeAppProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              l?.useModeSectionHint ??
                  'Right-size the app to how you actually use it. '
                      'Picking a preset enables the matching set of '
                      'features.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _PresetCard(
            profile: AppProfile.basic,
            icon: Icons.local_gas_station_outlined,
            title: l?.wizardProfileBasicName ?? 'Basic',
            description: l?.wizardProfileBasicDescription ??
                'Cheapest fuel and EV charging prices nearby. '
                    'Favorites and price alerts.',
            isActive: activeProfile == AppProfile.basic,
            onTap: () => _select(context, ref, AppProfile.basic, l),
          ),
          const SizedBox(height: 8),
          _PresetCard(
            profile: AppProfile.medium,
            icon: Icons.analytics_outlined,
            title: l?.wizardProfileMediumName ?? 'Medium',
            description: l?.wizardProfileMediumDescription ??
                'Everything in Basic, plus track your fuel fill-ups '
                    'and EV charging by hand.',
            isActive: activeProfile == AppProfile.medium,
            onTap: () => _select(context, ref, AppProfile.medium, l),
          ),
          const SizedBox(height: 8),
          _PresetCard(
            profile: AppProfile.full,
            icon: Icons.directions_car_filled,
            title: l?.wizardProfileFullName ?? 'Full',
            description: l?.wizardProfileFullDescription ??
                'Everything in Medium, plus automatic OBD2 trip '
                    'recording, driving scores, and loyalty cards.',
            isActive: activeProfile == AppProfile.full,
            onTap: () => _select(context, ref, AppProfile.full, l),
          ),
          if (activeProfile == AppProfile.custom) ...[
            const SizedBox(height: 8),
            _PresetCard(
              profile: AppProfile.custom,
              icon: Icons.tune_outlined,
              title: l?.wizardProfileCustomName ?? 'Custom',
              description: l?.useModeCustomSettingsDescription ??
                  "Your feature mix doesn't match any preset. Pick "
                      'one above to overwrite, or keep customising '
                      'individual features in the section below.',
              isActive: true,
              onTap: null,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    AppProfile profile,
    AppLocalizations? l,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref.read(activeAppProfileProvider.notifier).select(profile);
    if (messenger != null && context.mounted) {
      final name = _localizedName(profile, l);
      SnackBarHelper.showSuccess(
        context,
        l?.useModeSwitchedSnack(name) ?? 'Use mode set to $name.',
      );
    }
  }

  String _localizedName(AppProfile profile, AppLocalizations? l) {
    switch (profile) {
      case AppProfile.basic:
        return l?.wizardProfileBasicName ?? 'Basic';
      case AppProfile.medium:
        return l?.wizardProfileMediumName ?? 'Medium';
      case AppProfile.full:
        return l?.wizardProfileFullName ?? 'Full';
      case AppProfile.custom:
        return l?.wizardProfileCustomName ?? 'Custom';
    }
  }
}

/// One row in the Use-mode selector. Mirrors the wizard's
/// `ProfileChoiceStep` card but compressed for the Settings surface.
class _PresetCard extends StatelessWidget {
  final AppProfile profile;
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;
  final VoidCallback? onTap;

  const _PresetCard({
    required this.profile,
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // #2526 — the active on-colour is now `onPrimaryContainer` (the
    // scheme's guaranteed-legible pairing for a `primaryContainer`
    // fill), replacing the hardcoded light brand-green `#2E7D32` that
    // collapsed to ~1.16:1 on a dark surface.
    final activeOn = cs.onPrimaryContainer;
    // #2116 — replaced the 2-px green outline + checkmark badge of
    // the selected state with a Material 3-style subtle tonal
    // background + raised elevation. The on-container text + leading
    // icon carry the selected-state signal; the outline was visually
    // competing with the label.
    // #2526 — the fill was `primaryContainer.withValues(alpha: 0.4)`,
    // which in dark resolves to a mid-tone grey-green on which neither
    // the near-black `onPrimaryContainer` (2.7:1) nor brand green reads.
    // The *solid* `primaryContainer` keeps the M3 tonal look while
    // making `onPrimaryContainer` clear AA (11:1) in every theme.
    return Card(
      key: Key('useModeCard_${profile.name}'),
      elevation: isActive ? 1 : 0,
      margin: EdgeInsets.zero,
      color: isActive ? cs.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: isActive ? activeOn : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive ? activeOn : cs.onSurface,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            color: activeOn,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        // #2526 — on the solid `primaryContainer` active fill,
                        // `onSurfaceVariant` (light grey in dark) vanishes;
                        // pin to `onPrimaryContainer` while active.
                        color: isActive ? activeOn : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
