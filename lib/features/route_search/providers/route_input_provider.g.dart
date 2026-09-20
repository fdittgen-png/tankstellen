// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'route_input_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RouteInputController)
final routeInputControllerProvider = RouteInputControllerProvider._();

final class RouteInputControllerProvider
    extends $NotifierProvider<RouteInputController, RouteInputState> {
  RouteInputControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeInputControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeInputControllerHash();

  @$internal
  @override
  RouteInputController create() => RouteInputController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteInputState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteInputState>(value),
    );
  }
}

String _$routeInputControllerHash() =>
    r'bf9c5028599e1a14115f2fcb904cddde66098f62';

abstract class _$RouteInputController extends $Notifier<RouteInputState> {
  RouteInputState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RouteInputState, RouteInputState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RouteInputState, RouteInputState>,
              RouteInputState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
