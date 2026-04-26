import 'dart:ui' as ui;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/search/providers/search_provider.dart';
import '../storage/storage_providers.dart';
import '../utils/price_formatter.dart';
import 'country_config.dart';

part 'country_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveCountry extends _$ActiveCountry {
  static const _storageKey = 'active_country_code';

  @override
  CountryConfig build() {
    // Priority 1: active profile's country
    final profile = ref.watch(activeProfileProvider);
    if (profile?.countryCode != null) {
      final fromProfile = Countries.byCode(profile!.countryCode!);
      if (fromProfile != null) return _applyCountry(fromProfile);
    }

    // Priority 2: persisted setting (legacy / migration)
    final storage = ref.watch(storageRepositoryProvider);
    final savedCode = storage.getSetting(_storageKey) as String?;
    if (savedCode != null) {
      return _applyCountry(Countries.byCode(savedCode) ?? _detectFromLocale());
    }

    return _applyCountry(_detectFromLocale());
  }

  /// Apply country to price formatter when country changes.
  CountryConfig _applyCountry(CountryConfig config) {
    PriceFormatter.setCountry(config.code);
    return config;
  }

  /// Auto-detect country from system locale.
  CountryConfig _detectFromLocale() {
    final locale = ui.PlatformDispatcher.instance.locale.toString();
    return Countries.fromLocale(locale);
  }

  /// User explicitly selects a country.
  Future<void> select(CountryConfig country) async {
    final previousCode = state.code;

    // Update legacy storage
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(_storageKey, country.code);

    // Update active profile if it exists
    final profile = ref.read(activeProfileProvider);
    if (profile != null) {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        profile.copyWith(countryCode: country.code),
      );
      ref.read(activeProfileProvider.notifier).refresh();
    }

    state = country;

    // #753 — invalidate search results so the next render fetches fresh
    // ones from the new country's API. Without this, a stale country-A
    // search cache shadows country-B widget taps that share a numeric
    // id (the original bug). Mirrors the guard in
    // `ActiveProfile.switchProfile` so every country-change path is
    // covered (manual selector, profile edit, auto-switch).
    if (previousCode != country.code) {
      ref.invalidate(searchStateProvider);
    }
  }
}
