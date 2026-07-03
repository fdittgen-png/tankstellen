// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/station_services/uk/uk_service_builder.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_statutory_fallback_station_service.dart';

/// #3190 — GB service selection: registered Fuel Finder credentials route GB
/// through the statutory bulk primary (legacy fan-out as fallback); anything
/// else keeps the pre-#3190 keyless behaviour.

/// Minimal in-memory [CacheStrategy] (no Hive).
class _MemCache implements CacheStrategy {
  final Map<String, CacheEntry> entries = {};

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    entries[key] = CacheEntry(
      payload: data,
      storedAt: DateTime.now(),
      originalSource: source,
      ttl: ttl,
    );
  }

  @override
  CacheEntry? get(String key) => entries[key];

  @override
  CacheEntry? getFresh(String key) {
    final e = entries[key];
    if (e == null || e.isExpired) return null;
    return e;
  }
}

void main() {
  group('buildGbStationService (#3190)', () {
    test('packed client_id:client_secret → statutory primary with legacy '
        'fallback', () {
      final service = buildGbStationService(
        apiKey: 'client-abc:secret-xyz',
        cache: _MemCache(),
      );
      expect(service, isA<UkStatutoryFallbackStationService>());
    });

    test('no key → legacy retailer fan-out (pre-#3190 behaviour)', () {
      final service = buildGbStationService(
        apiKey: null,
        cache: _MemCache(),
      );
      expect(service, isA<UkStationService>());
    });

    test('a non-credential key (e.g. a Tankerkönig key in the shared slot) '
        'stays on the legacy fan-out', () {
      final service = buildGbStationService(
        apiKey: '00000000-0000-0000-0000-000000000002',
        cache: _MemCache(),
      );
      expect(service, isA<UkStationService>());
    });
  });
}
