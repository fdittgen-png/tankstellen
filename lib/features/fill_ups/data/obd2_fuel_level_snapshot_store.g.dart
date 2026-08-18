// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'obd2_fuel_level_snapshot_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide store instance over the production storage repository.

@ProviderFor(obd2FuelLevelSnapshotStore)
final obd2FuelLevelSnapshotStoreProvider =
    Obd2FuelLevelSnapshotStoreProvider._();

/// App-wide store instance over the production storage repository.

final class Obd2FuelLevelSnapshotStoreProvider
    extends
        $FunctionalProvider<
          Obd2FuelLevelSnapshotStore,
          Obd2FuelLevelSnapshotStore,
          Obd2FuelLevelSnapshotStore
        >
    with $Provider<Obd2FuelLevelSnapshotStore> {
  /// App-wide store instance over the production storage repository.
  Obd2FuelLevelSnapshotStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2FuelLevelSnapshotStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2FuelLevelSnapshotStoreHash();

  @$internal
  @override
  $ProviderElement<Obd2FuelLevelSnapshotStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2FuelLevelSnapshotStore create(Ref ref) {
    return obd2FuelLevelSnapshotStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2FuelLevelSnapshotStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2FuelLevelSnapshotStore>(value),
    );
  }
}

String _$obd2FuelLevelSnapshotStoreHash() =>
    r'd59d3995853e12c3656daae7e553fbb9165c90fa';
