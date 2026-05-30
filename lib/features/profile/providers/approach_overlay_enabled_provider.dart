// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../feature_management/domain/feature_dependency_graph.dart';

part 'approach_overlay_enabled_provider.g.dart';

/// Master gate for the in-trip approach overlay (#2382).
///
/// Thin shim over [featureFlagsProvider], keyed by
/// [Feature.approachOverlay] (default-OFF in the manifest baseline,
/// flipped ON by the `AppProfile.medium` and `AppProfile.full` presets).
///
/// The live approach detector (`approachStateProvider`) watches this so
/// that when the user turns the overlay off, the GPS subscription +
/// periodic search-chain polls never start — even mid-trip. The PiP
/// view also watches it so a stale simulator/detector value can never
/// flip the tile to the price layout once the feature is disabled.
@Riverpod(keepAlive: true)
bool approachOverlayEnabled(Ref ref) {
  final enabled = ref.watch(enabledFeaturesProvider);
  final manifest = ref.watch(featureManifestProvider);
  return isEffectivelyEnabled(Feature.approachOverlay, manifest, enabled);
}
