// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../vehicle/api.dart';
import '../../../domain/services/vehicle_fuel_capability_policy.dart';

/// The one entry point into the Fuel & Tank surface (#4278), on the tank
/// level card. Renders nothing unless the active vehicle burns liquid
/// fuel — an EV has no tank mix to explain.
class FuelAndTankEntryButton extends ConsumerWidget {
  const FuelAndTankEntryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(activeVehicleProfileProvider);
    if (!burnsLiquidFuel(vehicle)) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const Key('fuel_and_tank_entry'),
        icon: const Icon(Icons.water_drop_outlined),
        label: Text(AppLocalizations.of(context).fuelAndTankOpenAction),
        onPressed: () => context.push(RoutePaths.fuelAndTank),
      ),
    );
  }
}
