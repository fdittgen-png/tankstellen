import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final steps = _guideSteps;
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

        Text('Step ${currentStep + 1} of ${steps.length + 1}',
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
            decoration: const InputDecoration(
              labelText: 'Supabase URL',
              hintText: 'https://your-project.supabase.co',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
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
                child: const Text('Back'),
              )
            else
              const SizedBox(),
            FilledButton(
              onPressed: currentStep < 2 ? onNext : onContinue,
              child: Text(currentStep < 2 ? 'Next' : 'Continue'),
            ),
          ],
        ),
      ],
    );
  }

  static List<_GuideStep> get _guideSteps => const [
    _GuideStep(
      title: 'Create a Supabase project',
      instructions: '1. Tap "Open Supabase" below\n'
          '2. Create a free account (if you don\'t have one)\n'
          '3. Click "New Project"\n'
          '4. Choose a name and region\n'
          '5. Wait ~2 minutes for it to start',
      actionLabel: 'Open Supabase',
      actionUrl: 'https://supabase.com/dashboard/new',
    ),
    _GuideStep(
      title: 'Enable Anonymous Sign-ins',
      instructions: '1. In your Supabase dashboard:\n'
          '   Authentication → Providers\n'
          '2. Find "Anonymous Sign-ins"\n'
          '3. Toggle it ON\n'
          '4. Click "Save"',
      actionLabel: 'Open Auth Settings',
      actionUrl: null,
    ),
    _GuideStep(
      title: 'Copy your credentials',
      instructions: '1. Go to Settings → API in your dashboard\n'
          '2. Copy the "Project URL"\n'
          '3. Copy the "anon public" key\n'
          '4. Paste them below',
      actionLabel: 'Open API Settings',
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
