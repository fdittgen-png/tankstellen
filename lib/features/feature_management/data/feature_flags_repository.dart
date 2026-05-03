import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/feature.dart';
import '../domain/feature_manifest.dart';

/// Hive-backed persistence for the central feature-flags set (#1373).
///
/// Storage layout: ONE entry per [Feature] keyed by [Enum.name] with the
/// value `true` when enabled and `false` when explicitly disabled.
/// String keys are forward-compatible — adding new features or removing
/// stale entries does not need an index migration.
///
/// On the very first launch the box is empty, in which case
/// [loadEnabled] returns the manifest defaults so consumers see the same
/// initial behaviour they had before the central system existed.
class FeatureFlagsRepository {
  final Box<dynamic> _box;
  final FeatureManifest _manifest;

  FeatureFlagsRepository({
    required Box<dynamic> box,
    FeatureManifest manifest = FeatureManifest.defaultManifest,
  })  : _box = box,
        _manifest = manifest;

  /// Hive box that holds the persisted feature-flag set.
  static const String boxName = 'feature_flags';

  /// Returns the currently-enabled feature set.
  ///
  /// First launch (empty box) → manifest defaults. Subsequent launches
  /// → exactly the set persisted by [saveEnabled]. Unknown enum names
  /// (e.g. a feature removed in a later version) are skipped silently
  /// so a downgrade-then-upgrade does not crash.
  Future<Set<Feature>> loadEnabled() async {
    if (_box.isEmpty) {
      return _manifest.defaultEnabledSet();
    }
    final result = <Feature>{};
    final byName = {for (final f in Feature.values) f.name: f};
    for (final key in _box.keys) {
      final feature = byName[key.toString()];
      if (feature == null) {
        debugPrint(
          'FeatureFlagsRepository.loadEnabled: skipping unknown key $key',
        );
        continue;
      }
      final raw = _box.get(key);
      if (raw == true) {
        result.add(feature);
      }
    }
    return result;
  }

  /// Persists [enabled] as the new authoritative set. Every known
  /// [Feature] is written explicitly (true or false) so a future read
  /// can distinguish "user disabled it" from "first launch".
  Future<void> saveEnabled(Set<Feature> enabled) async {
    final updates = <String, bool>{
      for (final feature in Feature.values)
        feature.name: enabled.contains(feature),
    };
    await _box.putAll(updates);
  }
}
