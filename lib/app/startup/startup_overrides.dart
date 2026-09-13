// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/misc.dart';

import '../profile_language_binding.dart';
import '../../features/fill_ups/providers/refuel_profile_override.dart';
import '../../features/fill_ups/providers/tank_state_override.dart';

/// Every provider override the real app boots with (#4089).
///
/// The composition root is the one place allowed to know about several
/// features at once, and this is that list — named, so
/// `AppInitializer.launch` reads as one line and each override's reason
/// lives with the override:
///
///  * **profile language** — the stored locale, before the first frame.
///  * **refuel profile** — the measured consumption and the user's
///    median fill volume, wired into the CORE declaration so
///    `features/search` can rank by Best Value without importing
///    `features/fill_ups` (which `feature_boundary_test` would refuse).
///  * **tank state** (#4146) — capacity and current level from the
///    level-v2 estimate, for the same reason: the route screen plans
///    stops around the tank without reaching into `fill_ups`.
List<Override> startupOverrides() => [
      ...profileLanguageOverrides(),
      ...refuelProfileOverrides(),
      ...tankStateOverrides(),
    ];
