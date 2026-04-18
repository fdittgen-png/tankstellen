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

String _$favoritesHash() => r'90e15c837b7d248909ff35d28fc2226a75601269';

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

/// Whether a specific station is favorited (checks both fuel and EV).

@ProviderFor(isFavorite)
final isFavoriteProvider = IsFavoriteFamily._();

/// Whether a specific station is favorited (checks both fuel and EV).

final class IsFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific station is favorited (checks both fuel and EV).
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

/// Whether a specific station is favorited (checks both fuel and EV).

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

  /// Whether a specific station is favorited (checks both fuel and EV).

  IsFavoriteProvider call(String stationId) =>
      IsFavoriteProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isFavoriteProvider';
}

/// Whether a specific EV station is favorited (backward compatibility alias).

@ProviderFor(isEvFavorite)
final isEvFavoriteProvider = IsEvFavoriteFamily._();

/// Whether a specific EV station is favorited (backward compatibility alias).

final class IsEvFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific EV station is favorited (backward compatibility alias).
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

String _$isEvFavoriteHash() => r'acd73588a221554915fd24b7637376e73cfacdc8';

/// Whether a specific EV station is favorited (backward compatibility alias).

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

  /// Whether a specific EV station is favorited (backward compatibility alias).

  IsEvFavoriteProvider call(String stationId) =>
      IsEvFavoriteProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isEvFavoriteProvider';
}

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via [evFavoriteStationsProvider] (different entity format).
/// The UI merges both into a single list.

@ProviderFor(FavoriteStations)
final favoriteStationsProvider = FavoriteStationsProvider._();

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via [evFavoriteStationsProvider] (different entity format).
/// The UI merges both into a single list.
final class FavoriteStationsProvider
    extends
        $NotifierProvider<
          FavoriteStations,
          AsyncValue<ServiceResult<List<Station>>>
        > {
  /// Loads fuel station data for favorites and refreshes prices.
  ///
  /// Returns fuel favorites as [List<Station>]. EV favorites are loaded
  /// separately via [evFavoriteStationsProvider] (different entity format).
  /// The UI merges both into a single list.
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

String _$favoriteStationsHash() => r'2423fe97b711c45913ec4fe49ed282faf32b8070';

/// Loads fuel station data for favorites and refreshes prices.
///
/// Returns fuel favorites as [List<Station>]. EV favorites are loaded
/// separately via [evFavoriteStationsProvider] (different entity format).
/// The UI merges both into a single list.

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
