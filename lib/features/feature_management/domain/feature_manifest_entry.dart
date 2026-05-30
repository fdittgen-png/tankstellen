// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'build_channel.dart';
import 'feature.dart';

/// Metadata for a single [Feature] in the manifest (#1373 phase 1).
///
/// Plain immutable class — the codebase prefers Dart 3 native sealed/enum
/// + plain classes over Freezed multi-constructor unions for this kind of
/// declarative descriptor (see #1377 PR notes).
///
/// Extracted from `feature_manifest.dart` (#2382) to keep both files under
/// the 400-line cap (#1680); the manifest registry stays in that file.
class FeatureManifestEntry {
  /// The feature this entry describes.
  final Feature feature;

  /// Build channels this feature exists in (#1670 / #1673). A feature
  /// absent from a channel is completely unavailable there — force-off
  /// and hidden from that channel's feature-management UI.
  final Set<BuildChannel> availableChannels;

  /// Build channels where the feature defaults ON (opt-out). In an
  /// available channel NOT listed here the feature defaults OFF
  /// (opt-in). Always a subset of [availableChannels].
  final Set<BuildChannel> defaultEnabledChannels;

  /// Hard prerequisites — every feature here must be enabled before
  /// [feature] can be enabled. Cycles are rejected by
  /// `assertNoCycles` at provider construction.
  final Set<Feature> requires;

  /// Human-readable label used by Phase 2 settings UI. English only;
  /// localisation is Phase 2's concern.
  final String displayName;

  /// One-line description shown next to the toggle in Phase 2 UI.
  /// English only; localisation is Phase 2's concern.
  final String description;

  const FeatureManifestEntry({
    required this.feature,
    required this.availableChannels,
    this.defaultEnabledChannels = const {},
    required this.displayName,
    required this.description,
    this.requires = const {},
  });

  /// Convenience for a feature available in every build channel — the
  /// shape of every feature that predates the channel model (#1673).
  /// [defaultOn] sets opt-out (on) vs opt-in (off) uniformly across
  /// channels, mirroring the old single `defaultEnabled` bool.
  const FeatureManifestEntry.allChannels({
    required this.feature,
    required bool defaultOn,
    required this.displayName,
    required this.description,
    this.requires = const {},
  })  : availableChannels = const {
          BuildChannel.production,
          BuildChannel.beta,
        },
        defaultEnabledChannels = defaultOn
            ? const {BuildChannel.production, BuildChannel.beta}
            : const {};

  /// Whether [feature] exists at all in [channel].
  bool isAvailableIn(BuildChannel channel) =>
      availableChannels.contains(channel);

  /// Whether [feature] defaults enabled in [channel]. Always `false`
  /// for a channel the feature is not available in.
  bool defaultEnabledIn(BuildChannel channel) =>
      defaultEnabledChannels.contains(channel);
}
