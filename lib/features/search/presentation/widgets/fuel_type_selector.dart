// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/show_electric_enabled_provider.dart';
import '../../../profile/providers/show_fuel_enabled_provider.dart';
import '../../../../core/domain/fuel_type.dart';
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
      unawaited(
        Future.microtask(() {
          ref.read(selectedFuelTypeProvider.notifier).select(FuelType.all);
        }),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          // Localize "All" for display — other types use their canonical names
          final label = type == FuelType.all
              ? (AppLocalizations.of(context).allFuels)
              : type.displayName;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              label: AppLocalizations.of(
                context,
              ).fuelTypeSemantic(label, '${selected == type}'),
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
                  // #2974 — a selection tick on the per-fuel chip re-search,
                  // matching the everyday tap-surface haptics. selectionClick
                  // only (never heavyImpact); never fires on scroll because
                  // ChoiceChip.onSelected is a discrete tap, not a drag.
                  unawaited(HapticFeedback.selectionClick());
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
