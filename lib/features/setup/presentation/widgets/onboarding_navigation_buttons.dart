import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Bottom navigation row of the onboarding wizard — Back / Skip / Next.
///
/// Stateless: the parent screen owns the wizard step state and passes the
/// flags + callbacks through. Pulled out of `onboarding_wizard_screen.dart`
/// so the screen's build method drops the 45-line inline `Row(...)` block
/// and the button-state logic can be exercised by widget tests.
class OnboardingNavigationButtons extends StatelessWidget {
  /// Zero-based index of the current page.
  final int currentStep;

  /// Whether the *Next* / *Finish* action is in flight (controls the
  /// spinner and disables every button so the user can't fire two
  /// actions at once).
  final bool isLoading;

  /// `true` when the current step is the last one — flips the *Next*
  /// button to *Finish* with a check icon.
  final bool isLastStep;

  /// `true` when the current step is optional — surfaces the *Skip* button.
  final bool isSkippable;

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingNavigationButtons({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.isLastStep,
    required this.isSkippable,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        32,
        16,
        32,
        16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Row(
        children: [
          // Back button — hidden on the first step but the empty SizedBox
          // keeps the right-side button aligned.
          if (currentStep > 0)
            TextButton.icon(
              onPressed: isLoading ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n?.onboardingBack ?? 'Back'),
            )
          else
            const SizedBox(width: 80),
          const Spacer(),
          if (isSkippable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: isLoading ? null : onSkip,
                child: Text(l10n?.onboardingSkip ?? 'Skip'),
              ),
            ),
          FilledButton.icon(
            onPressed: isLoading ? null : onNext,
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isLastStep ? Icons.check : Icons.arrow_forward),
            label: Text(
              isLastStep
                  ? (l10n?.onboardingFinish ?? 'Get started')
                  : (l10n?.onboardingNext ?? 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
