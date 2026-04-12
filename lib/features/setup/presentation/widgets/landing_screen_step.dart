import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../providers/onboarding_wizard_provider.dart';

/// Onboarding step for choosing the default landing screen.
class LandingScreenStep extends ConsumerWidget {
  const LandingScreenStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(onboardingWizardControllerProvider);
    final notifier = ref.read(onboardingWizardControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 48,
              color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n?.onboardingLandingTitle ?? 'Home screen',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingLandingHint ??
                'Choose which screen opens when you launch the app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...LandingScreen.values.map((screen) {
            final selected = wizardState.landingScreen == screen;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                leading: Icon(
                  _iconFor(screen),
                  color: selected ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  screen.localizedName(l10n?.localeName ?? 'en'),
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : null,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                ),
                selected: selected,
                onTap: () => notifier.setLandingScreen(screen),
              ),
            );
          }),
        ],
      ),
    );
  }

  static IconData _iconFor(LandingScreen screen) {
    return switch (screen) {
      LandingScreen.search => Icons.search,
      LandingScreen.favorites => Icons.star,
      LandingScreen.map => Icons.map,
      LandingScreen.cheapest => Icons.trending_down,
      LandingScreen.nearest => Icons.near_me,
    };
  }
}
