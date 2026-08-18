// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `consumption` feature (#3132).
///
/// Cross-feature consumers must import THIS file — never a path
/// under `providers/`, `data/`, `domain/` or `presentation/` of
/// another feature. Enforced by `test/lint/feature_boundary_test.dart`
/// with an only-decreasing baseline (epic #3129).
///
/// The export list below is the de-facto contract measured when the
/// barrel was introduced — every file of this feature that other
/// features imported at the time. It should only ever SHRINK as
/// cross-feature reach-ins are inverted or moved to `lib/core/`.
library;

export 'data/baseline_sync.dart';
// #3743 (epic item 5) — the per-entity sync configs moved home from
// lib/core/sync; exported so cross-feature consumers (device linking,
// data transparency) keep going through the barrel.
export 'data/trips_sync.dart';
export 'data/driving_score_calculator.dart';
// #3743 — the #3137 source-compat re-export of ../obd2/api.dart is gone:
// consumers of the OBD2 stack import features/obd2/api.dart directly.
export 'data/pip_controller.dart';
export 'data/trip_history_repository.dart';
// #3739 — the ONE canonical TripSummary/TripSample codec. The obd2
// feature's WAL (active) + paused trip repositories delegate to these
// functions through this barrel (the boundary test's sanctioned seam)
// instead of maintaining the drifted private copies that were silently
// dropping 13-16 summary keys on crash/pause rehydrate.
export 'data/trip_sample_codec.dart';
export 'data/trip_summary_codec.dart';
export 'domain/direct_fuel_rate_detector.dart';
export 'domain/driving_coaching.dart';
export 'domain/harsh_event.dart';
export 'domain/services/speed_consumption_histogram.dart';
export 'domain/services/trip_length_aggregator.dart';
export 'domain/trip_recorder.dart';
export 'presentation/screens/add_charging_log_screen.dart';
export 'presentation/screens/consumption_screen.dart';
export 'presentation/screens/trip_detail_screen.dart';
export 'presentation/screens/trip_recording_screen.dart';
export 'presentation/widgets/broken_map_widgets.dart';
export 'presentation/widgets/proximity_fill_bar.dart';
export 'presentation/widgets/trip_recording_banner.dart';
export 'presentation/widgets/vehicle_adapter_section.dart';
export 'presentation/widgets/vehicle_baseline_section.dart';
export 'providers/auto_record_orchestrator.dart';
export 'providers/pip_mode_provider.dart';
export 'providers/trip_history_provider.dart';
export 'providers/trip_recording_provider.dart';
export 'providers/trip_ve_recompute_provider.dart';
export 'providers/wakelock_facade.dart';
