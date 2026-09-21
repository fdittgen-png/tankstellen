// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel_type.dart';
import '../../../core/time/app_clock.dart';
import '../domain/entities/fill_up.dart';
import '../domain/services/savings_ledger.dart';
import 'fuel_type_efficiency_provider.dart';
import '../../vehicle/api.dart';

part 'savings_provider.g.dart';

/// What the active vehicle saved against its own normal price (#4136).
///
/// Derived from the fill-ups rather than stored, so it can never drift
/// from them — see [SavingsLedger] for why that was the better call than
/// the Hive box the issue proposed.
@riverpod
SavingsLedger savingsLedger(Ref ref) {
  final List<FillUp> fills = ref.watch(activeVehicleFillUpsProvider);
  final vehicle = ref.watch(activeVehicleProfileProvider);
  final preferred = vehicle?.preferredFuelType;
  // No vehicle, or no fuel on it, means there is nothing to compare
  // against — an E85 fill measured on a diesel baseline would be
  // arithmetic, not a saving.
  if (preferred == null || preferred.isEmpty) {
    return const SavingsLedger.unavailable();
  }
  return savingsLedgerFor(
    fills,
    fuelType: FuelType.fromString(preferred),
    now: ref.watch(appClockProvider).now(),
  );
}
