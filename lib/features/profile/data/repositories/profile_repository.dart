import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../search/domain/entities/fuel_type.dart';
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
    return UserProfile.fromJson(data);
  }

  List<UserProfile> getAllProfiles() {
    return _storage
        .getAllProfiles()
        .map((data) => UserProfile.fromJson(data))
        .toList();
  }

  Future<UserProfile> createProfile({
    required String name,
    FuelType preferredFuelType = FuelType.e10,
    double defaultSearchRadius = 10.0,
    LandingScreen landingScreen = LandingScreen.search,
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
}
