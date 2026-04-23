import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'illustrations/fuel_pump_illustration.dart';

/// First onboarding step: welcome message with app branding.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FuelPumpIllustration(size: 160),
          const SizedBox(height: 24),
          Text(
            l10n?.welcome ?? 'Fuel Prices',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.welcomeSubtitle ?? 'Find the cheapest fuel near you.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.onboardingWelcomeHint ??
                'Set up the app in a few quick steps.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
