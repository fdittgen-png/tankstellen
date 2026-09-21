// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';

import '../cache/cache_manager.dart';
import '../data/storage_repository.dart';

/// The dependencies every per-country raw `StationService` can need,
/// resolved **once** by whoever builds the service (#2861).
///
/// This is the seam that makes country-service construction Riverpod-free:
/// the foreground reads each field from a `Ref`, the WorkManager / BGTask
/// background isolate constructs them directly from the isolate's
/// [HiveStorage], but the per-country wiring (each entry's
/// `CountryServiceEntry.buildService` factory, #3746) is *byte-identical*
/// for both — there is one construction path.
///
///  - [storage] backs the API-key gate (DE/KR/CL/GB), the OSM brand
///    enricher (FR legacy), and is the [CacheStorage] the bulk datasets
///    persist to.
///  - [cache] is the [CacheStrategy] the bulk-dataset services
///    (ES/IT/AR/DK + the flag-gated FR/GB bulk paths) read-through. #4110
///    pointed it at the `datasets` box: it is the dataset channel and
///    nothing else — every consumer passes it straight to a service's
///    `cache:`, which each service uses only to build its
///    `PersistentDataset`. The chain's per-key response cache is a
///    separate argument.
///  - [tankerkoenigDio] is the rate-limited, API-key-injecting Dio the DE
///    Tankerkönig service talks through. Background callers build a plain
///    rate-limited Dio (the key is sent per-request); the foreground hands
///    the interceptor-wired `tankerkoenigDioProvider` instance.
class CountryServiceDependencies {
  const CountryServiceDependencies({
    required this.storage,
    required this.cache,
    required this.tankerkoenigDio,
  });

  /// Storage repository (favorites, settings, API keys, cache).
  final StorageRepository storage;

  /// Cache layer the bulk-dataset services persist through — the
  /// `datasets` box in production (#4110).
  final CacheStrategy cache;

  /// Dio for the DE Tankerkönig service. Only the DE factory reads it; other
  /// countries build their own Dio internally, so it is allowed to be null
  /// for non-DE construction.
  final Dio? tankerkoenigDio;
}
