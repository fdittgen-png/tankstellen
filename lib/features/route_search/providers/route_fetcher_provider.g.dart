// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'route_fetcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single route-fetch seam of the route search (#4432).
///
/// `RouteSearchState` used to construct its [RoutingService] inline, so
/// the one path that matters for a "current position" search — submit
/// or refresh, re-resolve the origin, route from it — could only be
/// tested around the route fetch, never through it. Overriding this
/// provider lets a test record which origin was actually routed and
/// answer with a recorded polyline, without a public endpoint. It is
/// the sibling of `roadDistanceFetcherProvider` and
/// `travelEstimateFetcherProvider`, which already do the same for the
/// `/table` calls.

@ProviderFor(routeFetcher)
final routeFetcherProvider = RouteFetcherProvider._();

/// The single route-fetch seam of the route search (#4432).
///
/// `RouteSearchState` used to construct its [RoutingService] inline, so
/// the one path that matters for a "current position" search — submit
/// or refresh, re-resolve the origin, route from it — could only be
/// tested around the route fetch, never through it. Overriding this
/// provider lets a test record which origin was actually routed and
/// answer with a recorded polyline, without a public endpoint. It is
/// the sibling of `roadDistanceFetcherProvider` and
/// `travelEstimateFetcherProvider`, which already do the same for the
/// `/table` calls.

final class RouteFetcherProvider
    extends $FunctionalProvider<RouteFetcher, RouteFetcher, RouteFetcher>
    with $Provider<RouteFetcher> {
  /// The single route-fetch seam of the route search (#4432).
  ///
  /// `RouteSearchState` used to construct its [RoutingService] inline, so
  /// the one path that matters for a "current position" search — submit
  /// or refresh, re-resolve the origin, route from it — could only be
  /// tested around the route fetch, never through it. Overriding this
  /// provider lets a test record which origin was actually routed and
  /// answer with a recorded polyline, without a public endpoint. It is
  /// the sibling of `roadDistanceFetcherProvider` and
  /// `travelEstimateFetcherProvider`, which already do the same for the
  /// `/table` calls.
  RouteFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeFetcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeFetcherHash();

  @$internal
  @override
  $ProviderElement<RouteFetcher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RouteFetcher create(Ref ref) {
    return routeFetcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteFetcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteFetcher>(value),
    );
  }
}

String _$routeFetcherHash() => r'cceb0c3f3e72bfca5149c3ba9832f08ccc4b9e61';
