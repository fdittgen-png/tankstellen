// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the user's list of favorite station IDs.
///
/// ## Local-first pattern:
/// - **Writes**: Save to Hive immediately, then sync to Supabase asynchronously.
/// - **Reads**: Load from Hive on startup (instant), then merge with server data.
/// - **Deletes**: Remove locally + from server (exception to "sync never deletes" rule
///   because this is an explicit user action).
///
/// Uses `keepAlive: true` because favorites persist across the entire app lifecycle.

@ProviderFor(Favorites)
final favoritesProvider = FavoritesProvider._();

/// Manages the user's list of favorite station IDs.
///
/// ## Local-first pattern:
/// - **Writes**: Save to Hive immediately, then sync to Supabase asynchronously.
/// - **Reads**: Load from Hive on startup (instant), then merge with server data.
/// - **Deletes**: Remove locally + from server (exception to "sync never deletes" rule
///   because this is an explicit user action).
///
/// Uses `keepAlive: true` because favorites persist across the entire app lifecycle.
final class FavoritesProvider
    extends $NotifierProvider<Favorites, List<String>> {
  /// Manages the user's list of favorite station IDs.
  ///
  /// ## Local-first pattern:
  /// - **Writes**: Save to Hive immediately, then sync to Supabase asynchronously.
  /// - **Reads**: Load from Hive on startup (instant), then merge with server data.
  /// - **Deletes**: Remove locally + from server (exception to "sync never deletes" rule
  ///   because this is an explicit user action).
  ///
  /// Uses `keepAlive: true` because favorites persist across the entire app lifecycle.
  FavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesHash();

  @$internal
  @override
  Favorites create() => Favorites();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$favoritesHash() => r'1472d9efc6c5f230389b5f23f77f05d1fcef51d2';

/// Manages the user's list of favorite station IDs.
///
/// ## Local-first pattern:
/// - **Writes**: Save to Hive immediately, then sync to Supabase asynchronously.
/// - **Reads**: Load from Hive on startup (instant), then merge with server data.
/// - **Deletes**: Remove locally + from server (exception to "sync never deletes" rule
///   because this is an explicit user action).
///
/// Uses `keepAlive: true` because favorites persist across the entire app lifecycle.

abstract class _$Favorites extends $Notifier<List<String>> {
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

/// Whether a specific station is favorited. Rebuilds when favorites change.

@ProviderFor(isFavorite)
final isFavoriteProvider = IsFavoriteFamily._();

/// Whether a specific station is favorited. Rebuilds when favorites change.

final class IsFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific station is favorited. Rebuilds when favorites change.
  IsFavoriteProvider._({
    required IsFavoriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteHash();

  @override
  String toString() {
    return r'isFavoriteProvider'
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
    return isFavorite(ref, argument);
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
    return other is IsFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteHash() => r'407f8aa58c4a51cd73bb614574835fabbf173b80';

/// Whether a specific station is favorited. Rebuilds when favorites change.

final class IsFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavoriteFamily._()
    : super(
        retry: null,
        name: r'isFavoriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a specific station is favorited. Rebuilds when favorites change.

  IsFavoriteProvider call(String stationId) =>
      IsFavoriteProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isFavoriteProvider';
}

/// Loads station data for favorites and refreshes prices.
///
/// ## Data flow (local-first):
/// 1. Load persisted Station objects from Hive (permanent, never expires)
/// 2. Check connectivity — if offline, return persisted data with `isStale: true`
/// 3. If online, refresh prices via StationService.getPrices()
/// 4. Merge fresh prices into stations, persist updated data back
/// 5. On API failure, serve persisted data with stale flag

@ProviderFor(FavoriteStations)
final favoriteStationsProvider = FavoriteStationsProvider._();

/// Loads station data for favorites and refreshes prices.
///
/// ## Data flow (local-first):
/// 1. Load persisted Station objects from Hive (permanent, never expires)
/// 2. Check connectivity — if offline, return persisted data with `isStale: true`
/// 3. If online, refresh prices via StationService.getPrices()
/// 4. Merge fresh prices into stations, persist updated data back
/// 5. On API failure, serve persisted data with stale flag
final class FavoriteStationsProvider
    extends
        $NotifierProvider<
          FavoriteStations,
          AsyncValue<ServiceResult<List<Station>>>
        > {
  /// Loads station data for favorites and refreshes prices.
  ///
  /// ## Data flow (local-first):
  /// 1. Load persisted Station objects from Hive (permanent, never expires)
  /// 2. Check connectivity — if offline, return persisted data with `isStale: true`
  /// 3. If online, refresh prices via StationService.getPrices()
  /// 4. Merge fresh prices into stations, persist updated data back
  /// 5. On API failure, serve persisted data with stale flag
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

String _$favoriteStationsHash() => r'3f07e655c1a1a72ca4d6586b5e5794d69a60cb82';

/// Loads station data for favorites and refreshes prices.
///
/// ## Data flow (local-first):
/// 1. Load persisted Station objects from Hive (permanent, never expires)
/// 2. Check connectivity — if offline, return persisted data with `isStale: true`
/// 3. If online, refresh prices via StationService.getPrices()
/// 4. Merge fresh prices into stations, persist updated data back
/// 5. On API failure, serve persisted data with stale flag

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
