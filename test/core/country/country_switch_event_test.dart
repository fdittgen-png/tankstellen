import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_detection_provider.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/country/country_switch_event.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';

import '../../fakes/fake_hive_storage.dart';

class _FixedDetectedCountry extends DetectedCountry {
  final String? _value;
  _FixedDetectedCountry(this._value);

  @override
  String? build() => _value;
}

class _FixedActiveCountry extends ActiveCountry {
  final CountryConfig _value;
  _FixedActiveCountry(this._value);

  @override
  CountryConfig build() => _value;
}

const _frenchProfile = UserProfile(
  id: 'p-fr',
  name: 'France',
  countryCode: 'FR',
);

const _germanProfile = UserProfile(
  id: 'p-de',
  name: 'Germany',
  countryCode: 'DE',
);

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    fakeStorage.putSetting(StorageKeys.autoSwitchProfile, false);
  });

  ProviderContainer createContainer({
    String? detected,
    CountryConfig active = Countries.france,
    List<UserProfile> profiles = const [],
  }) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      detectedCountryProvider
          .overrideWith(() => _FixedDetectedCountry(detected)),
      activeCountryProvider.overrideWith(() => _FixedActiveCountry(active)),
      allProfilesProvider.overrideWith((ref) => profiles),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('countrySwitchEvent', () {
    test('returns null when no country is detected yet', () {
      final c = createContainer(detected: null);
      expect(c.read(countrySwitchEventProvider), isNull);
    });

    test('returns null when the detected country matches the active one',
        () {
      final c = createContainer(
        detected: 'FR',
        active: Countries.france,
      );
      expect(c.read(countrySwitchEventProvider), isNull);
    });

    test('returns "noProfile" when detected country has no matching profile',
        () {
      final c = createContainer(
        detected: 'DE',
        active: Countries.france,
        profiles: const [_frenchProfile],
      );

      final ev = c.read(countrySwitchEventProvider);
      expect(ev, isNotNull);
      expect(ev!.action, CountrySwitchAction.noProfile);
      expect(ev.detectedCountryCode, 'DE');
      expect(ev.matchingProfile, isNull);
    });

    test('returns "suggest" when profile matches but auto-switch is off',
        () async {
      await fakeStorage.putSetting(StorageKeys.autoSwitchProfile, false);

      final c = createContainer(
        detected: 'DE',
        active: Countries.france,
        profiles: const [_frenchProfile, _germanProfile],
      );

      final ev = c.read(countrySwitchEventProvider);
      expect(ev, isNotNull);
      expect(ev!.action, CountrySwitchAction.suggest);
      expect(ev.matchingProfile?.id, 'p-de');
    });

    test('returns "autoSwitch" when profile matches AND autoSwitch is on',
        () async {
      await fakeStorage.putSetting(StorageKeys.autoSwitchProfile, true);

      final c = createContainer(
        detected: 'DE',
        active: Countries.france,
        profiles: const [_germanProfile],
      );

      final ev = c.read(countrySwitchEventProvider);
      expect(ev, isNotNull);
      expect(ev!.action, CountrySwitchAction.autoSwitch);
      expect(ev.matchingProfile?.id, 'p-de');
    });

    test('autoSwitch only fires when a matching profile EXISTS — no profile '
        'still returns "noProfile" even with the flag on', () async {
      await fakeStorage.putSetting(StorageKeys.autoSwitchProfile, true);

      final c = createContainer(
        detected: 'IT',
        active: Countries.france,
        profiles: const [_frenchProfile],
      );

      expect(c.read(countrySwitchEventProvider)!.action,
          CountrySwitchAction.noProfile);
    });
  });
}
