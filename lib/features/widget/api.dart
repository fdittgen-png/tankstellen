// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `widget` feature (#3132).
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

export 'data/car_station_data.dart';
export 'data/car_station_writer.dart';
export 'data/home_widget_service.dart';
export 'presentation/widget_click_listener.dart';
export 'presentation/widget_help_section.dart';
export 'presentation/widget_uri_parser.dart';
export 'providers/nearest_widget_refresh_provider.dart';
export 'providers/pending_widget_uri_provider.dart';
