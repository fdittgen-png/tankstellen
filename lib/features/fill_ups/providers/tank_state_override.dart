// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/domain/tank_state_provider.dart';
import '../../vehicle/api.dart';
import 'tank_level_provider.dart';

/// The real [TankState] for the active vehicle (#4146).
///
/// `tankStateProvider` is declared in core so the route screen can plan
/// without importing this feature; this is the implementation it is
/// overridden with, mirroring `realRefuelProfileProvider` (#4089).
///
/// Both halves come from the level-v2 estimate (#3645), which already
/// resolves the fill anchor, the OBD2 sensor override and the catalog
/// capacity — there is nothing to re-derive here.
final realTankStateProvider = Provider<TankState>((ref) {
  final vehicle = ref.watch(activeVehicleProfileProvider);
  if (vehicle == null) return const TankState(capacityL: null, currentL: null);
  final estimate = ref.watch(tankLevelProvider(vehicle.id));
  return TankState(
    capacityL: estimate.capacityL,
    currentL: estimate.levelL,
  );
});

/// Wires [realTankStateProvider] into the core declaration. Added to the
/// composition root's override list, the one place allowed to know both
/// sides.
List<Override> tankStateOverrides() => [
      tankStateProvider.overrideWith((ref) => ref.watch(realTankStateProvider)),
    ];
