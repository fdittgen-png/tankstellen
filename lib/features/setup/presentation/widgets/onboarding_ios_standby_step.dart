import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Onboarding step shown only on iOS, right before the OBD2 pairing
/// step. Explains the three iOS-specific compromises that the
/// hands-free auto-record flow imposes on the user:
///
/// 1. Open the app once after each reboot.
/// 2. Don't swipe the app away in the app switcher.
/// 3. Grant "Always" location when iOS asks.
///
/// Copy is mirrored verbatim from the "iOS-only onboarding copy" block
/// in `docs/guides/ios-auto-record.md` so the docs and the in-app
/// screen stay in lock-step.
///
/// The wizard owns Next / Back via [OnboardingNavigationButtons]; this
/// step does not render its own CTA so the navigation chrome stays
/// consistent with every other step in the flow.
class OnboardingIosStandbyStep extends StatelessWidget {
  const OnboardingIosStandbyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.phone_iphone,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.iosAutoRecordOnboardingTitle ??
                "Stay out of the app — but don't quit it.",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _Bullet(
            number: 1,
            title: l10n?.iosAutoRecordOnboardingBullet1Title ??
                'Open Sparkilo once after each reboot.',
            body: l10n?.iosAutoRecordOnboardingBullet1Body ??
                'Apple wakes Sparkilo only after you’ve opened it at '
                    'least once since the phone restarted. After that, '
                    'your trips record automatically.',
          ),
          const SizedBox(height: 16),
          _Bullet(
            number: 2,
            title: l10n?.iosAutoRecordOnboardingBullet2Title ??
                'Don’t swipe Sparkilo away in the app switcher.',
            body: l10n?.iosAutoRecordOnboardingBullet2Body ??
                '"Force-quit" tells iOS to stop relaunching the app. Your '
                    'trips will stop recording until you open Sparkilo '
                    'again.',
          ),
          const SizedBox(height: 16),
          _Bullet(
            number: 3,
            title: l10n?.iosAutoRecordOnboardingBullet3Title ??
                'When iOS asks for "Always" location, please say yes.',
            body: l10n?.iosAutoRecordOnboardingBullet3Body ??
                'The fallback that records your trip when the OBD2 '
                    'adapter is slow needs background location. We never '
                    'share it.',
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final int number;
  final String title;
  final String body;

  const _Bullet({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            '$number',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
