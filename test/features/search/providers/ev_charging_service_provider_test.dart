import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/search/providers/ev_charging_service_provider.dart';

void main() {
  group('evChargingServiceProvider (#728 part 2)', () {
    test('returns null when no EV API key is configured', () {
      final container = ProviderContainer(overrides: [
        apiKeyStorageProvider.overrideWith((_) => _FakeApiKeyStorage(null)),
      ]);
      addTearDown(container.dispose);

      expect(container.read(evChargingServiceProvider), isNull);
    });

    test('returns null when the key string is empty', () {
      final container = ProviderContainer(overrides: [
        apiKeyStorageProvider.overrideWith((_) => _FakeApiKeyStorage('')),
      ]);
      addTearDown(container.dispose);

      expect(container.read(evChargingServiceProvider), isNull);
    });

    test('returns an EVChargingService when a key is set', () {
      final container = ProviderContainer(overrides: [
        apiKeyStorageProvider.overrideWith(
            (_) => _FakeApiKeyStorage('ocm-live-key')),
      ]);
      addTearDown(container.dispose);

      final service = container.read(evChargingServiceProvider);
      expect(service, isNotNull);
      expect(service!.apiKey, 'ocm-live-key');
    });

    test('same reference returned on repeat reads (keepAlive)', () {
      final container = ProviderContainer(overrides: [
        apiKeyStorageProvider.overrideWith(
            (_) => _FakeApiKeyStorage('ocm-live-key')),
      ]);
      addTearDown(container.dispose);

      final a = container.read(evChargingServiceProvider);
      final b = container.read(evChargingServiceProvider);
      expect(identical(a, b), isTrue,
          reason: 'keepAlive should cache the constructed service');
    });
  });
}

class _FakeApiKeyStorage implements ApiKeyStorage {
  final String? _evKey;
  _FakeApiKeyStorage(this._evKey);

  @override
  String? getEvApiKey() => _evKey;

  @override
  bool hasEvApiKey() => _evKey != null && _evKey.isNotEmpty;

  @override
  Future<void> setEvApiKey(String key) async {}

  @override
  String? getApiKey() => null;
  @override
  bool hasApiKey() => false;
  @override
  bool hasCustomApiKey() => false;
  @override
  bool hasCustomEvApiKey() => false;
  @override
  Future<void> setApiKey(String key) async {}
  @override
  Future<void> deleteApiKey() async {}
  @override
  String? getSupabaseAnonKey() => null;
  @override
  Future<void> setSupabaseAnonKey(String key) async {}
  @override
  Future<void> deleteSupabaseAnonKey() async {}
}
