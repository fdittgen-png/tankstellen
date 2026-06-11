// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `profile` feature (#3132).
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

export 'data/repositories/profile_repository.dart';
export 'domain/entities/user_profile.dart';
export 'presentation/screens/developer_tools/developer_tools_screen.dart';
export 'presentation/screens/developer_tools/error_log_viewer_screen.dart';
export 'presentation/screens/developer_tools/feature_flag_dump_screen.dart';
export 'presentation/screens/developer_tools/obd2_health_screen.dart';
export 'presentation/screens/developer_tools/pump_ocr_tester_screen.dart';
export 'presentation/screens/privacy_dashboard_screen.dart';
export 'presentation/screens/profile_screen.dart';
export 'presentation/screens/theme_settings_screen.dart';
export 'presentation/widgets/gamification_settings_tile.dart';
export 'providers/approach_overlay_enabled_provider.dart';
export 'providers/effective_fuel_type_provider.dart';
export 'providers/gamification_enabled_provider.dart';
export 'providers/profile_provider.dart';
export 'providers/show_electric_enabled_provider.dart';
export 'providers/show_fuel_enabled_provider.dart';
export 'providers/voice_announcements_enabled_provider.dart';
