// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `driving` feature (#3132).
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

export 'haptic_eco_coach.dart';
export 'presentation/screens/driving_mode_screen.dart';
export 'presentation/widgets/driving_settings_section.dart';
export 'providers/driving_coach_voice_listener_provider.dart';
export 'providers/haptic_eco_coach_provider.dart';
export 'providers/live_harsh_event_bus_provider.dart';
export 'providers/voice_announcement_listener_provider.dart';
