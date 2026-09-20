// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'current_fleet_vehicle_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current fleet vehicle. Explicit selection only.

@ProviderFor(CurrentFleetVehicle)
final currentFleetVehicleProvider = CurrentFleetVehicleProvider._();

/// The current fleet vehicle. Explicit selection only.
final class CurrentFleetVehicleProvider
    extends $NotifierProvider<CurrentFleetVehicle, CurrentVehicleContext> {
  /// The current fleet vehicle. Explicit selection only.
  CurrentFleetVehicleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentFleetVehicleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentFleetVehicleHash();

  @$internal
  @override
  CurrentFleetVehicle create() => CurrentFleetVehicle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CurrentVehicleContext value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CurrentVehicleContext>(value),
    );
  }
}

String _$currentFleetVehicleHash() =>
    r'83893d72c926e4ab322835c8946b170811ba9274';

/// The current fleet vehicle. Explicit selection only.

abstract class _$CurrentFleetVehicle extends $Notifier<CurrentVehicleContext> {
  CurrentVehicleContext build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CurrentVehicleContext, CurrentVehicleContext>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CurrentVehicleContext, CurrentVehicleContext>,
              CurrentVehicleContext,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
