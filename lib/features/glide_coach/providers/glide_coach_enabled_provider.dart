// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_toggle_notifier.dart';
import '../../feature_management/domain/feature.dart';

part 'glide_coach_enabled_provider.g.dart';

/// Whether the glide-coach feature is enabled (#1824).
///
/// Migrated off the compile-time `kGlideCoachEnabled` const onto the
/// central feature-flag set keyed by [Feature.glideCoach] — the
/// `FeatureFlags` system (#1373) the old TODO was waiting on.
///
/// The manifest defaults [Feature.glideCoach] off and declares
/// `obd2TripRecording` as a prerequisite, so production behaviour is
/// unchanged (off by default) — but the toggle in the Feature
/// management screen is now the single source of truth instead of a
/// dead switch shadowed by a build-time constant.
///
/// `keepAlive` because consumers (`glideCoachEvaluatorProvider`, the
/// settings notifier, the trip GPS stream controller) span the app
/// lifecycle. Reads route through `isEffectivelyEnabled` for symmetry
/// with the other feature shims (`showFuelEnabledProvider` etc.).
@Riverpod(keepAlive: true)
bool glideCoachEnabled(Ref ref) =>
    watchEffectiveFeature(ref, Feature.glideCoach);
