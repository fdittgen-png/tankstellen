// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

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

    // #3987 — the position is announced here, so the wizard needs no
    // `n / N` text of its own.
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.onboardingStepOf(currentStep + 1, stepCount),
      container: true,
      child: Row(
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
    ),
    );
  }
}
