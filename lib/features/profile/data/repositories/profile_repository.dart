// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/domain/fuel_type.dart';
import '../models/user_profile.dart';

part 'profile_repository.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(ref.watch(storageRepositoryProvider));
}

class ProfileRepository {
  final StorageRepository _storage;
  static const _uuid = Uuid();

  ProfileRepository(this._storage);

  UserProfile? getActiveProfile() {
    final id = _storage.getActiveProfileId();
    if (id == null) return null;
    final data = _storage.getProfile(id);
    if (data == null) return null;
    return UserProfile.fromJson(_migrateLegacyLandingScreen(data));
  }

  List<UserProfile> getAllProfiles() {
    return _storage
        .getAllProfiles()
        .map((data) => UserProfile.fromJson(_migrateLegacyLandingScreen(data)))
        .toList();
  }

  /// Rewrites the legacy `LandingScreen.search` value (removed in 4.2.0) to
  /// `nearest` so `fromJson` does not throw on profiles saved before the enum
  /// was trimmed. `search` was always equivalent to the default distance sort,
  /// which `nearest` now represents explicitly.
  Map<String, dynamic> _migrateLegacyLandingScreen(Map<String, dynamic> data) {
    final landing = data['landingScreen'];
    if (landing == 'search' || landing == 'LandingScreen.search') {
      return {...data, 'landingScreen': 'nearest'};
    }
    return data;
  }

  Future<UserProfile> createProfile({
    required String name,
    FuelType preferredFuelType = FuelType.e10,
    double defaultSearchRadius = 10.0,
    LandingScreen landingScreen = LandingScreen.nearest,
    String? homeZipCode,
    String? countryCode,
    String? languageCode,
  }) async {
    final profile = UserProfile(
      id: _uuid.v4(),
      name: name,
      preferredFuelType: preferredFuelType,
      defaultSearchRadius: defaultSearchRadius,
      landingScreen: landingScreen,
      homeZipCode: homeZipCode,
      countryCode: countryCode,
      languageCode: languageCode,
    );
    await _storage.saveProfile(profile.id, profile.toJson());

    // If this is the first profile, make it active
    if (_storage.getActiveProfileId() == null) {
      await _storage.setActiveProfileId(profile.id);
    }
    return profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _storage.saveProfile(profile.id, profile.toJson());
  }

  /// #2597 — whether another profile already owns [countryCode]. A null /
  /// empty country never counts as taken (profiles may have no country),
  /// and [excludeProfileId] lets the edit flow ignore the profile being
  /// edited so re-saving its own country isn't reported as a conflict.
  /// Backs the one-profile-per-country rule that keeps the border-cross
  /// auto-switch's country→profile match deterministic.
  bool isCountryTaken(String countryCode, {String? excludeProfileId}) {
    if (countryCode.isEmpty) return false;
    return getAllProfiles().any(
      (p) =>
          p.id != excludeProfileId &&
          p.countryCode != null &&
          p.countryCode == countryCode,
    );
  }

  Future<void> deleteProfile(String id) async {
    await _storage.deleteProfile(id);
    if (_storage.getActiveProfileId() == id) {
      final remaining = getAllProfiles();
      if (remaining.isNotEmpty) {
        await _storage.setActiveProfileId(remaining.first.id);
      }
    }
  }

  Future<void> setActiveProfile(String id) async {
    await _storage.setActiveProfileId(id);
  }

  /// Create a default profile if none exists.
  Future<UserProfile> ensureDefaultProfile() async {
    final profiles = getAllProfiles();
    if (profiles.isNotEmpty) {
      return getActiveProfile() ?? profiles.first;
    }
    return createProfile(name: 'Standard');
  }

  /// Migrate existing profiles that have no country/language set.
  /// Backfills from the current global settings stored in Hive.
  Future<void> migrateProfileCountryLanguage() async {
    final countryCode =
        _storage.getSetting('active_country_code') as String?;
    final languageCode =
        _storage.getSetting('active_language_code') as String?;

    if (countryCode == null && languageCode == null) return;

    for (final profile in getAllProfiles()) {
      if (profile.countryCode == null || profile.languageCode == null) {
        final updated = profile.copyWith(
          countryCode: profile.countryCode ?? countryCode,
          languageCode: profile.languageCode ?? languageCode,
        );
        await updateProfile(updated);
      }
    }
  }

  /// #2597 — enforce the one-profile-per-country rule for users who already
  /// hold duplicate same-country profiles from before the constraint
  /// existed. For every country owned by more than one profile we KEEP one
  /// canonical profile (the ACTIVE one if it is among them, otherwise the
  /// FIRST in storage order — `UserProfile` carries no modified timestamp,
  /// so storage order is the only stable, deterministic tie-break) and
  /// CLEAR the `countryCode` of the rest. The duplicate profiles survive
  /// intact, they just lose their country binding so the country→profile
  /// match stays deterministic for the auto-switch.
  ///
  /// Returns the number of profiles whose country was cleared. Idempotent:
  /// a second run finds no duplicates and clears nothing (returns 0), so it
  /// is safe to invoke on every cold start.
  Future<int> dedupeCountryProfiles() async {
    final profiles = getAllProfiles();
    final activeId = _storage.getActiveProfileId();

    // Group profiles by their non-null country code, preserving order.
    final byCountry = <String, List<UserProfile>>{};
    for (final p in profiles) {
      final code = p.countryCode;
      if (code == null || code.isEmpty) continue;
      byCountry.putIfAbsent(code, () => <UserProfile>[]).add(p);
    }

    var cleared = 0;
    for (final entry in byCountry.entries) {
      final group = entry.value;
      if (group.length < 2) continue; // No duplication for this country.

      // Pick the keeper: the active profile if it is in this group,
      // otherwise the first one in storage order (deterministic).
      final keeper = group.firstWhere(
        (p) => p.id == activeId,
        orElse: () => group.first,
      );

      for (final p in group) {
        if (p.id == keeper.id) continue;
        await updateProfile(p.copyWith(countryCode: null));
        cleared++;
      }
    }
    return cleared;
  }
}
