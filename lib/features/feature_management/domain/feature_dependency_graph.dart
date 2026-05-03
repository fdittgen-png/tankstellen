import 'feature.dart';
import 'feature_manifest.dart';

/// Pure helpers over the [FeatureManifest] dependency DAG (#1373 phase 1).
///
/// All functions are side-effect-free and operate on the caller-provided
/// `currentlyEnabled` set so they can be exercised from tests without a
/// Riverpod container.

/// Returns `true` when [feature] can be enabled given [currentlyEnabled].
///
/// A feature can be enabled when every entry in its
/// [FeatureManifestEntry.requires] is already in [currentlyEnabled]. The
/// feature itself does not need to be absent — re-enabling an already
/// enabled feature is a no-op the caller can decide to skip.
bool canEnable(
  Feature feature,
  FeatureManifest manifest,
  Set<Feature> currentlyEnabled,
) {
  final entry = manifest.entryFor(feature);
  for (final required in entry.requires) {
    if (!currentlyEnabled.contains(required)) return false;
  }
  return true;
}

/// Returns the set of currently-enabled features that depend on [feature].
///
/// When the returned set is empty, [feature] can be safely disabled.
/// Otherwise the caller must disable each returned feature first (or refuse
/// the operation).
Set<Feature> blockingDisable(
  Feature feature,
  FeatureManifest manifest,
  Set<Feature> currentlyEnabled,
) {
  final blockers = <Feature>{};
  for (final entry in manifest.entries.values) {
    if (entry.feature == feature) continue;
    if (!currentlyEnabled.contains(entry.feature)) continue;
    if (entry.requires.contains(feature)) {
      blockers.add(entry.feature);
    }
  }
  return blockers;
}

/// Throws [StateError] when [manifest] contains a `requires` cycle.
///
/// Called once at provider construction so a malformed manifest fails fast
/// in tests / debug builds. Uses three-colour DFS so the error message
/// names the actual cycle chain rather than a generic "cycle detected".
void assertNoCycles(FeatureManifest manifest) {
  // White = unvisited, grey = on the current DFS stack, black = fully
  // explored. A grey-grey edge is a back edge → cycle.
  const white = 0;
  const grey = 1;
  const black = 2;
  final colour = <Feature, int>{
    for (final f in manifest.entries.keys) f: white,
  };
  final stack = <Feature>[];

  void visit(Feature node) {
    colour[node] = grey;
    stack.add(node);
    final entry = manifest.entries[node];
    if (entry != null) {
      for (final next in entry.requires) {
        final nextColour = colour[next] ?? white;
        if (nextColour == grey) {
          // Trim the stack to the start of the cycle so the message is
          // tight rather than dragging the entire walk into it.
          final start = stack.indexOf(next);
          final chain = [
            ...stack.sublist(start).map((f) => f.name),
            next.name,
          ].join(' -> ');
          throw StateError('Feature dependency cycle: $chain');
        }
        if (nextColour == white) {
          visit(next);
        }
      }
    }
    stack.removeLast();
    colour[node] = black;
  }

  for (final feature in manifest.entries.keys) {
    if ((colour[feature] ?? white) == white) {
      visit(feature);
    }
  }
}
