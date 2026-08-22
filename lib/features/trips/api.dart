// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `trips` feature (#3743, epic item 1).
///
/// Extracted from the `consumption` mega-feature (step 5/5 of the split,
/// refile of the half-done #3136): trip recording (pipeline, isolate
/// host, WAL, GPS/IMU fusion, live activity, PiP), trip history +
/// detail, trip domain models (samples, summaries, verdicts, baselines)
/// and the trips/baselines/trip_shares sync configs.
///
/// #3739 — the ONE canonical TripSummary/TripSample codec lives here.
/// The obd2 feature's WAL (active) + paused trip repositories delegate
/// to these functions through this barrel (the boundary test's
/// sanctioned seam) instead of maintaining drifted private copies.
///
/// Cross-feature consumers must import THIS file — never a path under
/// `data/`, `domain/`, `providers/` or `presentation/` of this feature.
/// Enforced by `test/lint/feature_boundary_test.dart` (epic #3129). The
/// export list is the contract measured at extraction time — wide, as
/// befits the former hub of 19 feature cycles; epic #3743 item 3
/// (barrel pruning) and item 2 (the TripSink inversion) shrink it. It
/// should only ever SHRINK.
library;

export 'data/baseline_sync.dart';
export 'data/baselines_sync.dart';
export 'data/pip_controller.dart';
export 'data/trip_dedup.dart';
export 'data/trip_history_repository.dart';
export 'data/trip_sample_codec.dart';
export 'data/trip_summary_codec.dart';
export 'data/trips_sync.dart';
export 'domain/accel_event_gate.dart';
export 'domain/climb_restart_detector.dart';
export 'domain/cold_start_baselines.dart';
export 'domain/direct_fuel_rate_detector.dart';
export 'domain/engine_power_factor.dart';
export 'domain/entities/gps_sample_diagnostic.dart';
export 'domain/entities/trip_save_stage.dart';
export 'domain/fuel_event_attribution.dart';
export 'domain/gps_coverage_report.dart';
export 'domain/gps_driving_features.dart';
export 'domain/gps_track_distance.dart';
export 'domain/harsh_event.dart';
export 'domain/obd2_engine_coverage.dart';
export 'domain/obd2_trip_features.dart';
export 'domain/services/engine_off_transport.dart';
export 'domain/services/gear_inference.dart';
export 'domain/services/gps_live_estimate_folder.dart';
export 'domain/services/gps_live_fuel_estimator.dart';
export 'domain/services/gps_matrix_reconciler.dart';
export 'domain/services/speed_consumption_histogram.dart';
export 'domain/services/trip_consumed_liters.dart';
export 'domain/services/trip_consumption_reliability.dart';
export 'domain/services/trip_length_aggregator.dart';
export 'domain/situation_classifier.dart';
export 'domain/trip_recorder.dart';
export 'domain/trip_sample.dart';
export 'domain/trip_summary.dart';
export 'presentation/screens/trajets_map_screen.dart';
export 'presentation/screens/trip_detail_screen.dart';
export 'presentation/screens/trip_recording_screen.dart';
export 'presentation/widgets/broken_map_widgets.dart';
export 'presentation/widgets/proximity_fill_bar.dart';
export 'presentation/widgets/trajets_record_fab.dart';
export 'presentation/widgets/trajets_tab.dart';
export 'presentation/widgets/trip_detail_charts.dart';
export 'presentation/widgets/trip_recording_banner.dart';
export 'presentation/widgets/vehicle_adapter_section.dart';
export 'presentation/widgets/vehicle_baseline_section.dart';
export 'providers/auto_record_orchestrator.dart';
export 'providers/pip_mode_provider.dart';
export 'providers/reconnect_scanner_factory.dart';
export 'providers/recording_pipeline.dart';
export 'providers/reference_vehicle_match.dart';
export 'providers/trip_baseline_recorder.dart';
export 'providers/trip_gps_stream_controller.dart';
export 'providers/trip_haptic_controller.dart';
export 'providers/trip_history_provider.dart';
export 'providers/trip_oem_fuel_level_controller.dart';
export 'providers/trip_recording_phase.dart';
export 'providers/trip_recording_provider.dart';
export 'providers/trip_recording_state.dart';
export 'providers/trip_tile_action_listener_provider.dart';
export 'providers/trip_ve_recompute_provider.dart';
export 'providers/wakelock_facade.dart';
