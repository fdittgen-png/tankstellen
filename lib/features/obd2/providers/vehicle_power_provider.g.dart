// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'vehicle_power_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3860 (Epic #3855) — the fused vehicle power state for the UI: the
/// banners key the Reset action on it (retry-with-reset only while the
/// engine runs), the status vocabulary names it.
///
/// Republishes the process-wide model's transitions; the initial value is
/// the model's current verdict, so a widget mounting mid-drive reads the
/// right state before the first change.

@ProviderFor(VehiclePower)
final vehiclePowerProvider = VehiclePowerProvider._();

/// #3860 (Epic #3855) — the fused vehicle power state for the UI: the
/// banners key the Reset action on it (retry-with-reset only while the
/// engine runs), the status vocabulary names it.
///
/// Republishes the process-wide model's transitions; the initial value is
/// the model's current verdict, so a widget mounting mid-drive reads the
/// right state before the first change.
final class VehiclePowerProvider
    extends $NotifierProvider<VehiclePower, VehiclePowerState> {
  /// #3860 (Epic #3855) — the fused vehicle power state for the UI: the
  /// banners key the Reset action on it (retry-with-reset only while the
  /// engine runs), the status vocabulary names it.
  ///
  /// Republishes the process-wide model's transitions; the initial value is
  /// the model's current verdict, so a widget mounting mid-drive reads the
  /// right state before the first change.
  VehiclePowerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehiclePowerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehiclePowerHash();

  @$internal
  @override
  VehiclePower create() => VehiclePower();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehiclePowerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehiclePowerState>(value),
    );
  }
}

String _$vehiclePowerHash() => r'96c866c1a6ba03483879afca9a1f6414c4bc9db3';

/// #3860 (Epic #3855) — the fused vehicle power state for the UI: the
/// banners key the Reset action on it (retry-with-reset only while the
/// engine runs), the status vocabulary names it.
///
/// Republishes the process-wide model's transitions; the initial value is
/// the model's current verdict, so a widget mounting mid-drive reads the
/// right state before the first change.

abstract class _$VehiclePower extends $Notifier<VehiclePowerState> {
  VehiclePowerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VehiclePowerState, VehiclePowerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VehiclePowerState, VehiclePowerState>,
              VehiclePowerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
