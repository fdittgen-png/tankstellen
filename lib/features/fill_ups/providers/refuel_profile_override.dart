// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/refuel_economics.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/refuel_quantity_provider.dart';
import '../../../core/time/app_clock.dart';
import '../../vehicle/api.dart';
import '../domain/services/price_baseline.dart';
import 'consumption_providers.dart';
import 'fuel_type_efficiency_provider.dart';

/// The real [RefuelProfile], built from what the user has measured
/// (#4089).
///
/// `refuelProfileProvider` is declared in core so the results screen can
/// read it without importing this feature; this is the implementation it
/// is overridden with at the composition root.
///
///  * **Consumption** comes from the fill-up history
///    (`ConsumptionStats.avgConsumptionL100km`) — a measurement, not a
///    model. When there is none the profile stays empty and the engine
///    withholds Best Value rather than inventing a number.
///  * **Quantity** is the MEDIAN of the user's own fill volumes, so the
///    default is personal from the first few fills and one
///    splash-and-dash or jerrycan cannot skew it. No question is asked
///    of the user to get a correct answer.
///
///    #4150 — that median is the WINDOWED one from [PriceBaseline] when
///    the driver has enough recent history, falling back to the
///    all-history median otherwise. Two medians existed: this provider
///    averaged every fill ever logged while the savings ledger used a
///    90-day window, so "your usual fill" was a different number
///    depending on which screen asked. Tank sizes and habits change; the
///    windowed figure follows them and the all-time one does not.
///  * #4095 — an explicit `refuelQuantityProvider` choice wins over the
///    median when the user has made one. It is capped at the active
///    vehicle's tank capacity where a capacity is configured, because
///    the app cannot price litres the tank cannot hold; a vehicle with
///    no capacity on file is simply not capped. Capacity is a ceiling
///    here and nothing more — it never appears in the arithmetic, and is
///    never required for any of this to work (economics spec §2).
final realRefuelProfileProvider = Provider<RefuelProfile>((ref) {
  final consumption = ref.watch(consumptionStatsProvider).avgConsumptionL100km;
  // Already scoped to the active vehicle: a household with a diesel and
  // an E85 car has two habits, and mixing them makes both wrong.
  final fills = ref.watch(activeVehicleFillUpsProvider);
  final fuel = ref.watch(activeVehicleProfileProvider)?.preferredFuelType;
  final baseline = (fuel == null || fuel.isEmpty)
      ? null
      : priceBaselineFor(
          fills,
          fuelType: FuelType.fromString(fuel),
          now: ref.watch(appClockProvider).now(),
        );
  final median = baseline?.typicalLitres ??
      RefuelEconomics.medianLitres(fills.map((f) => f.liters));
  final chosen = ref.watch(refuelQuantityProvider);
  final capacity = ref.watch(activeVehicleProfileProvider)?.tankCapacityL;
  final litres = chosen ?? median ?? kDefaultRefuelLitres;
  return RefuelProfile(
    consumptionLPer100km: consumption,
    litresIntended: (capacity != null && capacity > 0)
        ? math.min(litres, capacity)
        : litres,
  );
});

/// Wires [realRefuelProfileProvider] into the core declaration. Added to
/// the composition root's override list (`AppInitializer`), which is the
/// one place allowed to know both sides.
List<Override> refuelProfileOverrides() => [
      refuelProfileProvider
          .overrideWith((ref) => ref.watch(realRefuelProfileProvider)),
    ];
