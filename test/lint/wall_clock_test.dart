// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet: raw `DateTime.now()` reads may only ever DECREASE (#3660,
/// llmwiki page 26 — the injectable clock).
///
/// ## Why this exists
///
/// A widget or service that reads the wall clock directly agrees with
/// the calendar of the machine that runs it — which is how a sibling
/// project got CI that was green on the 28th and red on the 1st with
/// no commits in between. The seam is `AppClock`
/// (`lib/core/time/app_clock.dart`): production reads
/// `ref.watch(appClockProvider)` / an injected `AppClock`; tests pin a
/// `FixedClock` at a mid-month Wednesday.
///
/// ## The ratchet
///
/// The baseline map below pins every file that still reads the wall clock raw to
/// its call-site count at adoption (2026-08-02: 274 files, 661 reads,
/// lib/ AND test/ — either half alone re-arms the time bomb: a widget
/// on the wall clock ignores a pinned test clock, a test seeding from
/// the wall clock disagrees with the pin).
///
/// * A file ABOVE its baseline count fails — new code uses the seam.
/// * A file BELOW its baseline count fails too — lock the improvement
///   in by lowering (or deleting) its entry, so it can never regress.
///
/// Legitimate permanent wall-clock reads (cache expiry against real
/// time, log/trace timestamps, OS scheduling) stay in the baseline
/// deliberately — the goal is that every read is a *decision*, not a
/// habit. `SystemClock.now()` itself is the seam's one exempt read.
void main() {
  const exempt = <String>{
    // The seam's own production read.
    'lib/core/time/app_clock.dart',
  };

  final raw = RegExp(r'DateTime\.now\(\)');

  const baseline = <String, int>{
    'lib/core/background/hive_isolate_lock.dart': 4,
    'lib/core/background/provider_request_budget.dart': 3,
    'lib/core/cache/cache_manager.dart': 3,
    'lib/core/country/country_switch_listener.dart': 2,
    'lib/core/country/country_time.dart': 4,
    'lib/core/feedback/github_issue_reporter/error_report_payload.dart': 1,
    'lib/core/location/user_position_provider.dart': 1,
    'lib/core/logging/error_logger.dart': 1,
    'lib/core/perf/startup_timer.dart': 2,
    'lib/core/perf/startup_trace_export.dart': 2,
    'lib/core/sensors/imu_sensor_source.dart': 2,
    'lib/core/services/diagnostics/data_access_recorder.dart': 2,
    'lib/core/services/geocoding_chain.dart': 6,
    'lib/core/services/impl/demo_station_service.dart': 4,
    // #3668 decomposition: 6 reads split 3/3 with the keyed mixin —
    // a move, not a widening (total unchanged).
    'lib/core/services/mixins/cached_dataset_mixin.dart': 3,
    'lib/core/services/mixins/keyed_cached_dataset_mixin.dart': 3,
    'lib/core/services/mixins/station_service_helpers.dart': 2,
    'lib/core/services/radar/highway_mode_provider.dart': 1,
    'lib/core/services/rate_limit_interceptor.dart': 1,
    'lib/core/services/service_result.dart': 1,
    // #3668 decomposition: 4 reads split 2/2 with the coalescing part.
    'lib/core/services/station_service_chain.dart': 2,
    'lib/core/services/station_service_chain_coalescing.dart': 2,
    'lib/core/services/widgets/freshness_badge.dart': 1,
    'lib/core/storage/stores/cache_hive_store.dart': 2,
    'lib/core/sync/baselines_sync.dart': 1,
    'lib/core/sync/deletions_sync.dart': 1,
    'lib/core/sync/entity_sync.dart': 1,
    'lib/core/sync/itineraries_sync.dart': 5,
    'lib/core/sync/price_history_sync.dart': 1,
    'lib/core/sync/ratings_sync.dart': 2,
    'lib/core/sync/trips_sync.dart': 4,
    'lib/core/telemetry/collectors/breadcrumb_collector.dart': 1,
    'lib/core/telemetry/storage/isolate_error_spool.dart': 1,
    'lib/core/telemetry/storage/startup_failure_store.dart': 1,
    'lib/core/telemetry/storage/trace_storage.dart': 2,
    'lib/core/telemetry/trace_recorder.dart': 1,
    'lib/features/achievements/providers/achievements_provider.dart': 1,
    'lib/features/alerts/background/background_alert_scan_coordinator.dart': 2,
    'lib/features/alerts/data/repositories/alert_repository.dart': 1,
    'lib/features/alerts/data/test_alert_runner.dart': 1,
    'lib/features/alerts/presentation/widgets/create_alert_dialog.dart': 1,
    'lib/features/alerts/presentation/widgets/radius_alert_create_sheet.dart': 1,
    'lib/features/alerts/providers/alert_statistics_provider.dart': 1,
    'lib/features/approach/providers/fuel_station_radar_provider.dart': 1,
    'lib/features/car/car_fix_store.dart': 1,
    'lib/features/consumption/data/ocr/ocr_trace_recorder.dart': 1,
    'lib/features/consumption/data/ocr/receipt_pdf_rasterizer.dart': 1,
    'lib/features/consumption/domain/entities/gps_sample_diagnostic.dart': 1,
    'lib/features/consumption/domain/services/gps_matrix_reconciler.dart': 1,
    'lib/features/consumption/domain/services/monthly_insights_aggregator.dart': 2,
    'lib/features/consumption/domain/services/motion_gate.dart': 1,
    'lib/features/consumption/presentation/screens/add_charging_log_screen.dart': 3,
    'lib/features/consumption/presentation/screens/add_fill_up_screen.dart': 3,
    'lib/features/consumption/presentation/screens/pump_display_camera_screen.dart': 1,
    'lib/features/consumption/presentation/screens/trip_detail_screen.dart': 1,
    'lib/features/consumption/presentation/screens/trip_recording_screen.dart': 3,
    'lib/features/consumption/presentation/widgets/driving_analysis_trace_card.dart': 1,
    'lib/features/consumption/presentation/widgets/eco_nudge_listener.dart': 1,
    'lib/features/consumption/presentation/widgets/edit_correction_fill_up_sheet.dart': 1,
    'lib/features/consumption/presentation/widgets/trajets_tab.dart': 1,
    'lib/features/consumption/providers/charging_charts_provider.dart': 2,
    'lib/features/consumption/providers/consumption_providers.dart': 6,
    'lib/features/consumption/providers/gps_only_recording_pipeline.dart': 4,
    'lib/features/consumption/providers/gps_only_trip_wal.dart': 2,
    'lib/features/consumption/providers/live_activity_provider.dart': 1,
    'lib/features/consumption/providers/maintenance_provider.dart': 3,
    'lib/features/consumption/providers/recording_lifecycle_marks_recorder.dart': 1,
    'lib/features/consumption/providers/tank_level_provider.dart': 1,
    'lib/features/consumption/providers/trip_gps_stream_controller.dart': 1,
    'lib/features/consumption/providers/trip_recording_provider.dart': 10,
    'lib/features/ev/data/services/fr_irve_price_service.dart': 2,
    'lib/features/ev/data/services/open_charge_map_service.dart': 1,
    'lib/features/favorites/presentation/screens/favorites_screen.dart': 2,
    'lib/features/favorites/providers/favorite_stations_provider.dart': 7,
    'lib/features/itinerary/providers/itinerary_provider.dart': 4,
    'lib/features/loyalty/presentation/widgets/loyalty_add_card_sheet.dart': 2,
    'lib/features/map/data/retry_network_tile_provider.dart': 1,
    'lib/features/map/presentation/screens/map_screen.dart': 2,
    'lib/features/obd2/data/auto_record_trace_log.dart': 2,
    'lib/features/obd2/data/auto_trip_coordinator.dart': 1,
    'lib/features/obd2/data/broken_map_belief_updater.dart': 1,
    'lib/features/obd2/data/broken_map_detector.dart': 1,
    'lib/features/obd2/data/classic_elm_channel.dart': 2,
    'lib/features/obd2/data/fake_background_adapter_listener.dart': 3,
    'lib/features/obd2/data/obd2_breadcrumb_collector.dart': 1,
    'lib/features/obd2/data/obd2_connect_trace_handle.dart': 1,
    'lib/features/obd2/data/obd2_debug_session_recorder.dart': 2,
    'lib/features/obd2/data/obd2_diagnostic_report.dart': 1,
    'lib/features/obd2/data/obd2_self_test_steps.dart': 4,
    'lib/features/obd2/providers/obd2_reconnect_provider.dart': 2,
    'lib/features/price_history/data/repositories/price_history_repository.dart': 2,
    'lib/features/price_history/providers/fill_up_guidance_provider.dart': 1,
    'lib/features/price_history/providers/price_recorder.dart': 1,
    'lib/features/profile/presentation/screens/developer_tools/developer_diagnostics.dart': 1,
    'lib/features/profile/presentation/screens/developer_tools/obd2_health_screen.dart': 1,
    'lib/features/profile/presentation/widgets/location_section_widget.dart': 1,
    'lib/features/profile/providers/privacy_data_provider.dart': 1,
    'lib/features/report/data/community_report_service.dart': 1,
    'lib/features/report/presentation/screens/report_submit_handler.dart': 1,
    'lib/features/route_search/data/services/routing_service.dart': 1,
    'lib/features/search/data/services/ev_charging_service.dart': 2,
    'lib/features/search/presentation/widgets/search_results_content.dart': 1,
    'lib/features/search/presentation/widgets/user_position_bar.dart': 1,
    'lib/features/search/providers/ev_search_provider.dart': 1,
    'lib/features/search/providers/road_distance_provider.dart': 1,
    'lib/features/search/providers/search_provider.dart': 1,
    'lib/features/search/providers/search_provider_orchestration.dart': 2,
    'lib/features/station_detail/domain/open_now.dart': 1,
    'lib/features/station_detail/presentation/widgets/opening_hours_view.dart': 2,
    'lib/features/station_detail/presentation/widgets/price_history_section.dart': 1,
    'lib/features/station_detail/providers/station_detail_provider.dart': 2,
    'lib/features/station_services/australia/australia_station_service.dart': 1,
    'lib/features/station_services/france/prix_carburants_flux_station_service.dart': 1,
    'lib/features/station_services/france/prix_carburants_station_service.dart': 6,
    'lib/features/station_services/germany/tankerkoenig_station_service.dart': 4,
    'lib/features/station_services/greece/greece_station_service.dart': 2,
    'lib/features/station_services/luxembourg/luxembourg_station_service.dart': 2,
    'lib/features/station_services/mexico/mexico_station_service.dart': 1,
    'lib/features/station_services/portugal/portugal_station_service.dart': 2,
    'lib/features/station_services/romania/romania_station_service.dart': 1,
    'lib/features/station_services/spain/miteco_station_service.dart': 1,
    'lib/features/station_services/uk/uk_cma_bulk_station_service.dart': 1,
    'lib/features/station_services/uk/uk_station_service.dart': 1,
    'lib/features/sync/providers/link_device_provider.dart': 1,
    'lib/features/vehicle/data/vin_adapter_pair_auto_populator.dart': 2,
    'lib/features/vehicle/data/vin_auto_populator.dart': 1,
    'lib/features/vehicle/data/vin_decoder.dart': 1,
    'lib/features/vehicle/providers/vehicle_providers.dart': 1,
    'lib/features/widget/data/home_widget_service.dart': 2,
    'lib/features/widget/data/nearest_widget_data_builder.dart': 4,
    'test/accessibility/guideline_tests.dart': 2,
    'test/accessibility/rtl_layout_test.dart': 2,
    'test/app/fresh_install_integration_test.dart': 2,
    'test/app/landing_screen_integration_test.dart': 2,
    'test/app/router_test.dart': 2,
    'test/app/shell_screen_responsive_test.dart': 2,
    'test/app/shell_screen_test.dart': 2,
    'test/app/startup/launch_sync_pulls_trips_prune_test.dart': 1,
    'test/core/background/hive_isolate_lock_test.dart': 1,
    'test/core/cache/cache_build_stamp_test.dart': 2,
    'test/core/cache/cache_manager_test.dart': 23,
    'test/core/cache/cache_strategy_test.dart': 4,
    'test/core/data/supabase_sync_repository_test.dart': 2,
    'test/core/data/sync_repository_test.dart': 1,
    'test/core/feedback/github_issue_reporter/error_report_payload_test.dart': 2,
    'test/core/location/location_service_test.dart': 2,
    'test/core/services/cancel_token_propagation_test.dart': 1,
    'test/core/services/diagnostics/data_access_chain_tap_test.dart': 2,
    'test/core/services/geocoding_chain_test.dart': 8,
    'test/core/services/location_search_service_test.dart': 2,
    'test/core/services/mixins/cached_dataset_mixin_test.dart': 1,
    'test/core/services/mixins/keyed_cached_dataset_mixin_test.dart': 1,
    'test/core/services/mixins/station_service_helpers_test.dart': 2,
    'test/core/services/persistent_dataset_test.dart': 2,
    'test/core/services/rate_limit_interceptor_test.dart': 3,
    'test/core/services/rate_limit_retry_after_test.dart': 1,
    'test/core/services/service_result_test.dart': 8,
    'test/core/services/station_search_peek_test.dart': 4,
    'test/core/services/station_service_chain_bulk_policy_test.dart': 2,
    'test/core/services/station_service_chain_edge_cases_test.dart': 6,
    'test/core/services/station_service_chain_failure_kind_test.dart': 1,
    'test/core/services/station_service_chain_new_test.dart': 6,
    'test/core/services/station_service_chain_ocm_guard_test.dart': 1,
    'test/core/services/station_service_chain_test.dart': 3,
    'test/core/services/station_service_chain_transient_retry_test.dart': 1,
    'test/core/services/widgets/freshness_badge_test.dart': 13,
    'test/core/services/widgets/service_status_banner_test.dart': 9,
    'test/core/storage/cache_schema_guard_test.dart': 1,
    'test/core/storage/hive_storage_test.dart': 2,
    'test/core/sync/sync_data_models_test.dart': 21,
    'test/core/sync/trips_sync_test.dart': 1,
    'test/core/telemetry/collectors/breadcrumb_collector_test.dart': 1,
    'test/core/telemetry/pii_scrubber_test.dart': 2,
    'test/core/telemetry/storage/trace_storage_test.dart': 6,
    'test/core/telemetry/upload/trace_uploader_test.dart': 1,
    'test/fakes/fake_hive_storage.dart': 2,
    'test/features/achievements/data/achievements_repository_test.dart': 1,
    'test/features/alerts/background/bg_scan_compliance_gate_test.dart': 2,
    'test/features/alerts/data/repositories/alert_repository_test.dart': 2,
    'test/features/consumption/comm_health_per_trip_test.dart': 1,
    'test/features/consumption/data/baseline_store_test.dart': 1,
    'test/features/consumption/data/ghost_trip_dedup_test.dart': 1,
    'test/features/consumption/data/trip_history_repository_test.dart': 1,
    'test/features/consumption/presentation/screens/trip_recording_screen_unpinned_warning_test.dart': 5,
    'test/features/consumption/presentation/widgets/trip_verdict_prompt_card_test.dart': 1,
    'test/features/consumption/providers/gps_only_backgrounding_flush_test.dart': 1,
    'test/features/consumption/providers/gps_only_imu_fusion_test.dart': 3,
    'test/features/consumption/providers/gps_only_recording_pipeline_test.dart': 1,
    'test/features/consumption/providers/gps_only_trip_wal_test.dart': 1,
    'test/features/consumption/providers/maintenance_provider_test.dart': 2,
    'test/features/consumption/providers/trip_recording_gps_diagnostics_persistence_test.dart': 1,
    'test/features/consumption/providers/trip_recording_lifecycle_marks_test.dart': 2,
    'test/features/consumption/providers/trip_recording_provider_active_snapshot_test.dart': 3,
    'test/features/consumption/providers/trip_recording_provider_automatic_flag_test.dart': 3,
    'test/features/consumption/providers/trip_recording_provider_gps_test.dart': 1,
    'test/features/consumption/providers/trip_recording_samples_persistence_test.dart': 1,
    'test/features/driving/presentation/screens/driving_mode_screen_test.dart': 1,
    'test/features/driving/providers/haptic_eco_coach_provider_test.dart': 1,
    'test/features/favorites/presentation/screens/favorites_screen_share_test.dart': 3,
    'test/features/favorites/presentation/screens/favorites_screen_test.dart': 1,
    'test/features/favorites/presentation/widgets/favorites_tab_test.dart': 1,
    'test/features/favorites/providers/favorites_provider_test.dart': 11,
    'test/features/feature_management/app_profile_provider_test.dart': 1,
    'test/features/feature_management/application/feature_toggle_notifier_test.dart': 1,
    'test/features/feature_management/application/legacy_toggle_migration_at_startup_wiring_test.dart': 1,
    'test/features/feature_management/data/app_profile_repository_test.dart': 1,
    'test/features/feature_management/data/feature_flags_repository_test.dart': 1,
    'test/features/feature_management/data/legacy_toggle_migrator_test.dart': 1,
    'test/features/feature_management/feature_flags_channel_gate_test.dart': 1,
    'test/features/feature_management/feature_flags_provider_test.dart': 1,
    'test/features/glide_coach/data/traffic_signal_repository_test.dart': 1,
    'test/features/map/nearby_map_center_test.dart': 2,
    'test/features/map/presentation/widgets/inline_map_route_test.dart': 1,
    'test/features/map/presentation/widgets/inline_map_test.dart': 2,
    'test/features/map/presentation/widgets/nearby_map_view_test.dart': 1,
    'test/features/obd2/data/active_trip_recovery_service_test.dart': 1,
    'test/features/obd2/data/active_trip_repository_test.dart': 1,
    'test/features/obd2/data/auto_record_trace_log_test.dart': 2,
    'test/features/obd2/data/dropped_session_manager_test.dart': 2,
    'test/features/obd2/data/obd2_breadcrumb_collector_test.dart': 1,
    'test/features/obd2/data/obd2_connect_trace_persistence_test.dart': 2,
    'test/features/obd2/data/obd2_connection_service_test.dart': 2,
    'test/features/obd2/data/paused_trip_recovery_service_test.dart': 1,
    'test/features/obd2/data/paused_trip_repository_test.dart': 1,
    'test/features/obd2/data/pid_scheduler_test.dart': 1,
    'test/features/obd2/data/supported_pids_cache_test.dart': 3,
    'test/features/obd2/data/trip_recording_controller_emit_summary_test.dart': 1,
    'test/features/obd2/data/trip_recording_controller_gps_degrade_test.dart': 2,
    'test/features/obd2/data/trip_recording_controller_reconnect_test.dart': 4,
    'test/features/obd2/data/trip_recording_controller_stale_engine_test.dart': 2,
    'test/features/obd2/data/trip_recording_controller_test.dart': 4,
    'test/features/obd2/obd2_link_standdown_test.dart': 1,
    'test/features/obd2/providers/obd2_recording_pipeline_test.dart': 2,
    'test/features/price_history/data/repositories/price_history_repository_test.dart': 8,
    'test/features/price_history/providers/fill_up_guidance_provider_test.dart': 2,
    'test/features/price_history/providers/price_history_provider_test.dart': 14,
    'test/features/profile/presentation/screens/developer_tools/developer_tools_screen_test.dart': 1,
    'test/features/profile/presentation/widgets/location_section_widget_test.dart': 5,
    'test/features/profile/providers/gamification_enabled_provider_test.dart': 1,
    'test/features/profile/providers/show_consumption_tab_enabled_provider_test.dart': 1,
    'test/features/profile/providers/show_electric_enabled_provider_test.dart': 1,
    'test/features/profile/providers/show_fuel_enabled_provider_test.dart': 1,
    'test/features/route_search/data/cross_border_corridor_query_test.dart': 1,
    'test/features/route_search/data/cross_border_near_border_corridor_test.dart': 1,
    'test/features/route_search/data/helpers/batch_query_helper_test.dart': 1,
    'test/features/route_search/providers/route_search_cross_border_test.dart': 4,
    'test/features/search/presentation/screens/search_screen_test.dart': 1,
    'test/features/search/presentation/widgets/cross_border_banner_test.dart': 1,
    'test/features/search/presentation/widgets/radar_search_button_test.dart': 3,
    'test/features/search/presentation/widgets/search_results_content_test.dart': 2,
    'test/features/search/providers/cross_border_provider_test.dart': 2,
    'test/features/search/providers/cross_border_suggestion_provider_test.dart': 3,
    'test/features/search/providers/search_filters_provider_test.dart': 1,
    'test/features/search/providers/search_provider_orchestration_test.dart': 2,
    'test/features/search/providers/search_provider_test.dart': 43,
    'test/features/search/radar_search_provider_test.dart': 4,
    'test/features/station_detail/presentation/screens/station_detail_screen_test.dart': 9,
    'test/features/station_detail/presentation/widgets/station_detail_inline_test.dart': 4,
    'test/features/station_detail/presentation/widgets/station_status_row_test.dart': 1,
    'test/features/station_detail/providers/station_detail_provider_detail_only_hours_test.dart': 3,
    'test/features/station_detail/providers/station_detail_provider_regression_test.dart': 3,
    'test/features/station_detail/providers/station_detail_provider_test.dart': 1,
    'test/features/station_services/denmark/denmark_station_service_test.dart': 1,
    'test/features/station_services/france/prix_carburants_cross_build_cache_test.dart': 1,
    'test/features/station_services/france/prix_carburants_structured_horaires_fallback_test.dart': 1,
    'test/features/station_services/france/prix_carburants_transient_empty_test.dart': 1,
    'test/features/station_services/uk/uk_service_builder_test.dart': 1,
    'test/features/station_services/uk/uk_statutory_fallback_station_service_test.dart': 1,
    'test/features/sync/providers/baseline_sync_enabled_provider_test.dart': 1,
    'test/features/widget/data/nearest_widget_data_builder_test.dart': 1,
    'test/features/widget/providers/nearest_widget_refresh_provider_test.dart': 1,
    'test/features/widget/widget_tap_e2e_test.dart': 3,
    'test/goldens/service_status_banner_golden_test.dart': 7,
    'test/helpers/mock_providers.dart': 1,
    'test/l10n/text_expansion_test.dart': 1,
    'test/lint/sync_utc_timestamps_test.dart': 8,
  };

  Map<String, int> scan() {
    final counts = <String, int>{};
    for (final root in ['lib', 'test']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        final rel = entity.path.replaceAll(r'\', '/');
        if (exempt.contains(rel) || rel == 'test/lint/wall_clock_test.dart') {
          continue;
        }
        final count = raw.allMatches(entity.readAsStringSync()).length;
        if (count > 0) counts[rel] = count;
      }
    }
    return counts;
  }

  test('no file gains raw DateTime.now() reads (use AppClock — #3660)', () {
    final counts = scan();
    final regressions = <String>[
      for (final e in counts.entries)
        if (e.value > (baseline[e.key] ?? 0))
          '  - ${e.key}: ${e.value} > baseline ${baseline[e.key] ?? 0}',
    ];
    expect(
      regressions,
      isEmpty,
      reason: 'Raw DateTime.now() reads increased. New code reads time '
          'through the AppClock seam (lib/core/time/app_clock.dart): '
          'ref.watch(appClockProvider).now() in app code, a FixedClock '
          'override in tests.\n${regressions.join('\n')}',
    );
  });

  test('improvements are locked in (baseline may only shrink)', () {
    final counts = scan();
    final stale = <String>[
      for (final e in baseline.entries)
        if ((counts[e.key] ?? 0) < e.value)
          '  - ${e.key}: now ${counts[e.key] ?? 0}, baseline ${e.value}',
    ];
    expect(
      stale,
      isEmpty,
      reason: 'These files dropped below their wall-clock baseline — '
          'excellent. Lock it in by lowering (or deleting) their entry '
          'in the baseline map so the improvement can never silently regress:\n'
          '${stale.join('\n')}',
    );
  });
}
