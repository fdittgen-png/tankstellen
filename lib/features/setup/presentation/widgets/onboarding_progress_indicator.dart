import 'package:flutter/material.dart';

/// Dot-style progress indicator for the onboarding wizard.
///
/// Shows [stepCount] dots with the [currentStep] highlighted.
/// Animates transitions between steps.
class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int stepCount;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(stepCount, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? theme.colorScheme.primary
                  : isCompleted
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      }),
    );
  }
}
