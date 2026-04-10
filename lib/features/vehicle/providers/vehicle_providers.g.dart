// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for reading/writing [VehicleProfile] entries.

@ProviderFor(vehicleProfileRepository)
final vehicleProfileRepositoryProvider = VehicleProfileRepositoryProvider._();

/// Repository for reading/writing [VehicleProfile] entries.

final class VehicleProfileRepositoryProvider
    extends
        $FunctionalProvider<
          VehicleProfileRepository,
          VehicleProfileRepository,
          VehicleProfileRepository
        >
    with $Provider<VehicleProfileRepository> {
  /// Repository for reading/writing [VehicleProfile] entries.
  VehicleProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleProfileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<VehicleProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VehicleProfileRepository create(Ref ref) {
    return vehicleProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleProfileRepository>(value),
    );
  }
}

String _$vehicleProfileRepositoryHash() =>
    r'f466a06a3256a4e33dd5b5844e2952e55fb8b67d';

/// Full list of stored vehicle profiles.

@ProviderFor(VehicleProfileList)
final vehicleProfileListProvider = VehicleProfileListProvider._();

/// Full list of stored vehicle profiles.
final class VehicleProfileListProvider
    extends $NotifierProvider<VehicleProfileList, List<VehicleProfile>> {
  /// Full list of stored vehicle profiles.
  VehicleProfileListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleProfileListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleProfileListHash();

  @$internal
  @override
  VehicleProfileList create() => VehicleProfileList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VehicleProfile> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VehicleProfile>>(value),
    );
  }
}

String _$vehicleProfileListHash() =>
    r'c728b5804706e187f82fd462aa89a9bbeb49f8d6';

/// Full list of stored vehicle profiles.

abstract class _$VehicleProfileList extends $Notifier<List<VehicleProfile>> {
  List<VehicleProfile> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<VehicleProfile>, List<VehicleProfile>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<VehicleProfile>, List<VehicleProfile>>,
              List<VehicleProfile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Currently active vehicle profile, or `null` when none is selected.

@ProviderFor(ActiveVehicleProfile)
final activeVehicleProfileProvider = ActiveVehicleProfileProvider._();

/// Currently active vehicle profile, or `null` when none is selected.
final class ActiveVehicleProfileProvider
    extends $NotifierProvider<ActiveVehicleProfile, VehicleProfile?> {
  /// Currently active vehicle profile, or `null` when none is selected.
  ActiveVehicleProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeVehicleProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeVehicleProfileHash();

  @$internal
  @override
  ActiveVehicleProfile create() => ActiveVehicleProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleProfile? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleProfile?>(value),
    );
  }
}

String _$activeVehicleProfileHash() =>
    r'57bb44897a1e45978f1b026d52cb70d641740354';

/// Currently active vehicle profile, or `null` when none is selected.

abstract class _$ActiveVehicleProfile extends $Notifier<VehicleProfile?> {
  VehicleProfile? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VehicleProfile?, VehicleProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VehicleProfile?, VehicleProfile?>,
              VehicleProfile?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
