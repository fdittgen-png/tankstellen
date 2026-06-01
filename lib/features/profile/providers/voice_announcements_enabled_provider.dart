// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../feature_management/domain/feature_dependency_graph.dart';

part 'voice_announcements_enabled_provider.g.dart';

/// Master gate for spoken voice announcements while driving (#2569).
///
/// Thin shim over [featureFlagsProvider], keyed by
/// [Feature.voiceAnnouncements] (default-OFF; `requires`
/// [Feature.approachOverlay], so it is effectively-enabled only when the
/// overlay it piggybacks on is also on). Mirrors
/// [approachOverlayEnabledProvider] / `glideCoachEnabledProvider`.
///
/// The live announcement listener (`voiceAnnouncementListenerProvider`)
/// and the persisted settings notifier both watch this so a stale config
/// can never speak once the feature is disabled — the engine is fed only
/// while the gate is true.
@Riverpod(keepAlive: true)
bool voiceAnnouncementsEnabled(Ref ref) {
  final enabled = ref.watch(enabledFeaturesProvider);
  final manifest = ref.watch(featureManifestProvider);
  return isEffectivelyEnabled(Feature.voiceAnnouncements, manifest, enabled);
}
