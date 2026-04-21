// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_stations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via the EV favorites provider (different entity format).
/// The UI merges both into a single list.
///
/// Split out of `favorites_provider.dart` in #727 — the file had grown
/// past 300 LOC; this notifier's per-country refresh logic is the
/// biggest chunk and stands on its own.

@ProviderFor(FavoriteStations)
final favoriteStationsProvider = FavoriteStationsProvider._();

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via the EV favorites provider (different entity format).
/// The UI merges both into a single list.
///
/// Split out of `favorites_provider.dart` in #727 — the file had grown
/// past 300 LOC; this notifier's per-country refresh logic is the
/// biggest chunk and stands on its own.
final class FavoriteStationsProvider
    extends
        $NotifierProvider<
          FavoriteStations,
          AsyncValue<ServiceResult<List<Station>>>
        > {
  /// Loads fuel station data for favorites and refreshes prices.
  ///
  /// Returns fuel favorites as [List<Station>]. EV favorites are loaded
  /// separately via the EV favorites provider (different entity format).
  /// The UI merges both into a single list.
  ///
  /// Split out of `favorites_provider.dart` in #727 — the file had grown
  /// past 300 LOC; this notifier's per-country refresh logic is the
  /// biggest chunk and stands on its own.
  FavoriteStationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteStationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteStationsHash();

  @$internal
  @override
  FavoriteStations create() => FavoriteStations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ServiceResult<List<Station>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<ServiceResult<List<Station>>>>(value),
    );
  }
}

String _$favoriteStationsHash() => r'c0cbf6ca605257f0a93fb7c3dc019d19912531fe';

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via the EV favorites provider (different entity format).
/// The UI merges both into a single list.
///
/// Split out of `favorites_provider.dart` in #727 — the file had grown
/// past 300 LOC; this notifier's per-country refresh logic is the
/// biggest chunk and stands on its own.

abstract class _$FavoriteStations
    extends $Notifier<AsyncValue<ServiceResult<List<Station>>>> {
  AsyncValue<ServiceResult<List<Station>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ServiceResult<List<Station>>>,
              AsyncValue<ServiceResult<List<Station>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ServiceResult<List<Station>>>,
                AsyncValue<ServiceResult<List<Station>>>
              >,
              AsyncValue<ServiceResult<List<Station>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
