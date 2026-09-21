// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/api.dart';
import '../../providers/onboarding_wizard_provider.dart';

/// First-page wizard step (#1518) where the user picks a use-mode
/// profile that drives which features and which subsequent wizard
/// steps they see (#1517).
///
/// Replaces the prior pure-branding `WelcomeStep`. Sparkilo wordmark +
/// short subhead at the top, then three large vertical cards for the
/// three preset profiles. Tapping a card persists the choice via
/// [ActiveAppProfile.select] (which also applies the corresponding
/// feature-flag bundle) and calls [onProfilePicked] so the wizard can
/// advance.
///
/// #4217 adds a fourth card — *company or fleet vehicle*. It picks the
/// same [AppProfile.medium] preset (a fleet driver logs fill-ups and
/// expenses; the OBD2 stack is not implied) and additionally switches
/// `Feature.fleetMode` on, which inserts the fleet identity and
/// privacy-summary pages into the wizard. The card renders only where
/// that capability is available at all — beta channel today
/// (ADR 0025 D6) — so a production user sees exactly the three cards
/// they saw before, with unchanged behaviour.
class ProfileChoiceStep extends ConsumerWidget {
  /// Called once the user has tapped a card (after the bundle has
  /// been applied). The wizard moves to the next step.
  final VoidCallback onProfilePicked;

  const ProfileChoiceStep({super.key, required this.onProfilePicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final activeProfile = ref.watch(activeAppProfileProvider);
    final fleetPicked = ref.watch(onboardingWizardControllerProvider
        .select((s) => s.fleetIntent));
    final fleetOffered = ref
        .watch(featureManifestProvider)
        .entryFor(Feature.fleetMode)
        .isAvailableIn(ref.watch(buildChannelProvider));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sparkilo', // i18n-ignore: brand wordmark / proper noun
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // #2526 — the wordmark was the light brand green `#2E7D32`
              // (3.4:1 on the dark surface). Brightness-select so dark uses
              // the lighter brand `primary` (#69A16B) and clears AA.
              color: DarkModeColors.brandGreen(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.wizardProfileChoiceHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _ProfileCard(
            cardKey: AppProfile.basic.name,
            icon: Icons.local_gas_station_outlined,
            title: l.wizardProfileBasicName,
            description: l.wizardProfileBasicDescription,
            isActive: activeProfile == AppProfile.basic && !fleetPicked,
            onTap: () => _pick(ref, AppProfile.basic),
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            cardKey: AppProfile.medium.name,
            icon: Icons.analytics_outlined,
            title: l.wizardProfileMediumName,
            description: l.wizardProfileMediumDescription,
            isActive: activeProfile == AppProfile.medium && !fleetPicked,
            onTap: () => _pick(ref, AppProfile.medium),
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            cardKey: AppProfile.full.name,
            icon: Icons.directions_car_filled,
            title: l.wizardProfileFullName,
            description: l.wizardProfileFullDescription,
            isActive: activeProfile == AppProfile.full && !fleetPicked,
            onTap: () => _pick(ref, AppProfile.full),
          ),
          if (fleetOffered) ...[
            const SizedBox(height: 12),
            _ProfileCard(
              cardKey: 'fleet',
              icon: Icons.business_center_outlined,
              title: l.wizardProfileFleetName,
              description: l.wizardProfileFleetDescription,
              isActive: fleetPicked,
              onTap: () => _pick(ref, AppProfile.medium, fleet: true),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l.wizardProfileChoiceFooter,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Applies the tapped card. Both halves (the preset bundle and the
  /// fleet-mode flag) run inside the wizard controller so the order is
  /// fixed and this widget never touches `ref` after an await (#3159).
  Future<void> _pick(
    WidgetRef ref,
    AppProfile profile, {
    bool fleet = false,
  }) async {
    await ref
        .read(onboardingWizardControllerProvider.notifier)
        .applyProfileChoice(profile, fleet: fleet);
    onProfilePicked();
  }
}

/// One large card per use-mode intent — icon on the left, title +
/// description on the right. Active card shows a brand-green border
/// and a check badge so the choice is visible after a tap (or when the
/// user revisits the wizard with a profile already set).
///
/// [cardKey] names the intent rather than the profile, because two
/// cards (personal *Track my consumption* and *Company or fleet
/// vehicle*) select the same [AppProfile.medium] preset and still have
/// to be addressable — and distinguishable — separately.
class _ProfileCard extends StatelessWidget {
  final String cardKey;
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // #2526 — adaptive brand green: dark substitutes the scheme's lighter
    // `primary` (#69A16B) so the active border/icon/title/check clear AA on
    // the dark Card surface; light keeps the icon brand green `#2E7D32`.
    final brandGreen = DarkModeColors.brandGreen(context);
    final borderColor = isActive ? brandGreen : theme.dividerColor;
    return Card(
      key: Key('profileCard_$cardKey'),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: isActive
                    ? brandGreen
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? brandGreen
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle, color: brandGreen, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
