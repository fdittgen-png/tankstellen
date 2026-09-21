// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel/fuel_grade.dart';
import '../../../core/domain/fuel/next_fill_request.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../favorites/api.dart';
import '../../search/api.dart';
import '../../vehicle/api.dart';
import '../domain/services/fuel_and_tank_view.dart';
import '../domain/services/next_fill_offers.dart';
import '../domain/services/vehicle_fuel_capability_policy.dart';
import 'fuel_behaviour_provider.dart';
import 'next_fill_decision_provider.dart';
import 'tank_blend_provider.dart';

part 'fuel_and_tank_provider.g.dart';

/// What the next fill should optimise (#4278), persisted in the settings
/// box as the [FillObjective] name. Defaults to lowest cost per km; a
/// name this build does not know falls back to the default too.
@riverpod
class FillObjectiveSetting extends _$FillObjectiveSetting {
  @override
  FillObjective build() {
    final raw = ref.watch(storageRepositoryProvider)
        .getSetting(StorageKeys.fillObjective);
    return FillObjective.values.where((o) => o.name == raw).firstOrNull ??
        FillObjective.lowestCostPerKm;
  }

  Future<void> set(FillObjective objective) async {
    await ref
        .read(storageRepositoryProvider)
        .putSetting(StorageKeys.fillObjective, objective.name);
    state = objective;
  }
}

/// The approvals [vehicleId]'s profile vouches for (#4278) — see
/// [vehicleFuelCapabilityOf], which reads the persisted declared grades
/// (#4324).
@riverpod
VehicleFuelCapability vehicleFuelCapability(Ref ref, String vehicleId) =>
    vehicleFuelCapabilityOf(_vehicle(ref, vehicleId));

/// The offers for the priceable grades, from prices the app ALREADY holds
/// — opening the surface never costs a network call.
///
/// #4324 — the last search's results come first: each station carries its
/// distance, so the decision prices the detour (`RefuelEconomics`).
/// Reading [searchStateProvider] never searches; with no search this
/// session it is empty. Only then the favourite stations' cached prices
/// (#4278), which carry no distance, so no detour is priced. The two are
/// never mixed: a detour-free favourite would undercut every priced one.
@riverpod
List<FuelOffer> nextFillOffers(Ref ref, String vehicleId) {
  final grades = priceableGradesOf(_vehicle(ref, vehicleId));
  final nearby = nearbySearchOffers(
      grades, ref.watch(searchStateProvider).value?.data ?? const []);
  if (nearby.isNotEmpty) return nearby;
  return favouriteOffers(
      grades, ref.watch(favoriteStationsProvider).value?.data ?? const []);
}

/// The decision request for [vehicleId]: objective, capability, offers.
/// Value-equal, so the decision provider recomputes only when one of them
/// actually changes.
@riverpod
NextFillRequest nextFillRequest(Ref ref, String vehicleId) => NextFillRequest(
      objective: ref.watch(fillObjectiveSettingProvider),
      capability: ref.watch(vehicleFuelCapabilityProvider(vehicleId)),
      offers: ref.watch(nextFillOffersProvider(vehicleId)),
    );

/// Everything the Fuel & Tank surface renders for [vehicleId] (#4278),
/// from the canonical providers: the evidence-only tank blend (#4279),
/// the learned behaviour profile (#4276) and the next-fill decision
/// (#4277).
@riverpod
FuelAndTankView fuelAndTankView(Ref ref, String vehicleId) {
  final vehicle = _vehicle(ref, vehicleId);
  final request = ref.watch(nextFillRequestProvider(vehicleId));
  return buildFuelAndTankView(
    tank: ref.watch(tankBlendProvider(vehicleId)),
    profile: ref.watch(fuelBehaviourProfileProvider(vehicleId)),
    capability: request.capability,
    configuredGrade: vehicle == null ? null : configuredGradeOf(vehicle),
    priceableGrades: priceableGradesOf(vehicle),
    request: request,
    decision: ref.watch(nextFillDecisionProvider(vehicleId, request)),
  );
}

VehicleProfile? _vehicle(Ref ref, String vehicleId) => ref
    .watch(vehicleProfileListProvider)
    .where((v) => v.id == vehicleId)
    .firstOrNull;
