// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Central provider returning the abstract [StorageRepository].
///
/// All consumers should depend on this (or a narrow interface provider below)
/// instead of [hiveStorageProvider]. This enables swapping the storage backend
/// (e.g. to Drift or Isar) without touching any consumer code.

@ProviderFor(storageRepository)
final storageRepositoryProvider = StorageRepositoryProvider._();

/// Central provider returning the abstract [StorageRepository].
///
/// All consumers should depend on this (or a narrow interface provider below)
/// instead of [hiveStorageProvider]. This enables swapping the storage backend
/// (e.g. to Drift or Isar) without touching any consumer code.

final class StorageRepositoryProvider
    extends
        $FunctionalProvider<
          StorageRepository,
          StorageRepository,
          StorageRepository
        >
    with $Provider<StorageRepository> {
  /// Central provider returning the abstract [StorageRepository].
  ///
  /// All consumers should depend on this (or a narrow interface provider below)
  /// instead of [hiveStorageProvider]. This enables swapping the storage backend
  /// (e.g. to Drift or Isar) without touching any consumer code.
  StorageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageRepositoryHash();

  @$internal
  @override
  $ProviderElement<StorageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorageRepository create(Ref ref) {
    return storageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageRepository>(value),
    );
  }
}

String _$storageRepositoryHash() => r'db1dacf7e620b5ea50fc47fee5fd4a09d95c706c';

/// Narrow provider for API key operations (presentation-safe).

@ProviderFor(apiKeyStorage)
final apiKeyStorageProvider = ApiKeyStorageProvider._();

/// Narrow provider for API key operations (presentation-safe).

final class ApiKeyStorageProvider
    extends $FunctionalProvider<ApiKeyStorage, ApiKeyStorage, ApiKeyStorage>
    with $Provider<ApiKeyStorage> {
  /// Narrow provider for API key operations (presentation-safe).
  ApiKeyStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyStorageHash();

  @$internal
  @override
  $ProviderElement<ApiKeyStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiKeyStorage create(Ref ref) {
    return apiKeyStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiKeyStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiKeyStorage>(value),
    );
  }
}

String _$apiKeyStorageHash() => r'9f15d9c3107a8cce2fda19dec6ea60af6dac90ac';

/// Narrow provider for app settings (presentation-safe).

@ProviderFor(settingsStorage)
final settingsStorageProvider = SettingsStorageProvider._();

/// Narrow provider for app settings (presentation-safe).

final class SettingsStorageProvider
    extends
        $FunctionalProvider<SettingsStorage, SettingsStorage, SettingsStorage>
    with $Provider<SettingsStorage> {
  /// Narrow provider for app settings (presentation-safe).
  SettingsStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStorageHash();

  @$internal
  @override
  $ProviderElement<SettingsStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsStorage create(Ref ref) {
    return settingsStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsStorage>(value),
    );
  }
}

String _$settingsStorageHash() => r'4fb45b52d34aba9c9c350aa3ba694292c7adf094';

/// Narrow provider for favorite storage operations.

@ProviderFor(favoriteStorage)
final favoriteStorageProvider = FavoriteStorageProvider._();

/// Narrow provider for favorite storage operations.

final class FavoriteStorageProvider
    extends
        $FunctionalProvider<FavoriteStorage, FavoriteStorage, FavoriteStorage>
    with $Provider<FavoriteStorage> {
  /// Narrow provider for favorite storage operations.
  FavoriteStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteStorageHash();

  @$internal
  @override
  $ProviderElement<FavoriteStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FavoriteStorage create(Ref ref) {
    return favoriteStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoriteStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoriteStorage>(value),
    );
  }
}

String _$favoriteStorageHash() => r'2518dc2862ef2bac8cfe2283fe3ccc9dafab909e';

/// Narrow provider for EV favorite storage operations.

@ProviderFor(evFavoriteStorage)
final evFavoriteStorageProvider = EvFavoriteStorageProvider._();

/// Narrow provider for EV favorite storage operations.

final class EvFavoriteStorageProvider
    extends
        $FunctionalProvider<
          EvFavoriteStorage,
          EvFavoriteStorage,
          EvFavoriteStorage
        >
    with $Provider<EvFavoriteStorage> {
  /// Narrow provider for EV favorite storage operations.
  EvFavoriteStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evFavoriteStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evFavoriteStorageHash();

  @$internal
  @override
  $ProviderElement<EvFavoriteStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EvFavoriteStorage create(Ref ref) {
    return evFavoriteStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvFavoriteStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvFavoriteStorage>(value),
    );
  }
}

String _$evFavoriteStorageHash() => r'dd725c080adee2a6615812134a580c29471be85e';

/// Narrow provider for ignored station operations.

@ProviderFor(ignoredStorage)
final ignoredStorageProvider = IgnoredStorageProvider._();

/// Narrow provider for ignored station operations.

final class IgnoredStorageProvider
    extends $FunctionalProvider<IgnoredStorage, IgnoredStorage, IgnoredStorage>
    with $Provider<IgnoredStorage> {
  /// Narrow provider for ignored station operations.
  IgnoredStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ignoredStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ignoredStorageHash();

  @$internal
  @override
  $ProviderElement<IgnoredStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IgnoredStorage create(Ref ref) {
    return ignoredStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IgnoredStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IgnoredStorage>(value),
    );
  }
}

