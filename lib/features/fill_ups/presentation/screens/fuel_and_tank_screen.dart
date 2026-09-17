// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/api.dart';
import '../../domain/services/vehicle_fuel_capability_policy.dart';
import '../../providers/fuel_and_tank_provider.dart';
import '../widgets/fuel_and_tank/fuel_behaviour_section.dart';
import '../widgets/fuel_and_tank/fuel_compatibility_section.dart';
import '../widgets/fuel_and_tank/next_fill_section.dart';
import '../widgets/fuel_and_tank/tank_mix_section.dart';

/// The Fuel & Tank explanation surface (#4278), opened from the tank
/// level card on the Cost tab.
///
/// Answers, for the active vehicle, in reading order: what is in the tank
/// and how surely; which fuels it may take; how THIS car behaved on each
/// (evidence-labelled); what the fuel standards say in general (a
/// separate, labelled panel); and whether the next fill should change
/// fuel. Everything comes from [fuelAndTankViewProvider]; this screen only
/// lays the sections out.
class FuelAndTankScreen extends ConsumerWidget {
  const FuelAndTankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vehicle = ref.watch(activeVehicleProfileProvider);
    return PageScaffold(
      title: l.fuelAndTankTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.tooltipBack,
        onPressed: () => context.pop(),
      ),
      bodyPadding: EdgeInsets.zero,
      body: vehicle == null || !burnsLiquidFuel(vehicle)
          ? EmptyState(
              icon: Icons.local_gas_station_outlined,
              title: l.fuelAndTankNoVehicle,
            )
          : FuelAndTankBody(vehicleId: vehicle.id),
    );
  }
}

/// The scrolling sections for [vehicleId] — public so tests can pump the
/// surface without the router.
class FuelAndTankBody extends ConsumerWidget {
  const FuelAndTankBody({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(fuelAndTankViewProvider(vehicleId));
    return ListView(
      key: const Key('fuel_and_tank_list'),
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      children: [
        TankMixSection(mix: view.mix),
        FuelCompatibilitySection(compatibility: view.compatibility),
        NextFillSection(view: view.nextFill),
        FuelBehaviourSection(view: view),
        FuelFactsSection(facts: view.facts),
      ],
    );
  }
}
