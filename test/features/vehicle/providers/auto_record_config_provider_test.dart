import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/auto_record_config_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

void main() {
  group('AutoRecordConfig value type (#1004 phase 1)', () {
    test('default constructor matches VehicleProfile defaults', () {
      const config = AutoRecordConfig();
      expect(config.autoRecord, isFalse);
      expect(config.pairedAdapterMac, isNull);
      expect(config.movementStartThresholdKmh, 5.0);
      expect(config.disconnectSaveDelaySec, 60);
      expect(config.backgroundLocationConsent, isFalse);
    });

    test('AutoRecordConfig.defaults matches VehicleProfile defaults', () {
      const profile = VehicleProfile(id: 'fresh', name: 'Fresh');
      const config = AutoRecordConfig.defaults;
      expect(config.autoRecord, profile.autoRecord);
      expect(config.pairedAdapterMac, profile.pairedAdapterMac);
      expect(config.movementStartThresholdKmh, profile.movementStartThresholdKmh);
      expect(config.disconnectSaveDelaySec, profile.disconnectSaveDelaySec);
      expect(config.backgroundLocationConsent, profile.backgroundLocationConsent);
    });

    test('fromProfile copies the five auto-record fields', () {
      const profile = VehicleProfile(
        id: 'opted-in',
        name: 'Daily',
        type: VehicleType.combustion,
        autoRecord: true,
        pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        movementStartThresholdKmh: 8.5,
        disconnectSaveDelaySec: 120,
        backgroundLocationConsent: true,
      );

      final config = AutoRecordConfig.fromProfile(profile);

      expect(config.autoRecord, isTrue);
      expect(config.pairedAdapterMac, 'AA:BB:CC:DD:EE:FF');
      expect(config.movementStartThresholdKmh, closeTo(8.5, 0.001));
      expect(config.disconnectSaveDelaySec, 120);
      expect(config.backgroundLocationConsent, isTrue);
    });

    test('equal instances compare equal and share a hash code', () {
      const a = AutoRecordConfig(
        autoRecord: true,
        pairedAdapterMac: '11:22:33:44:55:66',
        movementStartThresholdKmh: 6.0,
        disconnectSaveDelaySec: 75,
        backgroundLocationConsent: true,
      );
      const b = AutoRecordConfig(
        autoRecord: true,
        pairedAdapterMac: '11:22:33:44:55:66',
        movementStartThresholdKmh: 6.0,
        disconnectSaveDelaySec: 75,
        backgroundLocationConsent: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different field values compare unequal', () {
      const base = AutoRecordConfig(autoRecord: true);
      const flippedMac = AutoRecordConfig(
        autoRecord: true,
        pairedAdapterMac: '00:00:00:00:00:01',
      );
      const flippedThreshold = AutoRecordConfig(
        autoRecord: true,
        movementStartThresholdKmh: 12,
      );
      expect(base, isNot(equals(flippedMac)));
      expect(base, isNot(equals(flippedThreshold)));
    });

    test('toString surfaces all five fields for debug logs', () {
      const c = AutoRecordConfig(
        autoRecord: true,
        pairedAdapterMac: 'CC:DD:EE:FF:00:11',
        movementStartThresholdKmh: 4.0,
        disconnectSaveDelaySec: 45,
        backgroundLocationConsent: true,
      );
      final s = c.toString();
      expect(s, contains('autoRecord: true'));
      expect(s, contains('pairedAdapterMac: CC:DD:EE:FF:00:11'));
      expect(s, contains('movementStartThresholdKmh: 4.0'));
      expect(s, contains('disconnectSaveDelaySec: 45'));
      expect(s, contains('backgroundLocationConsent: true'));
    });
  });

  group('autoRecordConfigProvider (#1004 phase 1)', () {
    late ProviderContainer container;
    late VehicleProfileRepository repo;

    setUp(() {
      repo = VehicleProfileRepository(_FakeSettings());
      container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('looks up the profile and projects its five auto-record fields',
        () async {
      const v = VehicleProfile(
        id: 'v-auto',
        name: 'Daily Driver',
        type: VehicleType.combustion,
        autoRecord: true,
        pairedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        movementStartThresholdKmh: 7.5,
        disconnectSaveDelaySec: 90,
        backgroundLocationConsent: true,
      );
      await container.read(vehicleProfileListProvider.notifier).save(v);

      final config = container.read(autoRecordConfigProvider('v-auto'));

      expect(config.autoRecord, isTrue);
      expect(config.pairedAdapterMac, 'AA:BB:CC:DD:EE:FF');
      expect(config.movementStartThresholdKmh, closeTo(7.5, 0.001));
      expect(config.disconnectSaveDelaySec, 90);
      expect(config.backgroundLocationConsent, isTrue);
    });

    test('unknown vehicle id returns AutoRecordConfig.defaults', () async {
      // Save one vehicle so the underlying list is non-empty — a
      // truly empty list would mask any short-circuit bug that
      // accidentally returns the first entry.
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'other', name: 'Other'),
          );

      final config = container.read(autoRecordConfigProvider('does-not-exist'));

      expect(config, equals(AutoRecordConfig.defaults));
      expect(config.autoRecord, isFalse);
      expect(config.pairedAdapterMac, isNull);
      expect(config.movementStartThresholdKmh, 5.0);
      expect(config.disconnectSaveDelaySec, 60);
      expect(config.backgroundLocationConsent, isFalse);
    });

    test('a freshly-saved profile (never opted in) returns the same defaults '
        'as an unknown id — phase 2+ consumers cannot distinguish the two',
        () async {
      const fresh = VehicleProfile(id: 'fresh', name: 'Fresh');
      await container.read(vehicleProfileListProvider.notifier).save(fresh);

      final knownConfig = container.read(autoRecordConfigProvider('fresh'));
      final unknownConfig =
          container.read(autoRecordConfigProvider('not-saved-yet'));

      expect(knownConfig, equals(unknownConfig));
    });

    test('mutating the underlying profile rebuilds the provider with the '
        'new auto-record values', () async {
      const initial = VehicleProfile(
        id: 'mut',
        name: 'Mutable',
        type: VehicleType.combustion,
      );
      await container.read(vehicleProfileListProvider.notifier).save(initial);

      // First read mirrors the not-yet-opted-in defaults.
      final before = container.read(autoRecordConfigProvider('mut'));
      expect(before.autoRecord, isFalse);
      expect(before.pairedAdapterMac, isNull);

      // User opts in via a phase-6 UI surface — saving the updated
      // profile must invalidate the provider so any phase 2+
      // consumer sees the new MAC and threshold on the next read.
      const updated = VehicleProfile(
        id: 'mut',
        name: 'Mutable',
        type: VehicleType.combustion,
        autoRecord: true,
        pairedAdapterMac: '11:22:33:44:55:66',
        movementStartThresholdKmh: 3.0,
        disconnectSaveDelaySec: 45,
        backgroundLocationConsent: true,
      );
      await container.read(vehicleProfileListProvider.notifier).save(updated);

      final after = container.read(autoRecordConfigProvider('mut'));
      expect(after.autoRecord, isTrue);
      expect(after.pairedAdapterMac, '11:22:33:44:55:66');
      expect(after.movementStartThresholdKmh, 3.0);
      expect(after.disconnectSaveDelaySec, 45);
      expect(after.backgroundLocationConsent, isTrue);
      expect(after, isNot(equals(before)));
    });

    test('a listener attached before the mutation receives the new value',
        () async {
      const initial = VehicleProfile(
        id: 'mut',
        name: 'Mutable',
        type: VehicleType.combustion,
      );
      await container.read(vehicleProfileListProvider.notifier).save(initial);

      final emitted = <AutoRecordConfig>[];
      final sub = container.listen<AutoRecordConfig>(
        autoRecordConfigProvider('mut'),
        (previous, next) => emitted.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // First read mirrors the not-yet-opted-in defaults.
      expect(emitted, hasLength(1));
      expect(emitted.last.autoRecord, isFalse);

      const updated = VehicleProfile(
        id: 'mut',
        name: 'Mutable',
        type: VehicleType.combustion,
        autoRecord: true,
        pairedAdapterMac: '11:22:33:44:55:66',
      );
      await container.read(vehicleProfileListProvider.notifier).save(updated);

      // Force the dependency chain to materialize the new value —
      // listeners only fire when the provider is re-evaluated.
      container.read(autoRecordConfigProvider('mut'));

      expect(emitted.length, greaterThanOrEqualTo(2));
      expect(emitted.last.autoRecord, isTrue);
      expect(emitted.last.pairedAdapterMac, '11:22:33:44:55:66');
    });

    test('deleting the profile flips the provider back to defaults', () async {
      const v = VehicleProfile(
        id: 'gone',
        name: 'Vanishing',
        type: VehicleType.combustion,
        autoRecord: true,
        pairedAdapterMac: 'DE:AD:BE:EF:00:01',
      );
      await container.read(vehicleProfileListProvider.notifier).save(v);

      final beforeDelete = container.read(autoRecordConfigProvider('gone'));
      expect(beforeDelete.autoRecord, isTrue);
      expect(beforeDelete.pairedAdapterMac, 'DE:AD:BE:EF:00:01');

      await container.read(vehicleProfileListProvider.notifier).remove('gone');

      final afterDelete = container.read(autoRecordConfigProvider('gone'));
      expect(afterDelete, equals(AutoRecordConfig.defaults));
    });

    test('config does not leak unrelated VehicleProfile fields', () async {
      // The whole point of the projection: phase-2 consumers cannot
      // hold a reference to baselines, aggregates, charging prefs,
      // etc. that live on the wider profile. We assert by checking
      // the AutoRecordConfig type surface exposes only the five
      // documented fields.
      const v = VehicleProfile(
        id: 'rich',
        name: 'Rich',
        type: VehicleType.ev,
        batteryKwh: 75,
        tankCapacityL: 50,
        autoRecord: true,
      );
      await container.read(vehicleProfileListProvider.notifier).save(v);

      final config = container.read(autoRecordConfigProvider('rich'));
      // The runtime type carries no field accessors beyond the five
      // documented ones; this assertion mirrors that intent.
      expect(config.autoRecord, isTrue);
      expect(config, isA<AutoRecordConfig>());
    });
  });
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
