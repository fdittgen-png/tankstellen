// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'privacy_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Collects the device-data inventory from the storage layer.

@ProviderFor(deviceDataInventory)
final deviceDataInventoryProvider = DeviceDataInventoryProvider._();

/// Collects the device-data inventory from the storage layer.

final class DeviceDataInventoryProvider
    extends
        $FunctionalProvider<
          DeviceDataInventory,
          DeviceDataInventory,
          DeviceDataInventory
        >
    with $Provider<DeviceDataInventory> {
  /// Collects the device-data inventory from the storage layer.
  DeviceDataInventoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceDataInventoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceDataInventoryHash();

  @$internal
  @override
  $ProviderElement<DeviceDataInventory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceDataInventory create(Ref ref) {
    return deviceDataInventory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceDataInventory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceDataInventory>(value),
    );
  }
}

String _$deviceDataInventoryHash() =>
    r'8a2ae491c1f97f30f188c425ce66f7e39c2b6d37';

/// Exports all user data as a JSON string for GDPR data portability.
///
/// Excludes API keys for security — the user re-enters those on import.
/// Excludes cache data because it is ephemeral and reconstructable.

@ProviderFor(exportPrivacyData)
final exportPrivacyDataProvider = ExportPrivacyDataProvider._();

/// Exports all user data as a JSON string for GDPR data portability.
///
/// Excludes API keys for security — the user re-enters those on import.
/// Excludes cache data because it is ephemeral and reconstructable.

final class ExportPrivacyDataProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Exports all user data as a JSON string for GDPR data portability.
  ///
  /// Excludes API keys for security — the user re-enters those on import.
  /// Excludes cache data because it is ephemeral and reconstructable.
  ExportPrivacyDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportPrivacyDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportPrivacyDataHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return exportPrivacyData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$exportPrivacyDataHash() => r'0734ab85ebe78e42069067342530347b7414e25c';
