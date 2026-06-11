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
// #3137 — the OBD2/BLE stack moved to features/obd2; consumption's barrel
// keeps re-exporting it so existing consumers stay source-compatible.
export '../obd2/api.dart';
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
export 'presentation/widgets/ocr_block_overlay_painter.dart';
export 'presentation/widgets/ocr_trace_steps_panel.dart';
export 'presentation/widgets/proximity_fill_bar.dart';
export 'presentation/widgets/share_receipt_listener.dart';
export 'presentation/widgets/trip_recording_banner.dart';
export 'presentation/widgets/vehicle_adapter_section.dart';
export 'presentation/widgets/vehicle_baseline_section.dart';
export 'providers/auto_record_orchestrator.dart';
export 'providers/consumption_providers.dart';
export 'providers/pending_shared_receipt_provider.dart';
export 'providers/pip_mode_provider.dart';
export 'providers/trip_history_provider.dart';
export 'providers/trip_recording_provider.dart';
export 'providers/trip_ve_recompute_provider.dart';
export 'providers/wakelock_facade.dart';
