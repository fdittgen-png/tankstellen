// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Orchestrates "cheapest stations along my route" feature.
///
/// 1. Fetches route from OSRM
/// 2. Delegates station search to a [RouteSearchStrategy]
/// 3. Computes cheapest per segment

@ProviderFor(RouteSearchState)
final routeSearchStateProvider = RouteSearchStateProvider._();

/// Orchestrates "cheapest stations along my route" feature.
///
/// 1. Fetches route from OSRM
/// 2. Delegates station search to a [RouteSearchStrategy]
/// 3. Computes cheapest per segment
final class RouteSearchStateProvider
    extends
        $NotifierProvider<RouteSearchState, AsyncValue<RouteSearchResult?>> {
  /// Orchestrates "cheapest stations along my route" feature.
  ///
  /// 1. Fetches route from OSRM
  /// 2. Delegates station search to a [RouteSearchStrategy]
  /// 3. Computes cheapest per segment
  RouteSearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeSearchStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeSearchStateHash();

  @$internal
  @override
  RouteSearchState create() => RouteSearchState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RouteSearchResult?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RouteSearchResult?>>(
        value,
      ),
    );
  }
}

String _$routeSearchStateHash() => r'23a677ec2692a63c3b087e4a9d9927b28f0d0afa';

/// Orchestrates "cheapest stations along my route" feature.
///
/// 1. Fetches route from OSRM
/// 2. Delegates station search to a [RouteSearchStrategy]
/// 3. Computes cheapest per segment

abstract class _$RouteSearchState
    extends $Notifier<AsyncValue<RouteSearchResult?>> {
  AsyncValue<RouteSearchResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<RouteSearchResult?>,
              AsyncValue<RouteSearchResult?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RouteSearchResult?>,
                AsyncValue<RouteSearchResult?>
              >,
              AsyncValue<RouteSearchResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
