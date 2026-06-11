// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `route_search` feature (#3132).
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

export 'data/cross_border_corridor.dart';
export 'domain/entities/route_info.dart';
export 'domain/route_search_strategy.dart';
export 'presentation/widgets/route_input.dart';
export 'providers/route_input_provider.dart';
export 'providers/route_search_params_provider.dart';
export 'providers/route_search_provider.dart';
