// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `approach` feature (#3132).
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

export 'presentation/widgets/approach_test_panel.dart';
export 'providers/approach_state_provider.dart';
export 'providers/effective_approach_state_provider.dart';
export 'providers/fuel_station_radar_provider.dart';
export 'providers/nearest_station_radar_provider.dart';
export 'providers/radar_candidate_list_provider.dart';
export 'providers/radar_swipe_provider.dart';