String _$ignoredStorageHash() => r'08dec1bb977ac2bf7f6a89b2bc96f0b612064253';

/// Narrow provider for station rating operations.

@ProviderFor(ratingStorage)
final ratingStorageProvider = RatingStorageProvider._();

/// Narrow provider for station rating operations.

final class RatingStorageProvider
    extends $FunctionalProvider<RatingStorage, RatingStorage, RatingStorage>
    with $Provider<RatingStorage> {
  /// Narrow provider for station rating operations.
  RatingStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ratingStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ratingStorageHash();

  @$internal
  @override
  $ProviderElement<RatingStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RatingStorage create(Ref ref) {
    return ratingStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RatingStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RatingStorage>(value),
    );
  }
}

String _$ratingStorageHash() => r'737f26541cc49166bde9db423a4a26dee47747d8';

/// Narrow provider for profile storage operations.

@ProviderFor(profileStorage)
final profileStorageProvider = ProfileStorageProvider._();

/// Narrow provider for profile storage operations.

final class ProfileStorageProvider
    extends $FunctionalProvider<ProfileStorage, ProfileStorage, ProfileStorage>
    with $Provider<ProfileStorage> {
  /// Narrow provider for profile storage operations.
  ProfileStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileStorageHash();

  @$internal
  @override
  $ProviderElement<ProfileStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileStorage create(Ref ref) {
    return profileStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileStorage>(value),
    );
  }
}

String _$profileStorageHash() => r'493788dcfcaa02c50caddece575c9966498bf10a';

/// Narrow provider for price history storage operations.

@ProviderFor(priceHistoryStorage)
final priceHistoryStorageProvider = PriceHistoryStorageProvider._();

/// Narrow provider for price history storage operations.

final class PriceHistoryStorageProvider
    extends
        $FunctionalProvider<
          PriceHistoryStorage,
          PriceHistoryStorage,
          PriceHistoryStorage
        >
    with $Provider<PriceHistoryStorage> {
  /// Narrow provider for price history storage operations.
  PriceHistoryStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'priceHistoryStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$priceHistoryStorageHash();

  @$internal
  @override
  $ProviderElement<PriceHistoryStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PriceHistoryStorage create(Ref ref) {
    return priceHistoryStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PriceHistoryStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PriceHistoryStorage>(value),
    );
  }
}

String _$priceHistoryStorageHash() =>
    r'8200fa158dd6db66b66121d2728f1eee8e149494';

/// Narrow provider for alert storage operations.

@ProviderFor(alertStorage)
final alertStorageProvider = AlertStorageProvider._();

/// Narrow provider for alert storage operations.

final class AlertStorageProvider
    extends $FunctionalProvider<AlertStorage, AlertStorage, AlertStorage>
    with $Provider<AlertStorage> {
  /// Narrow provider for alert storage operations.
  AlertStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertStorageHash();

  @$internal
  @override
  $ProviderElement<AlertStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertStorage create(Ref ref) {
    return alertStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertStorage>(value),
    );
  }
}

String _$alertStorageHash() => r'6997a74fb7bbf21e7024c7e9c934696910046257';

/// Narrow provider for itinerary storage operations.

@ProviderFor(itineraryStorage)
final itineraryStorageProvider = ItineraryStorageProvider._();

/// Narrow provider for itinerary storage operations.

final class ItineraryStorageProvider
    extends
        $FunctionalProvider<
          ItineraryStorage,
          ItineraryStorage,
          ItineraryStorage
        >
    with $Provider<ItineraryStorage> {
  /// Narrow provider for itinerary storage operations.
  ItineraryStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itineraryStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itineraryStorageHash();

  @$internal
  @override
  $ProviderElement<ItineraryStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ItineraryStorage create(Ref ref) {
    return itineraryStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ItineraryStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ItineraryStorage>(value),
    );
  }
}

String _$itineraryStorageHash() => r'fa4c9b2bf4be96c4a0525ad9591cb8098c999a3f';

/// Narrow provider for cache storage operations.

@ProviderFor(cacheStorage)
final cacheStorageProvider = CacheStorageProvider._();

/// Narrow provider for cache storage operations.

final class CacheStorageProvider
    extends $FunctionalProvider<CacheStorage, CacheStorage, CacheStorage>
    with $Provider<CacheStorage> {
  /// Narrow provider for cache storage operations.
  CacheStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheStorageHash();

  @$internal
  @override
  $ProviderElement<CacheStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheStorage create(Ref ref) {
    return cacheStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheStorage>(value),
    );
  }
}

String _$cacheStorageHash() => r'cd8359a072e2333a1cca2522c3bc12bebc363c36';

/// Narrow provider for cache + storage management (presentation-safe).

@ProviderFor(storageManagement)
final storageManagementProvider = StorageManagementProvider._();

/// Narrow provider for cache + storage management (presentation-safe).

final class StorageManagementProvider
    extends
        $FunctionalProvider<
          StorageManagement,
          StorageManagement,
          StorageManagement
        >
    with $Provider<StorageManagement> {
  /// Narrow provider for cache + storage management (presentation-safe).
  StorageManagementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageManagementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageManagementHash();

  @$internal
  @override
  $ProviderElement<StorageManagement> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorageManagement create(Ref ref) {
    return storageManagement(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageManagement value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageManagement>(value),
    );
  }
}

String _$storageManagementHash() => r'9ee5462f607b2e69397f2d301789fcb13e29632a';
