// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/api.dart';
import '../../../profile/providers/show_electric_enabled_provider.dart';
import '../../../profile/providers/show_fuel_enabled_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/services/country_service_registry.dart'
    show fuelTypesForCountry;
import '../../providers/search_provider.dart';
import 'criteria/criteria_chip_group.dart';

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
    // Feature.evCharging finally gates the EV search entry (2026-08-17
    // review, dead-code finding 6): the electric chip needs BOTH the
    // per-profile showElectric visibility toggle AND the central
    // EV-charging feature. Both default on, so behavior is unchanged
    // until the user disables one.
    final showElectric = ref.watch(showElectricEnabledProvider) &&
        ref.watch(enabledFeaturesProvider).contains(Feature.evCharging);

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

    // #3927 — the selection must ALWAYS be visible. The old horizontal
    // scroller could park the selected chip (E85 on the French set) past
    // the right edge, so the sheet showed no answer to "which fuel am I
    // searching for?". Ordering the selected type first, wrapping the rest
    // onto as many rows as they need, and folding anything past the eighth
    // behind "Show more" keeps the answer on the first row at every width.
    final ordered = <FuelType>[
      ...types.where((t) => t == selected),
      ...types.where((t) => t != selected),
    ];

    return CriteriaChipGroup(
      groupKeyPrefix: 'criteria-fuel',
      collapsedCount: 8,
      selectedFlags: [for (final type in ordered) type == selected],
      chips: [for (final type in ordered) _chip(context, ref, type, selected)],
    );
  }

  Widget _chip(
    BuildContext context,
    WidgetRef ref,
    FuelType type,
    FuelType selected,
  ) {
    // Localize "All" for display — other types use their canonical names
    final label = type == FuelType.all
        ? (AppLocalizations.of(context).allFuels)
        : type.displayName;
    return Semantics(
      label: AppLocalizations.of(
        context,
      ).fuelTypeSemantic(label, '${selected == type}'),
      child: ChoiceChip(
        key: ValueKey('criteria-fuel-${type.name}'),
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
          // only (never heavyImpact); never fires on a drag because
          // ChoiceChip.onSelected is a discrete tap.
          unawaited(HapticFeedback.selectionClick());
          ref.read(selectedFuelTypeProvider.notifier).select(type);
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
