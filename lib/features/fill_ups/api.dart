// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `fill_ups` feature (#3743, epic item 1).
///
/// Extracted from the `consumption` mega-feature (step 2/5 of the split,
/// refile of the half-done #3136): fill-up entry/edit, the fill_ups sync
/// config, full-backup import/export, fill-up <-> trip reconciliation,
/// tank level/mix/report (fill-anchored, #3645-#3652), monthly fuel
/// stats, fuel-type efficiency, maintenance suggestions and the per-fill
/// eco score.
///
/// Cross-feature consumers must import THIS file — never a path under
/// `data/`, `domain/`, `providers/` or `presentation/` of this feature.
/// Enforced by `test/lint/feature_boundary_test.dart` (epic #3129). The
/// export list is the contract measured at extraction time — it should
/// only ever SHRINK.
library;

export 'data/exporters/backup/full_backup_exporter.dart';
export 'data/fill_ups_sync.dart';
export 'domain/add_fill_up_validators.dart';
export 'domain/entities/consumption_stats.dart';
export 'domain/entities/fill_up.dart';
export 'domain/services/monthly_insights_aggregator.dart';
export 'presentation/screens/add_fill_up_screen.dart';
export 'presentation/screens/consumption_statistics_screen.dart';
export 'presentation/screens/pick_station_for_fill_up_screen.dart';
export 'presentation/widgets/backup_progress_dialog.dart';
export 'presentation/widgets/backup_restore_flow.dart';
export 'presentation/widgets/fill_up_date_row.dart';
export 'presentation/widgets/fill_up_numeric_field.dart';
export 'presentation/widgets/fill_up_vehicle_dropdown.dart';
export 'presentation/widgets/fuel_breakdown_card.dart';
export 'presentation/widgets/fuel_tab.dart';
export 'presentation/widgets/maintenance_suggestion_card.dart';
export 'presentation/widgets/monthly_insights_card.dart';
export 'presentation/widgets/tank_report_card.dart';
export 'providers/consumption_providers.dart';
export 'providers/obd2_fuel_level_tracker.dart';
export 'providers/psa_fuel_level_provider.dart';
export 'providers/tank_mix_provider.dart';
