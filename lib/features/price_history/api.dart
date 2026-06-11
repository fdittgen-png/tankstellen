// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `price_history` feature (#3132).
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

export 'data/repositories/price_history_repository.dart';
export 'domain/entities/price_prediction.dart';
export 'domain/entities/price_record.dart';
export 'presentation/screens/price_history_screen.dart';
export 'presentation/widgets/price_chart.dart';
export 'presentation/widgets/price_stats_card.dart';
export 'providers/price_history_provider.dart';
export 'providers/price_prediction_provider.dart';
