// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'speed_consumption_bins_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The speed-vs-consumption histogram of the carbon Charts tab, over the
/// trips [vehicleId] may claim (every trip when null; a trip with no
/// vehicle counts for every vehicle).
///
/// Every stored sample of every such trip is decoded, so the decode AND
/// the fold run on ONE worker isolate — the tab used to decode them all
/// on the UI isolate inside its `build`. Recomputes when the list changes.

@ProviderFor(speedConsumptionBins)
final speedConsumptionBinsProvider = SpeedConsumptionBinsFamily._();

/// The speed-vs-consumption histogram of the carbon Charts tab, over the
/// trips [vehicleId] may claim (every trip when null; a trip with no
/// vehicle counts for every vehicle).
///
/// Every stored sample of every such trip is decoded, so the decode AND
/// the fold run on ONE worker isolate — the tab used to decode them all
/// on the UI isolate inside its `build`. Recomputes when the list changes.

final class SpeedConsumptionBinsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SpeedConsumptionBin>>,
          List<SpeedConsumptionBin>,
          FutureOr<List<SpeedConsumptionBin>>
        >
    with
        $FutureModifier<List<SpeedConsumptionBin>>,
        $FutureProvider<List<SpeedConsumptionBin>> {
  /// The speed-vs-consumption histogram of the carbon Charts tab, over the
  /// trips [vehicleId] may claim (every trip when null; a trip with no
  /// vehicle counts for every vehicle).
  ///
  /// Every stored sample of every such trip is decoded, so the decode AND
  /// the fold run on ONE worker isolate — the tab used to decode them all
  /// on the UI isolate inside its `build`. Recomputes when the list changes.
  SpeedConsumptionBinsProvider._({
    required SpeedConsumptionBinsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'speedConsumptionBinsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$speedConsumptionBinsHash();

  @override
  String toString() {
    return r'speedConsumptionBinsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SpeedConsumptionBin>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SpeedConsumptionBin>> create(Ref ref) {
    final argument = this.argument as String?;
    return speedConsumptionBins(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SpeedConsumptionBinsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$speedConsumptionBinsHash() =>
    r'fb525dd285b7f09cf7ce0d7acfc3bd02fe185007';

/// The speed-vs-consumption histogram of the carbon Charts tab, over the
/// trips [vehicleId] may claim (every trip when null; a trip with no
/// vehicle counts for every vehicle).
///
/// Every stored sample of every such trip is decoded, so the decode AND
/// the fold run on ONE worker isolate — the tab used to decode them all
/// on the UI isolate inside its `build`. Recomputes when the list changes.

final class SpeedConsumptionBinsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SpeedConsumptionBin>>,
          String?
        > {
  SpeedConsumptionBinsFamily._()
    : super(
        retry: null,
        name: r'speedConsumptionBinsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The speed-vs-consumption histogram of the carbon Charts tab, over the
  /// trips [vehicleId] may claim (every trip when null; a trip with no
  /// vehicle counts for every vehicle).
  ///
  /// Every stored sample of every such trip is decoded, so the decode AND
  /// the fold run on ONE worker isolate — the tab used to decode them all
  /// on the UI isolate inside its `build`. Recomputes when the list changes.

  SpeedConsumptionBinsProvider call(String? vehicleId) =>
      SpeedConsumptionBinsProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'speedConsumptionBinsProvider';
}
