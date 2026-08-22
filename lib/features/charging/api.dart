// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `charging` feature (#3743, epic item 1).
///
/// Extracted from the `consumption` mega-feature (step 4/5 of the split,
/// refile of the half-done #3136): the EV charging-log surfaces — log
/// entry/edit screen, charging tab, cost/efficiency charts and the
/// charging-log store/providers. The `ChargingLog` entity and cost
/// calculator stay in the `ev` feature (station data + pricing); this
/// feature consumes them through the ev barrel.
///
/// Cross-feature consumers must import THIS file — never a path under
/// `data/`, `domain/`, `providers/` or `presentation/` of this feature.
/// Enforced by `test/lint/feature_boundary_test.dart` (epic #3129). The
/// export list is the contract measured at extraction time — it should
/// only ever SHRINK.
library;

export 'presentation/screens/add_charging_log_screen.dart';
export 'presentation/widgets/charging_tab.dart';
export 'providers/charging_logs_provider.dart';
