// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'illustrations/shield_illustration.dart';

/// Final onboarding step: confirmation that setup is complete.
class CompletionStep extends StatelessWidget {
  const CompletionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #1698 — the wizard's PageView is NeverScrollable, so this step
    // owns its scrolling. The illustration + two texts are centred when
    // they fit and scroll when large text scaling pushes them past the
    // viewport: `ConstrainedBox(minHeight)` keeps the centred look in
    // the common case, the SingleChildScrollView absorbs the overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ShieldIllustration(size: 160),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.onboardingComplete ?? 'All set!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.onboardingCompleteHint ??
                        'You can change these settings anytime in your '
                            'profile.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
