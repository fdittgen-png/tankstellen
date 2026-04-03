// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$apiKeyStorageHash() => r'3b9e06c7d8886cf008dd6950e21982c1ba634aa5';

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

String _$settingsStorageHash() => r'79d5e3b00ed88836938003399827b5e66594159c';

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

String _$storageManagementHash() => r'965e4f04f5b60889c5329bbde96030f0d8349f39';
