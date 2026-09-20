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
/// which org, which role, and how fresh that answer is.
library;

export 'domain/fleet_scope.dart';
export 'providers/fleet_consent_provider.dart';
export 'providers/fleet_scope_provider.dart';
