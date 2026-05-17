import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/app_profile_provider.dart';
import '../../../feature_management/domain/app_profile.dart';

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
class ProfileChoiceStep extends ConsumerWidget {
  /// Called once the user has tapped a card (after the bundle has
  /// been applied). The wizard moves to the next step.
  final VoidCallback onProfilePicked;

  const ProfileChoiceStep({
    super.key,
    required this.onProfilePicked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final activeProfile = ref.watch(activeAppProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sparkilo', // i18n-ignore: brand wordmark / proper noun
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l?.wizardProfileChoiceHint ??
                'Choose how you want to use the app. You can change '
                    'this later in Settings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _ProfileCard(
            profile: AppProfile.basic,
            icon: Icons.local_gas_station_outlined,
            title: l?.wizardProfileBasicName ?? 'Basic',
            description: l?.wizardProfileBasicDescription ??
                'Cheapest fuel and EV charging prices nearby. '
                    'Favorites and price alerts.',
            isActive: activeProfile == AppProfile.basic,
            onTap: () => _pick(ref, AppProfile.basic),
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            profile: AppProfile.medium,
            icon: Icons.analytics_outlined,
            title: l?.wizardProfileMediumName ?? 'Medium',
            description: l?.wizardProfileMediumDescription ??
                'Everything in Basic, plus track your fuel fill-ups '
                    'and EV charging by hand.',
            isActive: activeProfile == AppProfile.medium,
            onTap: () => _pick(ref, AppProfile.medium),
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            profile: AppProfile.full,
            icon: Icons.directions_car_filled,
            title: l?.wizardProfileFullName ?? 'Full',
            description: l?.wizardProfileFullDescription ??
                'Everything in Medium, plus automatic OBD2 trip '
                    'recording, driving scores, and loyalty cards.',
            isActive: activeProfile == AppProfile.full,
            onTap: () => _pick(ref, AppProfile.full),
          ),
          const SizedBox(height: 16),
          Text(
            l?.wizardProfileChoiceFooter ??
                'You can change your choice any time from Settings '
                    '→ Use mode.',
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

  Future<void> _pick(WidgetRef ref, AppProfile profile) async {
    await ref.read(activeAppProfileProvider.notifier).select(profile);
    onProfilePicked();
  }
}

/// One large card per [AppProfile] — icon on the left, title +
/// description on the right. Active card shows a brand-green border
/// and a check badge so the choice is visible after a tap (or when the
/// user revisits the wizard with a profile already set).
class _ProfileCard extends StatelessWidget {
  final AppProfile profile;
  final IconData icon;
  final String title;
  final String description;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileCard({
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
    const brandGreen = Color(0xFF2E7D32);
    final borderColor = isActive ? brandGreen : theme.dividerColor;
    return Card(
      key: Key('profileCard_${profile.name}'),
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
                          const Icon(
                            Icons.check_circle,
                            color: brandGreen,
                            size: 20,
                          ),
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
