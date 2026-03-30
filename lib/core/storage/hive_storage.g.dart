// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(hiveStorage)
final hiveStorageProvider = HiveStorageProvider._();

final class HiveStorageProvider
    extends $FunctionalProvider<HiveStorage, HiveStorage, HiveStorage>
    with $Provider<HiveStorage> {
  HiveStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hiveStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hiveStorageHash();

  @$internal
  @override
  $ProviderElement<HiveStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HiveStorage create(Ref ref) {
    return hiveStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HiveStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HiveStorage>(value),
    );
  }
}

String _$hiveStorageHash() => r'0065432c5793eb55670ad24f2ca9a090b7e5e09a';
