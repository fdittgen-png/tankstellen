import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../storage/hive_storage.dart';
import '../storage/storage_keys.dart';
import 'country_detection_provider.dart';
import 'country_provider.dart';

part 'country_switch_event.g.dart';

enum CountrySwitchAction { suggest, autoSwitch, noProfile }

class CountrySwitchEvent {
  final CountrySwitchAction action;
  final String detectedCountryCode;
  final UserProfile? matchingProfile;

  const CountrySwitchEvent({
    required this.action,
    required this.detectedCountryCode,
    this.matchingProfile,
  });
}

/// Computes whether a profile switch should be suggested based on
/// the detected country vs. the active profile's country.
@riverpod
CountrySwitchEvent? countrySwitchEvent(Ref ref) {
  final detected = ref.watch(detectedCountryProvider);
  if (detected == null) return null;

  final activeCountry = ref.watch(activeCountryProvider);
  if (detected == activeCountry.code) return null;

  // Find a profile configured for the detected country
  final allProfiles = ref.read(allProfilesProvider);
  final match = allProfiles
      .where((p) => p.countryCode == detected)
      .toList();
  final matchingProfile = match.isNotEmpty ? match.first : null;

  final storage = ref.read(hiveStorageProvider);
  final autoSwitch =
      storage.getSetting(StorageKeys.autoSwitchProfile) as bool? ?? false;

  if (matchingProfile != null && autoSwitch) {
    return CountrySwitchEvent(
      action: CountrySwitchAction.autoSwitch,
      detectedCountryCode: detected,
      matchingProfile: matchingProfile,
    );
  } else if (matchingProfile != null) {
    return CountrySwitchEvent(
      action: CountrySwitchAction.suggest,
      detectedCountryCode: detected,
      matchingProfile: matchingProfile,
    );
  } else {
    return CountrySwitchEvent(
      action: CountrySwitchAction.noProfile,
      detectedCountryCode: detected,
    );
  }
}
