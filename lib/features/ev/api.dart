// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `ev` feature (#3132).
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

export 'data/repositories/ev_station_repository.dart';
export 'data/services/ev_price_enricher.dart';
export 'data/services/fr_irve_price_service.dart';
export 'data/services/ocm_poi_parser.dart';
export 'domain/charging_cost_calculator.dart';
export 'domain/entities/charging_log.dart';
export 'presentation/widgets/connector_status_style.dart';
export 'presentation/widgets/ev_filter_chips.dart';
export 'presentation/widgets/ev_map_overlay.dart';
export 'providers/ev_providers.dart';
