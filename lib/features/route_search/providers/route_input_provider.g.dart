// GENERATED CODE - DO NOT MODIFY BY HAND

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
    r'72f4cac4c2a27328131f37427eedaf65c6766d47';

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
