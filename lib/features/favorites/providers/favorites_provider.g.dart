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

String _$favoritesHash() => r'eeaeaaf2b3ab96588c1b76279fb72409c6f0414e';

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
