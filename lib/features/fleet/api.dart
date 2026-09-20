// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `fleet` feature (#3132, Epic #4211).
///
/// Cross-feature consumers must import THIS file — never a path under
/// `providers/`, `domain/` or `presentation/`. Enforced by
/// `test/lint/feature_boundary_test.dart` with an only-decreasing
/// baseline (epic #3129).
///
/// #4212 seeds it with the scope contract every later fleet slice reads:
/// which org, which role, and how fresh that answer is. #4213 adds the
/// vehicle half: the company-asset identity, the attribution a record
/// is stamped with at creation, the explicit-selection provider and the
/// two context widgets other surfaces embed.
///
/// The fleet feature imports NO other feature — signals arrive as
/// primitives (an adapter device id, a VIN string) — so this barrel is
/// a leaf of the dependency graph and `fill_ups -> fleet` cannot close
/// a cycle (`test/lint/feature_boundary_test.dart`, the #4346
/// barrel-aware SCC gate).
library;

export 'domain/fleet_scope.dart';
export 'domain/fleet_vehicle.dart';
export 'domain/vehicle_attribution.dart';
export 'domain/vehicle_attribution_resolver.dart';
export 'presentation/widgets/current_vehicle_control.dart';
export 'presentation/widgets/vehicle_switch_sheet.dart';
export 'providers/current_fleet_vehicle_provider.dart';
export 'providers/fleet_consent_provider.dart';
export 'providers/fleet_scope_provider.dart';
