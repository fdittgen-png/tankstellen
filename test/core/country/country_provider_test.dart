import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';

import '../../mocks/mocks.dart';

class _FixedActiveProfile extends ActiveProfile {
  final UserProfile? _value;
  _FixedActiveProfile(this._value);

  @override
  UserProfile? build() => _value;
}

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  ProviderContainer createContainer({
    UserProfile? profile,
    String? savedCountryCode,
  }) {
    when(() => mockStorage.getSetting('active_country_code'))
        .thenReturn(savedCountryCode);

    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
      activeProfileProvider.overrideWith(() => _FixedActiveProfile(profile)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('ActiveCountry — precedence', () {
    test('priority 1: active profile with a countryCode wins', () {
      final container = createContainer(
        profile: const UserProfile(
          id: 'p-de',
          name: 'Germany',
          countryCode: 'DE',
        ),
        savedCountryCode: 'FR', // would otherwise win if no profile
      );

      expect(container.read(activeCountryProvider).code, 'DE');
    });

    test('priority 2: persisted setting when no profile country',
        () {
      final container = createContainer(
        profile: const UserProfile(id: 'p', name: 'none'),
        savedCountryCode: 'AT',
      );
      expect(container.read(activeCountryProvider).code, 'AT');
    });

    test('unknown persisted code falls through to locale detection', () {
      // A previously stored country code that is no longer supported
      // must not strand the user — the provider falls back to the
      // locale-inferred country (or Germany as final default).
      final container = createContainer(
        profile: null,
        savedCountryCode: 'ZZ',
      );
      final resolved = container.read(activeCountryProvider);
      // The fallback is whatever Countries.fromLocale returns; at
      // minimum it must be a real known country.
      expect(Countries.byCode(resolved.code), isNotNull);
    });

    test('profile with null countryCode is ignored, falls to storage',
        () {
      final container = createContainer(
        profile: const UserProfile(id: 'p', name: 'none'),
        savedCountryCode: 'IT',
      );
      expect(container.read(activeCountryProvider).code, 'IT');
    });
  });
}
