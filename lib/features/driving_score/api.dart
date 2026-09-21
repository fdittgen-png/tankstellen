// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Public API barrel of the `driving_score` feature (#3743, epic item 1).
///
/// Extracted from the `consumption` mega-feature (step 3/5 of the split,
/// refile of the half-done #3136): the driving score calculator +
/// accumulators, driving insights analysis, the lesson/coaching content
/// (registry + per-rule lessons), live coaching hints and the eco-nudge
/// engine — NOT the core trip recording, which stays with `trips`.
///
/// Cross-feature consumers must import THIS file — never a path under
/// `data/`, `domain/` or `presentation/` of this feature. Enforced by
/// `test/lint/feature_boundary_test.dart` (epic #3129). The export list
/// is the contract measured at extraction time — it should only ever
/// SHRINK.
library;

export 'data/driving_insights_analyzer.dart';
export 'data/driving_insights_hard_accel_indices.dart';
export 'data/driving_score_calculator.dart';
export 'data/lessons/driving_lesson_registry.dart';
export 'data/lessons/lesson_format.dart';
export 'domain/driving_coaching.dart';
export 'domain/driving_insight.dart';
export 'domain/live_driving_band.dart';
export 'domain/driving_score.dart';
export 'domain/lessons/driving_lesson.dart';
export 'domain/lessons/driving_lesson_rule.dart';
// #4366 (Epic #4358 work package G) — the driving-pattern comparison:
// the read model, its bounded aggregation and the surface that renders
// it. #4365's vehicle-selection/period flow mounts the card and feeds
// the request; nothing here selects a vehicle.
export 'data/driving_pattern_aggregator.dart';
export 'data/driving_pattern_cache.dart';
export 'data/driving_pattern_measures.dart';
export 'domain/driving_pattern_comparison.dart';
export 'presentation/widgets/driving_pattern_comparison_card.dart';
export 'providers/driving_pattern_comparison_provider.dart';
export 'presentation/widgets/coaching_chip.dart';
export 'presentation/widgets/driving_analysis_trace_card.dart';
export 'presentation/widgets/driving_insights_card.dart';
export 'presentation/widgets/driving_score_card.dart';
export 'presentation/widgets/eco_nudge_listener.dart';
