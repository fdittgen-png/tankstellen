// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ev_favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the user's list of favorite EV charging station IDs.
///
/// Mirrors [Favorites] but for [ChargingStation] entities.

@ProviderFor(EvFavorites)
final evFavoritesProvider = EvFavoritesProvider._();

/// Manages the user's list of favorite EV charging station IDs.
///
/// Mirrors [Favorites] but for [ChargingStation] entities.
final class EvFavoritesProvider
    extends $NotifierProvider<EvFavorites, List<String>> {
  /// Manages the user's list of favorite EV charging station IDs.
  ///
  /// Mirrors [Favorites] but for [ChargingStation] entities.
  EvFavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evFavoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evFavoritesHash();

  @$internal
  @override
  EvFavorites create() => EvFavorites();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$evFavoritesHash() => r'1e16aec6b6db0f3dee062687b33f5e29c66935df';

/// Manages the user's list of favorite EV charging station IDs.
///
/// Mirrors [Favorites] but for [ChargingStation] entities.

abstract class _$EvFavorites extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether a specific EV station is favorited.

@ProviderFor(isEvFavorite)
final isEvFavoriteProvider = IsEvFavoriteFamily._();

/// Whether a specific EV station is favorited.

final class IsEvFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific EV station is favorited.
  IsEvFavoriteProvider._({
    required IsEvFavoriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isEvFavoriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isEvFavoriteHash();

  @override
  String toString() {
    return r'isEvFavoriteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isEvFavorite(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsEvFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isEvFavoriteHash() => r'36fb646620e239f6189455f792f4b3217007fed9';

/// Whether a specific EV station is favorited.

final class IsEvFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsEvFavoriteFamily._()
    : super(
        retry: null,
        name: r'isEvFavoriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a specific EV station is favorited.

  IsEvFavoriteProvider call(String stationId) =>
      IsEvFavoriteProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isEvFavoriteProvider';
}

/// Loads persisted EV station data for favorites.

@ProviderFor(EvFavoriteStations)
final evFavoriteStationsProvider = EvFavoriteStationsProvider._();

/// Loads persisted EV station data for favorites.
final class EvFavoriteStationsProvider
    extends $NotifierProvider<EvFavoriteStations, List<ChargingStation>> {
  /// Loads persisted EV station data for favorites.
  EvFavoriteStationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evFavoriteStationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evFavoriteStationsHash();

  @$internal
  @override
  EvFavoriteStations create() => EvFavoriteStations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChargingStation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChargingStation>>(value),
    );
  }
}

String _$evFavoriteStationsHash() =>
    r'5f94bec82bdf6fdfe0827fb5a05da110a2d66206';

/// Loads persisted EV station data for favorites.

abstract class _$EvFavoriteStations extends $Notifier<List<ChargingStation>> {
  List<ChargingStation> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ChargingStation>, List<ChargingStation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ChargingStation>, List<ChargingStation>>,
              List<ChargingStation>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
