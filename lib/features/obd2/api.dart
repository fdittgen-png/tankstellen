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

export 'data/active_trip_repository.dart';
export 'data/active_trip_sample_wal.dart';
export 'data/protocol/adapter_capability.dart';
export 'data/protocol/adapter_registry.dart';
export 'data/transport/android_background_adapter_listener.dart';
export 'data/session/auto_trip_coordinator.dart';
export 'data/transport/background_adapter_listener.dart';
export 'domain/broken_map_belief.dart';
export 'domain/broken_map_detector.dart';
export 'data/protocol/can_frame_decoders/psa_fuel_level_can_decoder.dart';
// #3437 — the consumption trip-start path fires the CDM association
// trigger through this barrel (the one sanctioned growth: a NEW
// cross-feature seam, not a legacy reach-in).
export 'data/session/companion_auto_record_coordinator.dart';
export 'data/protocol/elm327_protocol.dart';
export 'data/transport/ios_background_adapter_listener.dart';
export 'data/transport/ios_state_restoration_provider.dart';
export 'data/transport/ios_state_restoration_service.dart';
export 'data/obd2_comm_diagnostics.dart';
export 'data/obd2_connect_trace.dart';
export 'data/obd2_connect_trace_log.dart';
export 'domain/obd2_connection_errors.dart';
export 'data/session/obd2_connection_service.dart';
export 'data/session/obd2_disconnect_quietly.dart';
export 'data/transport/obd2_permissions.dart';
export 'data/obd2_read_telemetry.dart';
export 'data/session/obd2_link_supervisor.dart';
export 'data/session/obd2_reattach_source.dart';
// #3743 — the self-test DRIVER is internal (the app shell and the obd2
// controller drive it); external consumers only render the REPORT types.
export 'data/session/obd2_self_test_report.dart';
export 'data/session/obd2_service.dart';
export 'data/obd2_session_diagnostic.dart';
export 'data/obd2_trip_evidence.dart';
export 'data/obd_adapter_blocklist.dart';
export 'data/protocol/oem_pid_registry.dart';
export 'data/protocol/oem_pid_table.dart';
export 'data/paused_trip_repository.dart';
export 'domain/trip_distance_source.dart';
export 'domain/trip_live_reading.dart';
export 'domain/rolling_consumption_window.dart'; // #3883
// #3855 — the vehicle power state (engine / ignition on-off) is a NEW
// cross-feature contract: the trips surfaces key their copy and actions on
// it (the same sanctioned-growth shape as the #3437 / #3743 seams).
export 'domain/vehicle_power_state.dart';
export 'providers/vehicle_power_provider.dart';
export 'data/session/trip_recording_controller.dart';
// #3743 — the TripRecordingController inversion seam (epic item 2): a NEW
// cross-feature contract (consumption implements the obd2-owned overlay
// interface), the same sanctioned-growth shape as the #3437 CDM seam.
export 'data/session/trip_recording_sink.dart';
export 'domain/services/obd2_analytics_signals.dart';
export 'presentation/obd2_connection_reset_action.dart';
export 'presentation/obd2_connect_telemetry.dart';
export 'presentation/obd2_connection_error_l10n.dart';
export 'presentation/widgets/obd2_adapter_picker.dart';
export 'presentation/widgets/obd2_breadcrumb_overlay.dart';
export 'presentation/widgets/obd2_connect_trace_card.dart';
export 'presentation/widgets/obd2_diagnostics_card.dart';
export 'presentation/widgets/obd2_diagnostics_trip_card.dart';
export 'presentation/widgets/obd2_pause_banner.dart';
export 'presentation/widgets/obd2_status_chip.dart';
export 'presentation/widgets/obd2_status_dot.dart';
export 'providers/current_obd2_fuel_level_provider.dart';
export 'providers/obd2_capability_provider.dart';
export 'providers/obd2_connect_trace_revision_provider.dart';
export 'providers/obd2_connection_state_provider.dart';
export 'providers/obd2_debug_logging_provider.dart';
export 'providers/obd2_reconnect_provider.dart';
export 'providers/obd2_recording_pipeline.dart';
export 'providers/obd2_self_test_controller.dart';
