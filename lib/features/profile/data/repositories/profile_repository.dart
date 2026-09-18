// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/logging/app_log.dart';
import '../../../../core/logging/error_logger.dart';
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

  // Overlapping batches share a main-isolate occupancy-check/write queue.
  // Background isolates do not write profiles; this is not a cross-isolate lock.
  static Future<void> _writeTail = Future<void>.value();

  Future<T> _write<T>(Future<T> Function() action) async {
    final previous = _writeTail;
    final done = Completer<void>();
    _writeTail = done.future;
    await previous;
    try {
      return await action();
    } finally {
      done.complete();
    }
  }

  static String? _country(String? code) {
    final normalized = code?.trim().toUpperCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

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

  /// [activateIfNone] — when no profile is active yet, the created one
  /// becomes active. That is right for first-run onboarding and wrong for
  /// every automatic country setup: a route- or location-created profile
  /// must never become the user's active country just because none was set
  /// (#4268, Epic #4257 §C). Defaults to today's behaviour so onboarding is
  /// unchanged; automatic creators pass `false`.
  Future<UserProfile> createProfile({
    required String name,
    FuelType preferredFuelType = FuelType.e10,
    double defaultSearchRadius = 10.0,
    LandingScreen landingScreen = LandingScreen.nearest,
    String? homeZipCode,
    String? countryCode,
    String? languageCode,
    bool activateIfNone = true,
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

    // If this is the first profile, make it active — unless the caller
    // explicitly declined (#4268).
    if (activateIfNone && _storage.getActiveProfileId() == null) {
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
    final normalized = _country(countryCode);
    if (normalized == null) return false;
    return getAllProfiles().any(
      (p) =>
          p.id != excludeProfileId &&
          p.countryCode != null &&
          _country(p.countryCode) == normalized,
    );
  }

  /// Delete [id]; when it was the active profile, hand the active context
  /// to a **deterministically chosen** survivor.
  ///
  /// #4267 — this used `remaining.first` over `getAllProfiles()`, which is
  /// an unordered Hive map read. The active profile is the country context
  /// for nearby search and every country-scoped feature, so deleting it
  /// moved the user to an arbitrary country that could differ between two
  /// devices holding the same data.
  ///
  /// `UserProfile` carries no "last used" or modified timestamp, so the
  /// rule has to come from the data itself: order by country code, then
  /// name, then id — all three so the comparison is total and cannot fall
  /// back to storage order on a tie. Profiles with a country sort ahead of
  /// profiles without one, since a country-less profile gives the user no
  /// country context at all.
  ///
  /// Telling the user which country became active is presentation work and
  /// belongs to #4265; this only makes the choice stable and explainable.
  Future<void> deleteProfile(String id) async {
    await _storage.deleteProfile(id);
    if (_storage.getActiveProfileId() != id) return;

    final remaining = getAllProfiles();
    if (remaining.isEmpty) return;
    await _storage.setActiveProfileId(_nextActiveAfterDeletion(remaining).id);
  }

  /// The deterministic successor for the active slot (#4267). Pure and
  /// order-independent: the same set of profiles always yields the same
  /// winner, whatever order storage returned them in.
  UserProfile _nextActiveAfterDeletion(List<UserProfile> candidates) {
    final sorted = [...candidates]
      ..sort((a, b) {
        final ac = a.countryCode ?? '';
        final bc = b.countryCode ?? '';
        // A profile bound to a country outranks one with no country.
        if (ac.isEmpty != bc.isEmpty) return ac.isEmpty ? 1 : -1;
        final byCountry = ac.compareTo(bc);
        if (byCountry != 0) return byCountry;
        final byName = a.name.compareTo(b.name);
        if (byName != 0) return byName;
        return a.id.compareTo(b.id);
      });
    return sorted.first;
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
    final countryCode = _storage.getSetting('active_country_code') as String?;
    final languageCode = _storage.getSetting('active_language_code') as String?;

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

  /// #4259 — a country profile derived from [source] as a template.
  ///
  /// [createProfile] accepts 7 of `UserProfile`'s ~28 fields, so cloning
  /// through it would silently reset the rest to defaults: route segment
  /// length, detour budget, saving threshold, top-N and criterion,
  /// amenities, default vehicle, hybrid choice, approach radius/mode/poll,
  /// widget colour/variant, favourites, rating mode and auto-update. This
  /// clones with `copyWith` instead, so every country-independent setting
  /// carries over — and a field added to `UserProfile` later is carried
  /// automatically rather than being forgotten at a hand-written mapping.
  ///
  /// Only the country-specific context changes: a fresh [id], the target
  /// [countryCode], the [fuel] resolved for that country (see
  /// `CountryFuelCapability`, #4258) and a [name]. `languageCode` is kept
  /// from [source] — the UI language is the user's choice, not a property
  /// of the country being added.
  ///
  /// Pure: builds the model without writing it.
  UserProfile cloneProfileForCountry({
    required UserProfile source,
    required String countryCode,
    required FuelType fuel,
    required String name,
  }) {
    return source.copyWith(
      id: _uuid.v4(),
      name: name,
      countryCode: countryCode,
      preferredFuelType: fuel,
    );
  }

  /// #4259 — create the missing country profiles in [proposals], skipping
  /// any country that is already taken.
  ///
  /// Each proposal checks occupancy and persists within one main-isolate
  /// write queue, including overlapping confirmations. Failures remain
  /// individually retryable. This operation never writes the active pointer:
  /// an explicit country switch while saving must not be undone.
  Future<CountryProfileBatchResult> createMissingCountryProfiles(
    List<CountryProfileProposal> proposals,
  ) async {
    final created = <UserProfile>[];
    final skipped = <String>[];
    final failed = <String, Object>{};

    for (final proposal in proposals) {
      final code = _country(proposal.countryCode) ?? proposal.countryCode;
      try {
        await _write(() async {
          if (isCountryTaken(code)) {
            skipped.add(code);
            return;
          }
          final profile = cloneProfileForCountry(
            source: proposal.source,
            countryCode: code,
            fuel: proposal.fuel,
            name: proposal.name,
          );
          await updateProfile(profile);
          created.add(profile);
        });
      } catch (e, st) {
        // Preserve diagnostics while reporting this country as retryable.
        log.error(
          e,
          st,
          layer: ErrorLayer.storage,
          context: {
            'where': 'ProfileRepository.createMissingCountryProfiles',
            'country': code,
          },
        );
        failed[code] = e;
      }
    }

    return CountryProfileBatchResult(
      created: created,
      skipped: skipped,
      failed: failed,
    );
  }
}

/// #4259 — one country to be set up, resolved before any UI is shown.
///
/// [fuel] comes from `CountryFuelCapability.resolveForCountry` (#4258); a
/// country with no valid fuel never becomes a proposal, so this type
/// cannot represent an unusable suggestion.
class CountryProfileProposal {
  const CountryProfileProposal({
    required this.source,
    required this.countryCode,
    required this.fuel,
    required this.name,
  });

  /// The profile used as a template — normally the active one.
  final UserProfile source;

  /// Upper-case ISO 3166-1 alpha-2 code of the country to add.
  final String countryCode;

  /// The grade resolved for [countryCode] (#4258).
  final FuelType fuel;

  /// Display name to persist. Derived by the caller from the localized
  /// country name so the user never has to invent one (#4263).
  final String name;
}

/// #4259 — the outcome of [ProfileRepository.createMissingCountryProfiles].
///
/// Three outcomes are reported separately because the UX needs them
/// separately: "Spain added / Italy couldn't be set up right now /
/// [Retry Italy]" (#4257 §7). A partially-failed batch must never render
/// as "Done".
class CountryProfileBatchResult {
  const CountryProfileBatchResult({
    required this.created,
    required this.skipped,
    required this.failed,
  });

  /// Profiles written by this call.
  final List<UserProfile> created;

  /// Country codes that already had a profile — a safe no-op, not an error.
  final List<String> skipped;

  /// Country code → the error that stopped it. Retry targets exactly these.
  final Map<String, Object> failed;

  /// Whether every proposal resolved to a profile (created or already
  /// present). False means the caller must offer a retry rather than
  /// reporting success.
  bool get isComplete => failed.isEmpty;

  /// Whether anything was actually written — the signal to refresh profile
  /// state and rerun the pending search (#4260).
  bool get hasChanges => created.isNotEmpty;
}
