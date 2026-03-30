// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$itineraryNotifierHash() => r'276798959b32d9574fa602dba883925013806b71';

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
