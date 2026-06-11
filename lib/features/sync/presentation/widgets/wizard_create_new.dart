// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Guided step-by-step flow for creating a new Supabase project.
class WizardCreateNew extends StatelessWidget {
  final int currentStep;
  final TextEditingController urlController;
  final TextEditingController keyController;
  final Widget keyField;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onContinue;

  const WizardCreateNew({
    super.key,
    required this.currentStep,
    required this.urlController,
    required this.keyController,
    required this.keyField,
    required this.onBack,
    required this.onNext,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final steps = _guideSteps(l10n);
    final step = steps[currentStep.clamp(0, steps.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (currentStep + 1) / (steps.length + 1),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 16),

        Text(
          l10n.syncWizardStepOfSteps(currentStep + 1, steps.length + 1),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(step.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(step.instructions, style: theme.textTheme.bodyMedium),
          ),
        ),
        const SizedBox(height: 16),

        if (step.actionUrl != null)
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(step.actionUrl!),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new),
            label: Text(step.actionLabel),
          ),

        if (currentStep == 2) ...[
          // Show URL + key input on step 3
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: l10n.syncWizardSupabaseUrlLabel,
              hintText: l10n.syncWizardSupabaseUrlHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          keyField,
        ],

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentStep > 0)
              TextButton(onPressed: onBack, child: Text(l10n.syncWizardBack))
            else
              const SizedBox(),
            FilledButton(
              onPressed: currentStep < 2 ? onNext : onContinue,
              child: Text(
                currentStep < 2 ? (l10n.syncWizardNext) : (l10n.continueButton),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<_GuideStep> _guideSteps(AppLocalizations l10n) => [
    _GuideStep(
      title: l10n.syncWizardCreateSupabaseTitle,
      instructions: l10n.syncWizardCreateSupabaseInstructions,
      actionLabel: l10n.syncWizardOpenSupabase,
      actionUrl: 'https://supabase.com/dashboard/new',
    ),
    _GuideStep(
      title: l10n.syncWizardEnableAnonTitle,
      instructions: l10n.syncWizardEnableAnonInstructions,
      actionLabel: l10n.syncWizardOpenAuthSettings,
      actionUrl: null,
    ),
    _GuideStep(
      title: l10n.syncWizardCopyCredentialsTitle,
      instructions: l10n.syncWizardCopyCredentialsInstructions,
      actionLabel: l10n.syncWizardOpenApiSettings,
      actionUrl: null,
    ),
  ];
}

class _GuideStep {
  final String title;
  final String instructions;
  final String actionLabel;
  final String? actionUrl;
  const _GuideStep({
    required this.title,
    required this.instructions,
    required this.actionLabel,
    this.actionUrl,
  });
}
