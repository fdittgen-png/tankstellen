import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';

/// Optional onboarding step that lets the user pre-register one or more
/// vehicles (#692). Adding a vehicle here pre-fills the consumption log
/// and enables connector-based EV filters; skipping leaves the app
/// fully usable without any vehicle configured.
class VehiclesStep extends ConsumerWidget {
  const VehiclesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vehicles = ref.watch(vehicleProfileListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l10n?.vehiclesWizardTitle ?? 'My vehicles (optional)',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.vehiclesWizardSubtitle ??
                'Add your car to pre-fill the consumption log and enable '
                    'EV connector filters. You can skip this and add vehicles later.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (vehicles.isEmpty)
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n?.vehiclesWizardNoneYet ??
                                'No vehicle configured yet.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.vehiclesWizardYoursList(vehicles.length) ??
                      'You have ${vehicles.length} vehicle(s):',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                // Tappable tiles so the user can re-open / edit any
                // configured vehicle from within the wizard (#710).
                // The first-defined vehicle is implicitly the default
                // (see profile wiring) and displayed with a badge.
                ...vehicles.map((v) {
                  final isDefault = vehicles.first.id == v.id;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.directions_car),
                    title: Text(v.name),
                    subtitle: Text(
                      _typeLabel(l10n, v.isEv, v.isCombustion) +
                          _fuelSuffix(v.preferredFuelType) +
                          (isDefault
                              ? '  •  ${l10n?.wizardVehicleDefaultBadge ?? 'Default'}'
                              : ''),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () =>
                        context.push<void>('/vehicles/edit', extra: v.id),
                  );
                }),
              ],
            ),
          const SizedBox(height: 16),
          // Bigger button so the user can't accidentally tap the
          // wizard's Next/Skip row below it (#695 follow-up).
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              // Route for a new vehicle: `/vehicles/edit` with no extra.
              onPressed: () async {
                // Await the push so the wizard rebuilds after the user
                // saves/cancels the vehicle edit screen — without the
                // await, the returned Future is dropped and the step
                // never re-reads `vehicleProfileListProvider`.
                await context.push<void>('/vehicles/edit');
              },
              icon: const Icon(Icons.add),
              label: Text(l10n?.vehicleAdd ?? 'Add vehicle'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.vehiclesWizardSkipHint ??
                'Skip to finish setup — you can add vehicles anytime from Settings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations? l10n, bool isEv, bool isCombustion) {
    if (isEv && isCombustion) return l10n?.vehicleTypeHybrid ?? 'Hybrid';
    if (isEv) return l10n?.vehicleTypeEv ?? 'Electric';
    return l10n?.vehicleTypeCombustion ?? 'Combustion';
  }

  String _fuelSuffix(String? fuel) {
    if (fuel == null || fuel.trim().isEmpty) return '';
    return '  •  ${fuel.toUpperCase()}';
  }
}
