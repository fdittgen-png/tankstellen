// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../feature_management/domain/feature.dart';
import '../../../../feature_management/domain/feature_manifest.dart';

/// A parent feature plus the dependents that should render indented
/// beneath it (#1440). The parent itself is always the first row in the
/// rendered Card; [children] is empty for stand-alone parents.
///
/// Extracted from feature_management_section.dart for #2681 (file-length).
class FeatureGroup {
  final Feature parent;
  final List<Feature> children;

  const FeatureGroup({required this.parent, required this.children});
}

/// Walks [manifest] in declaration order and produces a list of groups
/// in the same order. A feature with empty `requires` ALWAYS opens a
/// new group; a feature with `requires` is appended to the first parent
/// it references — falling back to a stand-alone group when none of its
/// prerequisites are themselves declared in [manifest] (defensive: this
/// should never happen in practice but the function stays total).
List<FeatureGroup> buildGroups(FeatureManifest manifest) {
  final groups = <FeatureGroup>[];
  // Index of the group whose parent is `Feature`, for O(1) child append.
  final parentIndex = <Feature, int>{};

  for (final feature in manifest.entries.keys) {
    final entry = manifest.entries[feature]!;
    if (entry.requires.isEmpty) {
      parentIndex[feature] = groups.length;
      groups.add(FeatureGroup(parent: feature, children: <Feature>[]));
      continue;
    }
    // Pick the first prerequisite that is itself a parent we have
    // already seen — keeps ordering stable and predictable.
    int? targetIndex;
    for (final required in entry.requires) {
      final idx = parentIndex[required];
      if (idx != null) {
        targetIndex = idx;
        break;
      }
    }
    if (targetIndex == null) {
      // Defensive: dependent whose prerequisite is missing from the
      // manifest — render as its own group so the user still sees the
      // toggle.
      parentIndex[feature] = groups.length;
      groups.add(FeatureGroup(parent: feature, children: <Feature>[]));
    } else {
      groups[targetIndex].children.add(feature);
    }
  }
  return groups;
}
