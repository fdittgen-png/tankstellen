// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merged_favorites_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's fuel + EV favorites merged into one mixed
/// [SearchResultItem] list (#1786), ordered by distance so the
/// favorites tab renders a single interleaved list (#1787) rather than
/// two labelled sections.
///
/// The two Hive boxes stay separate — the merge is purely at the
/// provider layer. Fuel favorites come from [favoriteStationsProvider]
/// (which owns the per-country price refresh and the loading / error
/// lifecycle the tab still reads); EV favorites from
/// [evFavoriteStationsProvider]. `isFavorite` / `toggle` are untouched.

@ProviderFor(mergedFavorites)
final mergedFavoritesProvider = MergedFavoritesProvider._();

/// The user's fuel + EV favorites merged into one mixed
/// [SearchResultItem] list (#1786), ordered by distance so the
/// favorites tab renders a single interleaved list (#1787) rather than
/// two labelled sections.
///
/// The two Hive boxes stay separate — the merge is purely at the
/// provider layer. Fuel favorites come from [favoriteStationsProvider]
/// (which owns the per-country price refresh and the loading / error
/// lifecycle the tab still reads); EV favorites from
/// [evFavoriteStationsProvider]. `isFavorite` / `toggle` are untouched.

final class MergedFavoritesProvider
    extends
        $FunctionalProvider<
          List<SearchResultItem>,
          List<SearchResultItem>,
          List<SearchResultItem>
        >
    with $Provider<List<SearchResultItem>> {
  /// The user's fuel + EV favorites merged into one mixed
  /// [SearchResultItem] list (#1786), ordered by distance so the
  /// favorites tab renders a single interleaved list (#1787) rather than
  /// two labelled sections.
  ///
  /// The two Hive boxes stay separate — the merge is purely at the
  /// provider layer. Fuel favorites come from [favoriteStationsProvider]
  /// (which owns the per-country price refresh and the loading / error
  /// lifecycle the tab still reads); EV favorites from
  /// [evFavoriteStationsProvider]. `isFavorite` / `toggle` are untouched.
  MergedFavoritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mergedFavoritesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mergedFavoritesHash();

  @$internal
  @override
  $ProviderElement<List<SearchResultItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SearchResultItem> create(Ref ref) {
    return mergedFavorites(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchResultItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchResultItem>>(value),
    );
  }
}

String _$mergedFavoritesHash() => r'264894e22c87f313618149dafd9b69f361b2f0b9';
