// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'refuel_economics.dart';

part 'refuel_profile_provider.g.dart';

/// The vehicle side of the refuel decision — consumption, and how much
/// the user typically buys (#4089, Epic #4087).
///
/// ## Why this is declared in core and implemented elsewhere
///
/// The results screen needs a profile to rank by Best Value, but the
/// numbers come from the fill-ups feature (measured consumption, the
/// user's own fill volumes). Having `features/search` read
/// `features/fill_ups` would add a cross-feature edge that
/// `feature_boundary_test` correctly refuses — `search` imports nothing
/// from `fill_ups` today.
///
/// So the dependency is inverted, the way the repo's decomposition rule
/// prescribes: this provider is declared here against the CORE type,
/// defaults to a profile with no consumption, and the composition root
/// (`AppInitializer`, which may import features) overrides it with the
/// real one via `refuelProfileOverrides()`. Search depends on core;
/// fill_ups supplies the value; neither knows about the other.
///
/// The default is deliberately empty rather than a plausible guess: with
/// no consumption the engine withholds Best Value and the UI says why,
/// which is the spec's first trust rule. A fabricated default would turn
/// a missing measurement into a confident recommendation.
@Riverpod(keepAlive: true)
RefuelProfile refuelProfile(Ref ref) => const RefuelProfile();
