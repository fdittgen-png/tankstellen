// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `search` feature (#3132).
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

export 'domain/entities/brand_registry.dart';
export 'presentation/screens/ev_station_detail_screen.dart';
export 'presentation/screens/search_criteria_screen.dart';
export 'presentation/screens/search_screen.dart';
export 'presentation/widgets/amenity_chips.dart';
export 'presentation/widgets/pay_with_app_button.dart';
export 'presentation/widgets/payment_method_chips.dart';
export 'presentation/widgets/sort_selector.dart';
export 'presentation/widgets/station_card.dart';
export 'providers/ev_charging_service_provider.dart';
export 'providers/ev_search_provider.dart';
export 'providers/radar_search_provider.dart';
export 'providers/search_filters_provider.dart';
export 'providers/search_mode_provider.dart';
export 'providers/search_provider.dart';
export 'providers/search_screen_ui_provider.dart';
export 'providers/selected_station_provider.dart';
export 'providers/station_rating_provider.dart';
