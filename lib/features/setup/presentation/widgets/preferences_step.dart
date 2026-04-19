import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
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

          // Fuel type — locked to the default vehicle's fuel if one is
          // configured in the previous wizard step (#710). The chips
          // are disabled so the user can't pick a conflicting value.
          Builder(builder: (_) {
            final vehicles = ref.watch(vehicleProfileListProvider);
            final defaultVehicle =
                vehicles.isNotEmpty ? vehicles.first : null;
            final derivedFromVehicle =
                defaultVehicle != null ? _fuelForVehicle(defaultVehicle) : null;
            // Sync wizard state to the vehicle's fuel so completion
            // writes the right value to the profile.
            if (derivedFromVehicle != null &&
                wizardState.preferredFuelType.runtimeType !=
                    derivedFromVehicle.runtimeType) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notifier.setPreferredFuelType(derivedFromVehicle);
              });
            }
            final locked = derivedFromVehicle != null;
            final activeFuel = derivedFromVehicle ?? wizardState.preferredFuelType;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.preferredFuel ?? 'Preferred fuel',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: locked ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: locked,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FuelType.e5,
                        FuelType.e10,
                        FuelType.diesel,
                        FuelType.e98,
                        FuelType.lpg,
                        FuelType.e85,
                        FuelType.electric,
                      ].map((fuel) {
                        final selected =
                            activeFuel.runtimeType == fuel.runtimeType;
                        return ChoiceChip(
                          label: Text(fuel.displayName),
                          selected: selected,
                          onSelected: locked
                              ? null
                              : (_) => notifier.setPreferredFuelType(fuel),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n?.profileFuelFromVehicleHint ??
                        'Fuel type is derived from your default vehicle. '
                            'Clear the vehicle to pick a fuel directly.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            );
          }),
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

  /// EV → electric; combustion/hybrid → parsed preferredFuelType. Returns
  /// null when the vehicle has no fuel configured (rare — default is E10).
  FuelType? _fuelForVehicle(VehicleProfile v) {
    if (v.type == VehicleType.ev) return FuelType.electric;
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    return FuelType.fromString(raw);
  }
}
