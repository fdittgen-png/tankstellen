// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/domain/refuel_economics.dart';
import '../../../core/domain/refuel_profile_provider.dart';
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
final realRefuelProfileProvider = Provider<RefuelProfile>((ref) {
  final consumption = ref.watch(consumptionStatsProvider).avgConsumptionL100km;
  final median = RefuelEconomics.medianLitres(
    ref.watch(activeVehicleFillUpsProvider).map((f) => f.liters),
  );
  return RefuelProfile(
    consumptionLPer100km: consumption,
    litresIntended: median ?? kDefaultRefuelLitres,
  );
});

/// Wires [realRefuelProfileProvider] into the core declaration. Added to
/// the composition root's override list (`AppInitializer`), which is the
/// one place allowed to know both sides.
List<Override> refuelProfileOverrides() => [
      refuelProfileProvider
          .overrideWith((ref) => ref.watch(realRefuelProfileProvider)),
    ];
