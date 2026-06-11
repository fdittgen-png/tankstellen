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
export 'data/driving_score_calculator.dart';
export 'data/obd2/active_trip_recovery_service.dart';
export 'data/obd2/active_trip_repository.dart';
export 'data/obd2/adapter_capability.dart';
export 'data/obd2/adapter_registry.dart';
export 'data/obd2/broken_map_belief.dart';
export 'data/obd2/broken_map_detector.dart';
export 'data/obd2/elm327_protocol.dart';
export 'data/obd2/event_channel_cancel.dart';
export 'data/obd2/ios_state_restoration_provider.dart';
export 'data/obd2/obd2_comm_diagnostics.dart';
export 'data/obd2/obd2_connect_trace.dart';
export 'data/obd2/obd2_connect_trace_log.dart';
export 'data/obd2/obd2_connect_trace_persistence.dart';
export 'data/obd2/obd2_connection_service.dart';
export 'data/obd2/obd2_read_telemetry.dart';
export 'data/obd2/obd2_self_test_driver.dart';
export 'data/obd2/obd2_service.dart';
export 'data/obd2/obd2_session_diagnostic.dart';
export 'data/obd2/obd_adapter_blocklist.dart';
export 'data/obd2/paused_trip_recovery_service.dart';
export 'data/obd2/paused_trip_repository.dart';
export 'data/obd2/trip_live_reading.dart';
export 'data/ocr/ocr_geometry.dart';
export 'data/ocr/ocr_trace_package.dart';
export 'data/ocr/ocr_trace_recorder.dart';
export 'data/ocr/ocr_trace_serializer.dart';
export 'data/ocr/pump_ocr_config.dart';
export 'data/pip_controller.dart';
export 'data/receipt_scan_service.dart';
export 'data/trip_history_repository.dart';
export 'domain/direct_fuel_rate_detector.dart';
export 'domain/driving_coaching.dart';
export 'domain/entities/fill_up.dart';
export 'domain/harsh_event.dart';
export 'domain/services/speed_consumption_histogram.dart';
export 'domain/services/trip_length_aggregator.dart';
export 'domain/trip_recorder.dart';
export 'presentation/screens/add_charging_log_screen.dart';
export 'presentation/screens/add_fill_up_screen.dart';
export 'presentation/screens/consumption_screen.dart';
export 'presentation/screens/consumption_statistics_screen.dart';
export 'presentation/screens/pick_station_for_fill_up_screen.dart';
export 'presentation/screens/pump_display_camera_screen.dart';
export 'presentation/screens/trip_detail_screen.dart';
export 'presentation/screens/trip_recording_screen.dart';
export 'presentation/widgets/broken_map_widgets.dart';
export 'presentation/widgets/obd2_adapter_picker.dart';
export 'presentation/widgets/obd2_connect_trace_card.dart';
export 'presentation/widgets/obd2_diagnostics_card.dart';
export 'presentation/widgets/ocr_block_overlay_painter.dart';
export 'presentation/widgets/ocr_trace_steps_panel.dart';
export 'presentation/widgets/proximity_fill_bar.dart';
export 'presentation/widgets/share_receipt_listener.dart';
export 'presentation/widgets/trip_recording_banner.dart';
export 'presentation/widgets/vehicle_adapter_section.dart';
export 'presentation/widgets/vehicle_baseline_section.dart';
export 'providers/auto_record_orchestrator.dart';
export 'providers/consumption_providers.dart';
export 'providers/obd2_capability_provider.dart';
export 'providers/obd2_comm_diagnostics_gate_provider.dart';
export 'providers/obd2_connect_trace_revision_provider.dart';
export 'providers/obd2_debug_logging_provider.dart';
export 'providers/obd2_self_test_controller.dart';
export 'providers/pending_shared_receipt_provider.dart';
export 'providers/pip_mode_provider.dart';
export 'providers/trip_history_provider.dart';
export 'providers/trip_recording_provider.dart';
export 'providers/trip_ve_recompute_provider.dart';
export 'providers/wakelock_facade.dart';
