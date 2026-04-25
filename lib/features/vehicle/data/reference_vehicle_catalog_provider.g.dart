// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_vehicle_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the bundled reference vehicle catalog (#950 phase 1).
///
/// `keepAlive: true` because the catalog is static for the lifetime of
/// the app — re-decoding the JSON on every read would be wasteful.
/// Phase 2 (obd2_service) and phase 4 (VehicleProfile migration) both
/// read this provider; the cached `List<ReferenceVehicle>` is shared.

@ProviderFor(referenceVehicleCatalog)
final referenceVehicleCatalogProvider = ReferenceVehicleCatalogProvider._();

/// Loads the bundled reference vehicle catalog (#950 phase 1).
///
/// `keepAlive: true` because the catalog is static for the lifetime of
/// the app — re-decoding the JSON on every read would be wasteful.
/// Phase 2 (obd2_service) and phase 4 (VehicleProfile migration) both
/// read this provider; the cached `List<ReferenceVehicle>` is shared.

final class ReferenceVehicleCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReferenceVehicle>>,
          List<ReferenceVehicle>,
          FutureOr<List<ReferenceVehicle>>
        >
    with
        $FutureModifier<List<ReferenceVehicle>>,
        $FutureProvider<List<ReferenceVehicle>> {
  /// Loads the bundled reference vehicle catalog (#950 phase 1).
  ///
  /// `keepAlive: true` because the catalog is static for the lifetime of
  /// the app — re-decoding the JSON on every read would be wasteful.
  /// Phase 2 (obd2_service) and phase 4 (VehicleProfile migration) both
  /// read this provider; the cached `List<ReferenceVehicle>` is shared.
  ReferenceVehicleCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'referenceVehicleCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$referenceVehicleCatalogHash();

  @$internal
  @override
  $FutureProviderElement<List<ReferenceVehicle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReferenceVehicle>> create(Ref ref) {
    return referenceVehicleCatalog(ref);
  }
}

String _$referenceVehicleCatalogHash() =>
    r'63a58d8821fa273613204b24d52bebbb5e0b7f6b';

/// Returns the best catalog match for [make], [model], and [year], or
/// `null` if no entry covers the trio (#950 phase 1).
///
/// Lookup is case-insensitive on make + model, and inclusive on the
/// production-year window. While the catalog is loading, this returns
/// `null` (the AsyncValue is unresolved) — callers should re-watch the
/// underlying [referenceVehicleCatalogProvider] if they need to wait.

@ProviderFor(referenceVehicleByMakeModel)
final referenceVehicleByMakeModelProvider =
    ReferenceVehicleByMakeModelFamily._();

/// Returns the best catalog match for [make], [model], and [year], or
/// `null` if no entry covers the trio (#950 phase 1).
///
/// Lookup is case-insensitive on make + model, and inclusive on the
/// production-year window. While the catalog is loading, this returns
/// `null` (the AsyncValue is unresolved) — callers should re-watch the
/// underlying [referenceVehicleCatalogProvider] if they need to wait.

final class ReferenceVehicleByMakeModelProvider
    extends
        $FunctionalProvider<
          ReferenceVehicle?,
          ReferenceVehicle?,
          ReferenceVehicle?
        >
    with $Provider<ReferenceVehicle?> {
  /// Returns the best catalog match for [make], [model], and [year], or
  /// `null` if no entry covers the trio (#950 phase 1).
  ///
  /// Lookup is case-insensitive on make + model, and inclusive on the
  /// production-year window. While the catalog is loading, this returns
  /// `null` (the AsyncValue is unresolved) — callers should re-watch the
  /// underlying [referenceVehicleCatalogProvider] if they need to wait.
  ReferenceVehicleByMakeModelProvider._({
    required ReferenceVehicleByMakeModelFamily super.from,
    required ({String make, String model, int year}) super.argument,
  }) : super(
         retry: null,
         name: r'referenceVehicleByMakeModelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$referenceVehicleByMakeModelHash();

  @override
  String toString() {
    return r'referenceVehicleByMakeModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ReferenceVehicle?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReferenceVehicle? create(Ref ref) {
    final argument = this.argument as ({String make, String model, int year});
    return referenceVehicleByMakeModel(
      ref,
      make: argument.make,
      model: argument.model,
      year: argument.year,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReferenceVehicle? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReferenceVehicle?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReferenceVehicleByMakeModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$referenceVehicleByMakeModelHash() =>
    r'2c75c00a69ad7b06018564b820a81312818503cb';

/// Returns the best catalog match for [make], [model], and [year], or
/// `null` if no entry covers the trio (#950 phase 1).
///
/// Lookup is case-insensitive on make + model, and inclusive on the
/// production-year window. While the catalog is loading, this returns
/// `null` (the AsyncValue is unresolved) — callers should re-watch the
/// underlying [referenceVehicleCatalogProvider] if they need to wait.

final class ReferenceVehicleByMakeModelFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ReferenceVehicle?,
          ({String make, String model, int year})
        > {
  ReferenceVehicleByMakeModelFamily._()
    : super(
        retry: null,
        name: r'referenceVehicleByMakeModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Returns the best catalog match for [make], [model], and [year], or
  /// `null` if no entry covers the trio (#950 phase 1).
  ///
  /// Lookup is case-insensitive on make + model, and inclusive on the
  /// production-year window. While the catalog is loading, this returns
  /// `null` (the AsyncValue is unresolved) — callers should re-watch the
  /// underlying [referenceVehicleCatalogProvider] if they need to wait.

  ReferenceVehicleByMakeModelProvider call({
    required String make,
    required String model,
    required int year,
  }) => ReferenceVehicleByMakeModelProvider._(
    argument: (make: make, model: model, year: year),
    from: this,
  );

  @override
  String toString() => r'referenceVehicleByMakeModelProvider';
}
