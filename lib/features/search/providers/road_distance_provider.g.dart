// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'road_distance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single road-distance fetch seam, injectable so tests never touch
/// the network. Defaults to the shared [RoutingService] table call.

@ProviderFor(roadDistanceFetcher)
final roadDistanceFetcherProvider = RoadDistanceFetcherProvider._();

/// The single road-distance fetch seam, injectable so tests never touch
/// the network. Defaults to the shared [RoutingService] table call.

final class RoadDistanceFetcherProvider
    extends
        $FunctionalProvider<
          Future<List<double?>> Function(
            double lat,
            double lng,
            List<({double lat, double lng})> destinations,
          ),
          Future<List<double?>> Function(
            double lat,
            double lng,
            List<({double lat, double lng})> destinations,
          ),
          Future<List<double?>> Function(
            double lat,
            double lng,
            List<({double lat, double lng})> destinations,
          )
        >
    with
        $Provider<
          Future<List<double?>> Function(
            double lat,
            double lng,
            List<({double lat, double lng})> destinations,
          )
        > {
  /// The single road-distance fetch seam, injectable so tests never touch
  /// the network. Defaults to the shared [RoutingService] table call.
  RoadDistanceFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roadDistanceFetcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roadDistanceFetcherHash();

  @$internal
  @override
  $ProviderElement<
    Future<List<double?>> Function(
      double lat,
      double lng,
      List<({double lat, double lng})> destinations,
    )
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Future<List<double?>> Function(
    double lat,
    double lng,
    List<({double lat, double lng})> destinations,
  )
  create(Ref ref) {
    return roadDistanceFetcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Future<List<double?>> Function(
      double lat,
      double lng,
      List<({double lat, double lng})> destinations,
    )
    value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            Future<List<double?>> Function(
              double lat,
              double lng,
              List<({double lat, double lng})> destinations,
            )
          >(value),
    );
  }
}

String _$roadDistanceFetcherHash() =>
    r'e51a006f17661a15390f83f9c984d2d157b9cafe';

/// Station-id → real road distance (km) for the radar surface (#3634).
///
/// Display-only enrichment: the crow-flies figure always remains the
/// baseline, sorting stays with the ranking authority, and any failure
/// leaves the map as-is (silent degrade — the list must never suffer for
/// a routing hiccup). Session-lived; `keepAlive` so paging around the
/// app doesn't refetch.

@ProviderFor(RoadDistances)
final roadDistancesProvider = RoadDistancesProvider._();

/// Station-id → real road distance (km) for the radar surface (#3634).
///
/// Display-only enrichment: the crow-flies figure always remains the
/// baseline, sorting stays with the ranking authority, and any failure
/// leaves the map as-is (silent degrade — the list must never suffer for
/// a routing hiccup). Session-lived; `keepAlive` so paging around the
/// app doesn't refetch.
final class RoadDistancesProvider
    extends $NotifierProvider<RoadDistances, Map<String, double>> {
  /// Station-id → real road distance (km) for the radar surface (#3634).
  ///
  /// Display-only enrichment: the crow-flies figure always remains the
  /// baseline, sorting stays with the ranking authority, and any failure
  /// leaves the map as-is (silent degrade — the list must never suffer for
  /// a routing hiccup). Session-lived; `keepAlive` so paging around the
  /// app doesn't refetch.
  RoadDistancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roadDistancesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roadDistancesHash();

  @$internal
  @override
  RoadDistances create() => RoadDistances();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$roadDistancesHash() => r'3f3e1638dd24f72f372f75b27a96c12b4b53f08a';

/// Station-id → real road distance (km) for the radar surface (#3634).
///
/// Display-only enrichment: the crow-flies figure always remains the
/// baseline, sorting stays with the ranking authority, and any failure
/// leaves the map as-is (silent degrade — the list must never suffer for
/// a routing hiccup). Session-lived; `keepAlive` so paging around the
/// app doesn't refetch.

abstract class _$RoadDistances extends $Notifier<Map<String, double>> {
  Map<String, double> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, double>, Map<String, double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, double>, Map<String, double>>,
              Map<String, double>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
