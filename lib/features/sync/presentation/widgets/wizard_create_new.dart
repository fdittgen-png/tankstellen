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
            l10n?.syncWizardStepOfSteps(currentStep + 1, steps.length + 1) ??
                'Step ${currentStep + 1} of ${steps.length + 1}',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
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
            onPressed: () => launchUrl(Uri.parse(step.actionUrl!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: Text(step.actionLabel),
          ),

        if (currentStep == 2) ...[
          // Show URL + key input on step 3
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText:
                  l10n?.syncWizardSupabaseUrlLabel ?? 'Supabase URL',
              hintText: l10n?.syncWizardSupabaseUrlHint ??
                  'https://your-project.supabase.co',
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
              TextButton(
                onPressed: onBack,
                child: Text(l10n?.syncWizardBack ?? 'Back'),
              )
            else
              const SizedBox(),
            FilledButton(
              onPressed: currentStep < 2 ? onNext : onContinue,
              child: Text(currentStep < 2
                  ? (l10n?.syncWizardNext ?? 'Next')
                  : (l10n?.continueButton ?? 'Continue')),
            ),
          ],
        ),
      ],
    );
  }

  static List<_GuideStep> _guideSteps(AppLocalizations? l10n) => [
    _GuideStep(
      title: l10n?.syncWizardCreateSupabaseTitle ?? 'Create a Supabase project',
      instructions: l10n?.syncWizardCreateSupabaseInstructions ??
          '1. Tap "Open Supabase" below\n'
              '2. Create a free account (if you don\'t have one)\n'
              '3. Click "New Project"\n'
              '4. Choose a name and region\n'
              '5. Wait ~2 minutes for it to start',
      actionLabel: l10n?.syncWizardOpenSupabase ?? 'Open Supabase',
      actionUrl: 'https://supabase.com/dashboard/new',
    ),
    _GuideStep(
      title: l10n?.syncWizardEnableAnonTitle ?? 'Enable Anonymous Sign-ins',
      instructions: l10n?.syncWizardEnableAnonInstructions ??
          '1. In your Supabase dashboard:\n'
              '   Authentication → Providers\n'
              '2. Find "Anonymous Sign-ins"\n'
              '3. Toggle it ON\n'
              '4. Click "Save"',
      actionLabel: l10n?.syncWizardOpenAuthSettings ?? 'Open Auth Settings',
      actionUrl: null,
    ),
    _GuideStep(
      title: l10n?.syncWizardCopyCredentialsTitle ?? 'Copy your credentials',
      instructions: l10n?.syncWizardCopyCredentialsInstructions ??
          '1. Go to Settings → API in your dashboard\n'
              '2. Copy the "Project URL"\n'
              '3. Copy the "anon public" key\n'
              '4. Paste them below',
      actionLabel: l10n?.syncWizardOpenApiSettings ?? 'Open API Settings',
      actionUrl: null,
    ),
  ];
}

class _GuideStep {
  final String title;
  final String instructions;
  final String actionLabel;
  final String? actionUrl;
  const _GuideStep({required this.title, required this.instructions, required this.actionLabel, this.actionUrl});
}
