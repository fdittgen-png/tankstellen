// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3592 — the MAP-side [evStationService] provider must source the OCM
// key from [ApiKeyStorage.getEvApiKey] (secure store + shipped default),
// exactly like the search side. The regression it pins: the old generic
// settings-box read returned null forever, so the map overlay silently
// served demo stations even for configured users.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/ev/data/services/open_charge_map_service.dart';
import 'package:tankstellen/features/ev/providers/ev_providers.dart';

void main() {
  group('evStationService key sourcing (#3592)', () {
    test('uses the ApiKeyStorage key — the secure store, not the plain box',
        () {
      final container = ProviderContainer(overrides: [
        apiKeyStorageProvider.overrideWith(
            (_) => _FakeApiKeyStorage('ocm-map-key')),
      ]);
      addTearDown(container.dispose);

      final service = container.read(evStationServiceProvider);
      expect(service, isA<OpenChargeMapService>());
      expect((service as OpenChargeMapService).apiKey, 'ocm-map-key',
          reason: 'the map overlay must query real OCM with the '
              'configured/default key, not fall back to demo data');
    });

    test('a null key still constructs the service (demo fallback inside)',
        () {
      final container = ProviderContainer(overrides: [
        apiKeyStorageProvider.overrideWith((_) => _FakeApiKeyStorage(null)),
      ]);
      addTearDown(container.dispose);

      final service = container.read(evStationServiceProvider);
      expect(service, isA<OpenChargeMapService>());
      expect((service as OpenChargeMapService).apiKey, isNull);
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

