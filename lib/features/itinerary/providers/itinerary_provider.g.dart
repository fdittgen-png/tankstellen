// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'itinerary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the first server merge is still running (#3993).
///
/// [ItineraryNotifier.build] returns LOCAL rows synchronously, so the
/// list is usually correct immediately. It is not for the one user who
/// matters here: a fresh device whose routes exist only on the server.
/// For them the local list is empty until the merge lands, and the
/// screen would state — as fact — that they have no saved routes.
///
/// This flag is true only while that first merge is in flight AND the
/// local list came back empty, which is exactly the window where
/// "you have none" would be a lie.

@ProviderFor(ItineraryFirstLoad)
final itineraryFirstLoadProvider = ItineraryFirstLoadProvider._();

/// Whether the first server merge is still running (#3993).
///
/// [ItineraryNotifier.build] returns LOCAL rows synchronously, so the
/// list is usually correct immediately. It is not for the one user who
/// matters here: a fresh device whose routes exist only on the server.
/// For them the local list is empty until the merge lands, and the
/// screen would state — as fact — that they have no saved routes.
///
/// This flag is true only while that first merge is in flight AND the
/// local list came back empty, which is exactly the window where
/// "you have none" would be a lie.
final class ItineraryFirstLoadProvider
    extends $NotifierProvider<ItineraryFirstLoad, bool> {
  /// Whether the first server merge is still running (#3993).
  ///
  /// [ItineraryNotifier.build] returns LOCAL rows synchronously, so the
  /// list is usually correct immediately. It is not for the one user who
  /// matters here: a fresh device whose routes exist only on the server.
  /// For them the local list is empty until the merge lands, and the
  /// screen would state — as fact — that they have no saved routes.
  ///
  /// This flag is true only while that first merge is in flight AND the
  /// local list came back empty, which is exactly the window where
  /// "you have none" would be a lie.
  ItineraryFirstLoadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itineraryFirstLoadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itineraryFirstLoadHash();

  @$internal
  @override
  ItineraryFirstLoad create() => ItineraryFirstLoad();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$itineraryFirstLoadHash() =>
    r'0dfe97200ff5fcbd5e2e8c84047b6484bf60060a';

/// Whether the first server merge is still running (#3993).
///
/// [ItineraryNotifier.build] returns LOCAL rows synchronously, so the
/// list is usually correct immediately. It is not for the one user who
/// matters here: a fresh device whose routes exist only on the server.
/// For them the local list is empty until the merge lands, and the
/// screen would state — as fact — that they have no saved routes.
///
/// This flag is true only while that first merge is in flight AND the
/// local list came back empty, which is exactly the window where
/// "you have none" would be a lie.

abstract class _$ItineraryFirstLoad extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Manages saved itineraries with local-first strategy:
/// - Save locally first, then sync to DB
/// - Load from DB first, then overwrite with local (local wins)
/// - Sync only adds/changes, never deletes (except explicit user delete)

@ProviderFor(ItineraryNotifier)
final itineraryProvider = ItineraryNotifierProvider._();

/// Manages saved itineraries with local-first strategy:
/// - Save locally first, then sync to DB
/// - Load from DB first, then overwrite with local (local wins)
/// - Sync only adds/changes, never deletes (except explicit user delete)
final class ItineraryNotifierProvider
    extends $NotifierProvider<ItineraryNotifier, List<SavedItinerary>> {
  /// Manages saved itineraries with local-first strategy:
  /// - Save locally first, then sync to DB
  /// - Load from DB first, then overwrite with local (local wins)
  /// - Sync only adds/changes, never deletes (except explicit user delete)
  ItineraryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itineraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itineraryNotifierHash();

  @$internal
  @override
  ItineraryNotifier create() => ItineraryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SavedItinerary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SavedItinerary>>(value),
    );
  }
}

String _$itineraryNotifierHash() => r'fcacc950462238b66cf918424534986bc353561a';

/// Manages saved itineraries with local-first strategy:
/// - Save locally first, then sync to DB
/// - Load from DB first, then overwrite with local (local wins)
/// - Sync only adds/changes, never deletes (except explicit user delete)

abstract class _$ItineraryNotifier extends $Notifier<List<SavedItinerary>> {
  List<SavedItinerary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<SavedItinerary>, List<SavedItinerary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SavedItinerary>, List<SavedItinerary>>,
              List<SavedItinerary>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
