// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'vehicle_comparison_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The compared vehicles and the report period. Independent of the
/// active vehicle in both directions.

@ProviderFor(VehicleComparisonSelector)
final vehicleComparisonSelectorProvider = VehicleComparisonSelectorProvider._();

/// The compared vehicles and the report period. Independent of the
/// active vehicle in both directions.
final class VehicleComparisonSelectorProvider
    extends
        $NotifierProvider<
          VehicleComparisonSelector,
          VehicleComparisonSelection
        > {
  /// The compared vehicles and the report period. Independent of the
  /// active vehicle in both directions.
  VehicleComparisonSelectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleComparisonSelectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleComparisonSelectorHash();

  @$internal
  @override
  VehicleComparisonSelector create() => VehicleComparisonSelector();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleComparisonSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleComparisonSelection>(value),
    );
  }
}

String _$vehicleComparisonSelectorHash() =>
    r'145879ca5d329757c7621b352c96ac5d43f05bfe';

/// The compared vehicles and the report period. Independent of the
/// active vehicle in both directions.

abstract class _$VehicleComparisonSelector
    extends $Notifier<VehicleComparisonSelection> {
  VehicleComparisonSelection build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<VehicleComparisonSelection, VehicleComparisonSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                VehicleComparisonSelection,
                VehicleComparisonSelection
              >,
              VehicleComparisonSelection,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The comparison for one explicit [key] — the reusable result #4366
/// and #4367 read.
///
/// Keyed by the selected ids, the period and the evidence version, so
/// two surfaces asking the same question share one computation and a
/// different question gets a different answer rather than a stale one.

@ProviderFor(vehicleHistoryComparison)
final vehicleHistoryComparisonProvider = VehicleHistoryComparisonFamily._();

/// The comparison for one explicit [key] — the reusable result #4366
/// and #4367 read.
///
/// Keyed by the selected ids, the period and the evidence version, so
/// two surfaces asking the same question share one computation and a
/// different question gets a different answer rather than a stale one.

final class VehicleHistoryComparisonProvider
    extends
        $FunctionalProvider<
          VehicleHistoryComparison,
          VehicleHistoryComparison,
          VehicleHistoryComparison
        >
    with $Provider<VehicleHistoryComparison> {
  /// The comparison for one explicit [key] — the reusable result #4366
  /// and #4367 read.
  ///
  /// Keyed by the selected ids, the period and the evidence version, so
  /// two surfaces asking the same question share one computation and a
  /// different question gets a different answer rather than a stale one.
  VehicleHistoryComparisonProvider._({
    required VehicleHistoryComparisonFamily super.from,
    required VehicleComparisonKey super.argument,
  }) : super(
         retry: null,
         name: r'vehicleHistoryComparisonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleHistoryComparisonHash();

  @override
  String toString() {
    return r'vehicleHistoryComparisonProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<VehicleHistoryComparison> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VehicleHistoryComparison create(Ref ref) {
    final argument = this.argument as VehicleComparisonKey;
    return vehicleHistoryComparison(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleHistoryComparison value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleHistoryComparison>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleHistoryComparisonProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleHistoryComparisonHash() =>
    r'8666133a5d8681002c12baf0697f27a04debcbdd';

/// The comparison for one explicit [key] — the reusable result #4366
/// and #4367 read.
///
/// Keyed by the selected ids, the period and the evidence version, so
/// two surfaces asking the same question share one computation and a
/// different question gets a different answer rather than a stale one.

final class VehicleHistoryComparisonFamily extends $Family
    with
        $FunctionalFamilyOverride<
          VehicleHistoryComparison,
          VehicleComparisonKey
        > {
  VehicleHistoryComparisonFamily._()
    : super(
        retry: null,
        name: r'vehicleHistoryComparisonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The comparison for one explicit [key] — the reusable result #4366
  /// and #4367 read.
  ///
  /// Keyed by the selected ids, the period and the evidence version, so
  /// two surfaces asking the same question share one computation and a
  /// different question gets a different answer rather than a stale one.

  VehicleHistoryComparisonProvider call(VehicleComparisonKey key) =>
      VehicleHistoryComparisonProvider._(argument: key, from: this);

  @override
  String toString() => r'vehicleHistoryComparisonProvider';
}

/// The comparison the personal surface is currently showing.

@ProviderFor(selectedVehicleComparison)
final selectedVehicleComparisonProvider = SelectedVehicleComparisonProvider._();

/// The comparison the personal surface is currently showing.

final class SelectedVehicleComparisonProvider
    extends
        $FunctionalProvider<
          VehicleHistoryComparison,
          VehicleHistoryComparison,
          VehicleHistoryComparison
        >
    with $Provider<VehicleHistoryComparison> {
  /// The comparison the personal surface is currently showing.
  SelectedVehicleComparisonProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedVehicleComparisonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedVehicleComparisonHash();

  @$internal
  @override
  $ProviderElement<VehicleHistoryComparison> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VehicleHistoryComparison create(Ref ref) {
    return selectedVehicleComparison(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleHistoryComparison value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleHistoryComparison>(value),
    );
  }
}

String _$selectedVehicleComparisonHash() =>
    r'33c4a8fcb9264f788e126120bd13219bf56468a7';
