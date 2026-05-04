import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/show_electric_enabled_provider.dart';
import '../../../profile/providers/show_fuel_enabled_provider.dart';
import '../../domain/entities/fuel_type.dart';
import '../../providers/search_provider.dart';

class FuelTypeSelector extends ConsumerWidget {
  const FuelTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedFuelTypeProvider);
    final country = ref.watch(activeCountryProvider);
    var types = fuelTypesForCountry(country.code);
    // Read the central feature flags via the thin shim providers
    // (#1373 phase 3c). The legacy `UserProfile.showFuel` /
    // `showElectric` fields are still readable but their value is
    // promoted into the central feature-flag set on first launch by
    // the legacy-toggle migrator; subsequent reads go through these
    // shims so the UI stays in sync with the central state.
    final showFuel = ref.watch(showFuelEnabledProvider);
    final showElectric = ref.watch(showElectricEnabledProvider);

    if (!showElectric) {
      types = types.where((t) => t != FuelType.electric).toList();
    }
    if (!showFuel) {
      // Remove all fuel types, keep only electric
      types = types.where((t) => t == FuelType.electric).toList();
    }
    // Always include 'all' only if both fuel AND electric are enabled
    if (showFuel && showElectric) {
      if (!types.contains(FuelType.all)) types.add(FuelType.all);
    } else {
      types = types.where((t) => t != FuelType.all).toList();
    }

    // If selected type isn't available in this country, reset to 'all'
    if (!types.contains(selected)) {
      Future.microtask(() {
        ref.read(selectedFuelTypeProvider.notifier).select(FuelType.all);
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          // Localize "All" for display — other types use their canonical names
          final label = type == FuelType.all
              ? (AppLocalizations.of(context)?.allFuels ?? 'All')
              : type.displayName;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              label: 'Fuel type $label${selected == type ? ", selected" : ""}',
              child: ChoiceChip(
                avatar: selected == type
                    ? null
                    : CircleAvatar(
                        backgroundColor: FuelColors.forType(type),
                        radius: 6,
                      ),
                label: Text(label),
                selected: selected == type,
                onSelected: (_) {
                  ref.read(selectedFuelTypeProvider.notifier).select(type);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
