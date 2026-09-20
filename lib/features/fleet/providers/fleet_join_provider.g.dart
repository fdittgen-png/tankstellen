// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fleet_join_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The wire seam. Null when TankSync is not initialised or nobody is
/// signed in; tests override it with `FakeFleetTransport`.

@ProviderFor(fleetTransport)
final fleetTransportProvider = FleetTransportProvider._();

/// The wire seam. Null when TankSync is not initialised or nobody is
/// signed in; tests override it with `FakeFleetTransport`.

final class FleetTransportProvider
    extends
        $FunctionalProvider<FleetTransport?, FleetTransport?, FleetTransport?>
    with $Provider<FleetTransport?> {
  /// The wire seam. Null when TankSync is not initialised or nobody is
  /// signed in; tests override it with `FakeFleetTransport`.
  FleetTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetTransportHash();

  @$internal
  @override
  $ProviderElement<FleetTransport?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FleetTransport? create(Ref ref) {
    return fleetTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetTransport? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetTransport?>(value),
    );
  }
}

String _$fleetTransportHash() => r'0c06bdb8aefcc69790e43625f305d0726b49e0b1';

/// The join service for the current session, or null when there is no
/// transport to talk through.

@ProviderFor(fleetJoinService)
final fleetJoinServiceProvider = FleetJoinServiceProvider._();

/// The join service for the current session, or null when there is no
/// transport to talk through.

final class FleetJoinServiceProvider
    extends
        $FunctionalProvider<
          FleetJoinService?,
          FleetJoinService?,
          FleetJoinService?
        >
    with $Provider<FleetJoinService?> {
  /// The join service for the current session, or null when there is no
  /// transport to talk through.
  FleetJoinServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetJoinServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetJoinServiceHash();

  @$internal
  @override
  $ProviderElement<FleetJoinService?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FleetJoinService? create(Ref ref) {
    return fleetJoinService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetJoinService? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetJoinService?>(value),
    );
  }
}

String _$fleetJoinServiceHash() => r'd8268c0556ebf4f928b66cb6b73473c1da1645a4';

/// Drives [FleetJoinService] and republishes the fleet scope on success.

@ProviderFor(FleetJoinController)
final fleetJoinControllerProvider = FleetJoinControllerProvider._();

/// Drives [FleetJoinService] and republishes the fleet scope on success.
final class FleetJoinControllerProvider
    extends $NotifierProvider<FleetJoinController, FleetJoinState> {
  /// Drives [FleetJoinService] and republishes the fleet scope on success.
  FleetJoinControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetJoinControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetJoinControllerHash();

  @$internal
  @override
  FleetJoinController create() => FleetJoinController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetJoinState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetJoinState>(value),
    );
  }
}

String _$fleetJoinControllerHash() =>
    r'18ead4c78f2b74ac385c8fb93e20a2bcc8071355';

/// Drives [FleetJoinService] and republishes the fleet scope on success.

abstract class _$FleetJoinController extends $Notifier<FleetJoinState> {
  FleetJoinState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FleetJoinState, FleetJoinState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FleetJoinState, FleetJoinState>,
              FleetJoinState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
