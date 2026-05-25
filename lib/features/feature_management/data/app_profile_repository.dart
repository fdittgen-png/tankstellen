// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/app_profile.dart';

/// Hive-backed persistence for the active [AppProfile] (#1517).
///
/// Storage layout: at most ONE entry keyed [_profileKey] whose value is
/// the enum's [Enum.name]. The box is `dynamic`-typed since we share
/// shape with the rest of the legacy Hive setup (string keys → string
/// values).
///
/// Empty box → no choice yet. Caller can distinguish three startup
/// states:
/// 1. Box empty AND feature_flags empty → fresh install, wizard asks.
/// 2. Box empty AND feature_flags populated → pre-#1517 install,
///    migrate to [AppProfile.custom] preserving the existing flags.
/// 3. Box populated → user has chosen, replay their preset (or honour
///    [AppProfile.custom]).
class AppProfileRepository {
  final Box<dynamic> _box;

  AppProfileRepository({required Box<dynamic> box}) : _box = box;

  /// Hive box that holds the persisted profile.
  static const String boxName = 'app_profile';

  /// Single entry key inside the box. Constant so a future migration
  /// (e.g. multi-profile per user) can reuse the same box without a
  /// key collision.
  static const String _profileKey = 'profile';

  /// Returns the persisted profile, or `null` when the box is empty
  /// (i.e. the user has not chosen yet on this install).
  AppProfile? load() {
    final raw = _box.get(_profileKey);
    if (raw == null) return null;
    final byName = {for (final p in AppProfile.values) p.name: p};
    final profile = byName[raw.toString()];
    if (profile == null) {
      debugPrint(
        'AppProfileRepository.load: unknown profile name "$raw" — '
        'treating as no choice',
      );
      return null;
    }
    return profile;
  }

  /// Persists [profile] as the new active choice.
  Future<void> save(AppProfile profile) async {
    await _box.put(_profileKey, profile.name);
  }

  /// True when the box is empty — i.e. the user has never chosen a
  /// profile on this install.
  bool get isEmpty => _box.isEmpty;
}
