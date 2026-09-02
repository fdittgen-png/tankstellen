// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../../core/domain/pump_gain_resolution.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../protocol/elm327_protocol.dart';
import '../../domain/fuel_mixture_model.dart';
import '../../domain/vehicle_power_state.dart';
import '../obd2_breadcrumb_collector.dart';
import 'obd2_service.dart';
import '../../domain/pid_scheduler.dart';
import '../../domain/precision_pid_latches.dart';

part 'live_sample_snapshot_latches.dart';
part 'live_sample_snapshot_subscriptions.dart';
part 'live_sample_snapshot_fuel_rate.dart';

/// The "clock"-side snapshot extracted from [TripRecordingController]
/// (#1679): the per-PID latest-value scratch space, the scheduler
/// subscription wiring that fills it, and the tier-1/2/3 fuel-rate
/// derivation that reads it.
///
/// The controller keeps the emit timer + `_emit` itself — that path
/// entangles lifecycle flags, the recorder, and the fuel accumulators.
/// This collaborator is the safe core of the split: it owns the
/// values, the controller reads them once per emit tick.
///
/// Scheduler callbacks push high-priority parse outcomes back through
/// [_onHighPriorityParse] (the controller's silent-failure observer)
/// and vehicle-speed samples through [_onSpeedSample] (the controller's
/// virtual-odometer buffer), so this class carries no drop-detection
/// or distance state of its own.
///
/// #3760 — decomposed under the #1680 file-length cap into `part`
/// mixins (move-only): the latest-value latches + getters
/// (`live_sample_snapshot_latches.dart`), the cadence-tier scheduler
/// wiring (`live_sample_snapshot_subscriptions.dart`) and the fuel-rate
/// derivation (`live_sample_snapshot_fuel_rate.dart`). This file keeps
/// the constructor-owned collaborators.
class LiveSampleSnapshot
    with
        _LiveSampleSnapshotLatches,
        _LiveSampleSnapshotSubscriptions,
        _LiveSampleSnapshotFuelRate {
  LiveSampleSnapshot({
    required this._service,
    this._vehicle,
    this._referenceVehicle,
    this._breadcrumbCollector,
    required this._onHighPriorityParse,
    required this._onSpeedSample,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _precision = PrecisionPidLatches(clock: clock);

  /// #3784 — point the snapshot at the freshly-reconnected service after
  /// a mid-trip rebind (`replaceService` swaps only the controller's
  /// pointer): the per-PID support gates and any snapshot-side reads
  /// must evaluate against the LIVE service's state, not the dead
  /// original's.
  void rebindService(Obd2Service service) => _service = service;

  @override
  Obd2Service _service;
  @override
  final VehicleProfile? _vehicle;
  @override
  final ReferenceVehicle? _referenceVehicle;
  @override
  final Obd2BreadcrumbRecorder? _breadcrumbCollector;
  @override
  final void Function(Object? parsedValue) _onHighPriorityParse;
  @override
  final void Function(double speedKmh) _onSpeedSample;
  // #2505 — IAT-staleness clock (test seam).
  @override
  final DateTime Function() _clock;

  // Epic #3416 — latches + subscriptions for the precision PID families
  // (measured wideband φ #3427, MAF 0x66 / fuel-rate 0x9D / 0xA2 #3428,
  // ethanol 0x52 #3429). A collaborator so this grandfathered file grows
  // by a field + one subscribe call, not by twenty latches.
  @override
  final PrecisionPidLatches _precision;
}
