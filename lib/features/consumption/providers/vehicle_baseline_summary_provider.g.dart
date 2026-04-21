// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_baseline_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sample count per [DrivingSituation] for a vehicle (#779).
///
/// Reads the stored Welford accumulator for the vehicle directly
/// from the Hive baseline box and returns the `n` field as the
/// sample count. Transient situations (`hardAccel`, `fuelCutCoast`)
/// are never persisted, so they're filtered out — the UI shouldn't
/// surface them as "learning".
///
/// Returns an empty map when the box is closed (widget tests without
/// Hive init) or when no baseline has been saved for the vehicle yet.

@ProviderFor(vehicleBaselineSummary)
final vehicleBaselineSummaryProvider = VehicleBaselineSummaryFamily._();

/// Sample count per [DrivingSituation] for a vehicle (#779).
///
/// Reads the stored Welford accumulator for the vehicle directly
/// from the Hive baseline box and returns the `n` field as the
/// sample count. Transient situations (`hardAccel`, `fuelCutCoast`)
/// are never persisted, so they're filtered out — the UI shouldn't
/// surface them as "learning".
///
/// Returns an empty map when the box is closed (widget tests without
/// Hive init) or when no baseline has been saved for the vehicle yet.

final class VehicleBaselineSummaryProvider
    extends
        $FunctionalProvider<
          Map<DrivingSituation, int>,
          Map<DrivingSituation, int>,
          Map<DrivingSituation, int>
        >
    with $Provider<Map<DrivingSituation, int>> {
  /// Sample count per [DrivingSituation] for a vehicle (#779).
  ///
  /// Reads the stored Welford accumulator for the vehicle directly
  /// from the Hive baseline box and returns the `n` field as the
  /// sample count. Transient situations (`hardAccel`, `fuelCutCoast`)
  /// are never persisted, so they're filtered out — the UI shouldn't
  /// surface them as "learning".
  ///
  /// Returns an empty map when the box is closed (widget tests without
  /// Hive init) or when no baseline has been saved for the vehicle yet.
  VehicleBaselineSummaryProvider._({
    required VehicleBaselineSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'vehicleBaselineSummaryProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleBaselineSummaryHash();

  @override
  String toString() {
    return r'vehicleBaselineSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<DrivingSituation, int>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<DrivingSituation, int> create(Ref ref) {
    final argument = this.argument as String;
    return vehicleBaselineSummary(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<DrivingSituation, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<DrivingSituation, int>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleBaselineSummaryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleBaselineSummaryHash() =>
    r'cb3b2b43b2b14ffe20fabbf51f841a1944324889';

/// Sample count per [DrivingSituation] for a vehicle (#779).
///
/// Reads the stored Welford accumulator for the vehicle directly
/// from the Hive baseline box and returns the `n` field as the
/// sample count. Transient situations (`hardAccel`, `fuelCutCoast`)
/// are never persisted, so they're filtered out — the UI shouldn't
/// surface them as "learning".
///
/// Returns an empty map when the box is closed (widget tests without
/// Hive init) or when no baseline has been saved for the vehicle yet.

final class VehicleBaselineSummaryFamily extends $Family
    with $FunctionalFamilyOverride<Map<DrivingSituation, int>, String> {
  VehicleBaselineSummaryFamily._()
    : super(
        retry: null,
        name: r'vehicleBaselineSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Sample count per [DrivingSituation] for a vehicle (#779).
  ///
  /// Reads the stored Welford accumulator for the vehicle directly
  /// from the Hive baseline box and returns the `n` field as the
  /// sample count. Transient situations (`hardAccel`, `fuelCutCoast`)
  /// are never persisted, so they're filtered out — the UI shouldn't
  /// surface them as "learning".
  ///
  /// Returns an empty map when the box is closed (widget tests without
  /// Hive init) or when no baseline has been saved for the vehicle yet.

  VehicleBaselineSummaryProvider call(String vehicleId) =>
      VehicleBaselineSummaryProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'vehicleBaselineSummaryProvider';
}

/// Wipe every baseline entry for [vehicleId] (#779). Invalidates the
/// summary provider so the UI rebuilds to the zero state.
///
/// `keepAlive: true` prevents Riverpod from disposing the provider
/// mid-await — without it, the `ref.invalidate` call at the tail of
/// this method lands on a torn-down element.

@ProviderFor(resetVehicleBaselines)
final resetVehicleBaselinesProvider = ResetVehicleBaselinesFamily._();

/// Wipe every baseline entry for [vehicleId] (#779). Invalidates the
/// summary provider so the UI rebuilds to the zero state.
///
/// `keepAlive: true` prevents Riverpod from disposing the provider
/// mid-await — without it, the `ref.invalidate` call at the tail of
/// this method lands on a torn-down element.

final class ResetVehicleBaselinesProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Wipe every baseline entry for [vehicleId] (#779). Invalidates the
  /// summary provider so the UI rebuilds to the zero state.
  ///
  /// `keepAlive: true` prevents Riverpod from disposing the provider
  /// mid-await — without it, the `ref.invalidate` call at the tail of
  /// this method lands on a torn-down element.
  ResetVehicleBaselinesProvider._({
    required ResetVehicleBaselinesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'resetVehicleBaselinesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resetVehicleBaselinesHash();

  @override
  String toString() {
    return r'resetVehicleBaselinesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return resetVehicleBaselines(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ResetVehicleBaselinesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resetVehicleBaselinesHash() =>
    r'2542239c22e9b3bfc7d11de932d5340856813c1e';

/// Wipe every baseline entry for [vehicleId] (#779). Invalidates the
/// summary provider so the UI rebuilds to the zero state.
///
/// `keepAlive: true` prevents Riverpod from disposing the provider
/// mid-await — without it, the `ref.invalidate` call at the tail of
/// this method lands on a torn-down element.

final class ResetVehicleBaselinesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  ResetVehicleBaselinesFamily._()
    : super(
        retry: null,
        name: r'resetVehicleBaselinesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Wipe every baseline entry for [vehicleId] (#779). Invalidates the
  /// summary provider so the UI rebuilds to the zero state.
  ///
  /// `keepAlive: true` prevents Riverpod from disposing the provider
  /// mid-await — without it, the `ref.invalidate` call at the tail of
  /// this method lands on a torn-down element.

  ResetVehicleBaselinesProvider call(String vehicleId) =>
      ResetVehicleBaselinesProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'resetVehicleBaselinesProvider';
}
