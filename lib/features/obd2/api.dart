// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `obd2` feature (#3132, #3137).
///
/// Cross-feature consumers must import THIS file — never a path
/// under `providers/`, `data/`, `domain/` or `presentation/` of
/// another feature. Enforced by `test/lint/feature_boundary_test.dart`
/// with an only-decreasing baseline (epic #3129).
///
/// The export list below is the de-facto contract measured when the
/// OBD2/BLE stack was extracted out of `consumption` (#3137) — every
/// moved file that other features imported at the time. It should only
/// ever SHRINK as cross-feature reach-ins are inverted or moved to
/// `lib/core/`.
library;

export 'data/active_trip_recovery_service.dart';
export 'data/active_trip_repository.dart';
export 'data/adapter_capability.dart';
export 'data/adapter_reconnect_scanner.dart';
export 'data/adapter_registry.dart';
export 'data/android_background_adapter_listener.dart';
export 'data/auto_trip_coordinator.dart';
export 'data/background_adapter_listener.dart';
export 'data/broken_map_belief.dart';
export 'data/broken_map_detector.dart';
export 'data/can_frame_decoders/psa_fuel_level_can_decoder.dart';
export 'data/elm327_protocol.dart';
export 'data/ios_background_adapter_listener.dart';
export 'data/ios_state_restoration_provider.dart';
export 'data/ios_state_restoration_service.dart';
export 'data/obd2_comm_diagnostics.dart';
export 'data/obd2_connect_trace.dart';
export 'data/obd2_connect_trace_log.dart';
export 'data/obd2_connect_trace_persistence.dart';
export 'data/obd2_connection_errors.dart';
export 'data/obd2_connection_service.dart';
export 'data/obd2_permissions.dart';
export 'data/obd2_read_telemetry.dart';
export 'data/obd2_reconnect_controller.dart';
export 'data/obd2_self_test_driver.dart';
export 'data/obd2_service.dart';
export 'data/obd2_session_diagnostic.dart';
export 'data/obd_adapter_blocklist.dart';
export 'data/oem_pid_registry.dart';
export 'data/oem_pid_table.dart';
export 'data/paused_trip_recovery_service.dart';
export 'data/paused_trip_repository.dart';
export 'data/reconnect_connector.dart';
export 'data/trip_distance_source.dart';
export 'data/trip_live_reading.dart';
export 'data/trip_recording_controller.dart';
export 'domain/services/obd2_analytics_signals.dart';
export 'presentation/obd2_connect_telemetry.dart';
export 'presentation/obd2_connection_error_l10n.dart';
export 'presentation/widgets/obd2_adapter_picker.dart';
export 'presentation/widgets/obd2_breadcrumb_overlay.dart';
export 'presentation/widgets/obd2_connect_trace_card.dart';
export 'presentation/widgets/obd2_diagnostics_card.dart';
export 'presentation/widgets/obd2_diagnostics_trip_card.dart';
export 'presentation/widgets/obd2_pause_banner.dart';
export 'presentation/widgets/obd2_reconnect_retry_banner.dart';
export 'presentation/widgets/obd2_status_chip.dart';
export 'presentation/widgets/obd2_status_dot.dart';
export 'providers/current_obd2_fuel_level_provider.dart';
export 'providers/obd2_capability_provider.dart';
export 'providers/obd2_comm_diagnostics_gate_provider.dart';
export 'providers/obd2_connect_trace_revision_provider.dart';
export 'providers/obd2_connection_state_provider.dart';
export 'providers/obd2_debug_logging_provider.dart';
export 'providers/obd2_reconnect_provider.dart';
export 'providers/obd2_recording_pipeline.dart';
export 'providers/obd2_self_test_controller.dart';
