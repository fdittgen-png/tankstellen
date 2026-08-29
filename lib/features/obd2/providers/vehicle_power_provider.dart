// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/vehicle_power_state.dart';

part 'vehicle_power_provider.g.dart';

/// #3860 (Epic #3855) — the fused vehicle power state for the UI: the
/// banners key the Reset action on it (retry-with-reset only while the
/// engine runs), the status vocabulary names it.
///
/// Republishes the process-wide model's transitions; the initial value is
/// the model's current verdict, so a widget mounting mid-drive reads the
/// right state before the first change.
@Riverpod(keepAlive: true)
class VehiclePower extends _$VehiclePower {
  @override
  VehiclePowerState build() {
    final power = Obd2VehiclePower.instance;
    final sub = power.states.listen((next) => state = next);
    ref.onDispose(sub.cancel);
    return power.state;
  }
}
