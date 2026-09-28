// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'route_origin_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Screen-scoped: lives while the route form shows it, and never
/// persists — a failure from an earlier visit is not this visit's news.

@ProviderFor(RouteOriginStatusController)
final routeOriginStatusControllerProvider =
    RouteOriginStatusControllerProvider._();

/// Screen-scoped: lives while the route form shows it, and never
/// persists — a failure from an earlier visit is not this visit's news.
final class RouteOriginStatusControllerProvider
    extends $NotifierProvider<RouteOriginStatusController, RouteOriginStatus> {
  /// Screen-scoped: lives while the route form shows it, and never
  /// persists — a failure from an earlier visit is not this visit's news.
  RouteOriginStatusControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeOriginStatusControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeOriginStatusControllerHash();

  @$internal
  @override
  RouteOriginStatusController create() => RouteOriginStatusController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteOriginStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteOriginStatus>(value),
    );
  }
}

String _$routeOriginStatusControllerHash() =>
    r'3ed9cb43b61e2cd61aafaff298c69cd4ccbd3f2a';

/// Screen-scoped: lives while the route form shows it, and never
/// persists — a failure from an earlier visit is not this visit's news.

abstract class _$RouteOriginStatusController
    extends $Notifier<RouteOriginStatus> {
  RouteOriginStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RouteOriginStatus, RouteOriginStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RouteOriginStatus, RouteOriginStatus>,
              RouteOriginStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
