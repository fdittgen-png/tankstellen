import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../providers/onboarding_wizard_provider.dart';

/// Onboarding step for setting default zip code, search radius, and fuel type.
class PreferencesStep extends ConsumerStatefulWidget {
  const PreferencesStep({super.key});

  @override
  ConsumerState<PreferencesStep> createState() => _PreferencesStepState();
}

class _PreferencesStepState extends ConsumerState<PreferencesStep> {
  late final TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingWizardControllerProvider);
    _zipController = TextEditingController(text: state.homeZipCode ?? '');
  }

  @override
  void dispose() {
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(onboardingWizardControllerProvider);
    final notifier = ref.read(onboardingWizardControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.tune, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n?.onboardingPreferencesTitle ?? 'Your preferences',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Home zip code
          TextField(
            controller: _zipController,
            decoration: InputDecoration(
              labelText: l10n?.homeZip ?? 'Home postal code',
              hintText: l10n?.zipCodeHint ?? 'e.g. 10115',
              helperText: l10n?.onboardingZipHelper ??
                  'Used when GPS is unavailable',
              prefixIcon: const Icon(Icons.home),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
            onChanged: (value) => notifier.setHomeZipCode(
                value.trim().isEmpty ? null : value.trim()),
          ),
          const SizedBox(height: 24),

          // Search radius
          Text(
            '${l10n?.searchRadius ?? 'Radius'}: ${wizardState.defaultSearchRadius.round()} km',
            style: theme.textTheme.titleSmall,
          ),
          Slider(
            value: wizardState.defaultSearchRadius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${wizardState.defaultSearchRadius.round()} km',
            onChanged: notifier.setDefaultSearchRadius,
          ),
          Text(
            l10n?.onboardingRadiusHelper ??
                'Larger radius = more results',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Fuel type
          Text(
            l10n?.preferredFuel ?? 'Preferred fuel',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FuelType.e5,
              FuelType.e10,
              FuelType.diesel,
              FuelType.e98,
              FuelType.lpg,
              FuelType.e85,
            ].map((fuel) {
              final selected =
                  wizardState.preferredFuelType.runtimeType == fuel.runtimeType;
              return ChoiceChip(
                label: Text(fuel.displayName),
                selected: selected,
                onSelected: (_) => notifier.setPreferredFuelType(fuel),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Privacy reassurance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, size: 20,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.onboardingPrivacy ??
                        'These settings are stored only on your device and never shared.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
