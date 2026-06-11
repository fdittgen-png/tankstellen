// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `feature_management` feature (#3132).
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

export 'application/app_profile_provider.dart';
export 'application/feature_flags_provider.dart';
export 'application/feature_toggle_notifier.dart';
export 'application/legacy_toggle_migration_provider.dart';
export 'domain/app_profile.dart';
export 'domain/build_channel.dart';
export 'domain/conso_mode.dart';
export 'domain/consumption_tab_visibility.dart';
export 'domain/feature.dart';
export 'domain/feature_category.dart';
export 'domain/feature_dependency_graph.dart';
export 'domain/feature_manifest.dart';
