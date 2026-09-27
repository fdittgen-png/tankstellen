// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'storage_repository.dart';

/// Cache stores whose readiness or payload conversion requires asynchronous work.
abstract interface class AsyncCacheStorage implements CacheStorage {
  Future<Map<String, dynamic>?> getCachedDataAsync(String key);
}
