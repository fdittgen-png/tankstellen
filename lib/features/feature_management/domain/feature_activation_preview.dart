// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'build_channel.dart';
import 'feature.dart';
import 'feature_dependency_graph.dart';
import 'feature_manifest.dart';

/// Read-only impact of enabling a capability through the canonical DAG.
/// Stored preferences remain owned by FeatureFlags, including dormant children.
final class FeatureActivationPreview {
  FeatureActivationPreview._(
    this.target,
    Set<Feature> before,
    Set<Feature> required,
    Set<Feature> activated,
  ) : before = Set.unmodifiable(before),
      required = Set.unmodifiable(required),
      activated = Set.unmodifiable(activated);

  final Feature target;
  final Set<Feature> before;
  final Set<Feature> required;

  /// Includes stored children restored by enabling a missing parent.
  final Set<Feature> activated;

  static FeatureActivationPreview? resolve({
    required Feature target,
    required FeatureManifest manifest,
    required BuildChannel channel,
    required Set<Feature> enabled,
  }) {
    assertNoCycles(manifest);
    final required = <Feature>{};
    bool visit(Feature feature) {
      if (!required.add(feature)) return true;
      final entry = manifest.entries[feature];
      return entry != null &&
          entry.isAvailableIn(channel) &&
          entry.requires.every(visit);
    }

    if (!visit(target)) return null;
    final next = {...enabled, ...required};
    return FeatureActivationPreview._(target, enabled, required, {
      for (final feature in Feature.values)
        if (manifest.entries[feature]?.isAvailableIn(channel) == true &&
            !isEffectivelyEnabled(feature, manifest, enabled) &&
            isEffectivelyEnabled(feature, manifest, next))
          feature,
    });
  }

  /// A changed stored set or manifest impact requires a fresh confirmation.
  bool matches(FeatureActivationPreview other) =>
      target == other.target &&
      _same(before, other.before) &&
      _same(required, other.required) &&
      _same(activated, other.activated);

  static bool _same(Set<Feature> a, Set<Feature> b) =>
      a.length == b.length && a.containsAll(b);
}
