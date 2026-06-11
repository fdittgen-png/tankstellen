// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `alerts` feature (#3132).
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

export 'data/price_snapshot_store.dart';
export 'data/radius_alert_dedup.dart';
export 'data/radius_alert_runner.dart';
export 'data/radius_alert_store.dart';
export 'data/repositories/alert_repository.dart';
export 'data/test_alert_runner.dart';
export 'data/velocity_alert_cooldown.dart';
export 'data/velocity_alert_runner.dart';
export 'domain/entities/price_alert.dart';
export 'domain/entities/radius_alert.dart';
export 'domain/radius_alert_evaluator.dart';
export 'domain/velocity_alert_detector.dart';
export 'presentation/screens/alerts_screen.dart';
export 'presentation/widgets/create_alert_dialog.dart';
export 'providers/alert_provider.dart';
