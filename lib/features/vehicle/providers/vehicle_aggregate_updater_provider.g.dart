// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_aggregate_updater_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod-managed instance of [VehicleAggregateUpdater] (#1193 phase 2).
///
/// `keepAlive: true` so the production wiring can `ref.read` it once
/// from `app_initializer.dart`, install it as the
/// `TripHistoryRepository.onSavedHook`, and let it live for the rest
/// of the app session. Tests override it with a fake updater that
/// records calls.

@ProviderFor(vehicleAggregateUpdater)
final vehicleAggregateUpdaterProvider = VehicleAggregateUpdaterProvider._();

/// Riverpod-managed instance of [VehicleAggregateUpdater] (#1193 phase 2).
///
/// `keepAlive: true` so the production wiring can `ref.read` it once
/// from `app_initializer.dart`, install it as the
/// `TripHistoryRepository.onSavedHook`, and let it live for the rest
/// of the app session. Tests override it with a fake updater that
/// records calls.

final class VehicleAggregateUpdaterProvider
    extends
        $FunctionalProvider<
          VehicleAggregateUpdater,
          VehicleAggregateUpdater,
          VehicleAggregateUpdater
        >
    with $Provider<VehicleAggregateUpdater> {
  /// Riverpod-managed instance of [VehicleAggregateUpdater] (#1193 phase 2).
  ///
  /// `keepAlive: true` so the production wiring can `ref.read` it once
  /// from `app_initializer.dart`, install it as the
  /// `TripHistoryRepository.onSavedHook`, and let it live for the rest
  /// of the app session. Tests override it with a fake updater that
  /// records calls.
  VehicleAggregateUpdaterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleAggregateUpdaterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleAggregateUpdaterHash();

  @$internal
  @override
  $ProviderElement<VehicleAggregateUpdater> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VehicleAggregateUpdater create(Ref ref) {
    return vehicleAggregateUpdater(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleAggregateUpdater value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleAggregateUpdater>(value),
    );
  }
}

String _$vehicleAggregateUpdaterHash() =>
    r'add2aed16bb557bda4e398e4a9ed1845873dd5f2';
