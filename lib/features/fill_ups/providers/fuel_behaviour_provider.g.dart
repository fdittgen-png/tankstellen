// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fuel_behaviour_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How [vehicleId] behaves per fuel context (#4276), learned from its
/// canonical consumption evidence and full-to-full fill windows.
///
/// Recomputed from the fill-up list and trip history whenever either
/// changes, and never persisted — the UI (#4278) and the next-fill
/// decision (#4277) read this one result instead of re-analysing.
/// Every figure is a `BehaviourMetric`: a value with its interval, or
/// insufficient with the reason. See `deriveFuelBehaviourProfile` for what
/// the live history can and cannot supply today.

@ProviderFor(fuelBehaviourProfile)
final fuelBehaviourProfileProvider = FuelBehaviourProfileFamily._();

/// How [vehicleId] behaves per fuel context (#4276), learned from its
/// canonical consumption evidence and full-to-full fill windows.
///
/// Recomputed from the fill-up list and trip history whenever either
/// changes, and never persisted — the UI (#4278) and the next-fill
/// decision (#4277) read this one result instead of re-analysing.
/// Every figure is a `BehaviourMetric`: a value with its interval, or
/// insufficient with the reason. See `deriveFuelBehaviourProfile` for what
/// the live history can and cannot supply today.

final class FuelBehaviourProfileProvider
    extends
        $FunctionalProvider<
          FuelBehaviourProfile,
          FuelBehaviourProfile,
          FuelBehaviourProfile
        >
    with $Provider<FuelBehaviourProfile> {
  /// How [vehicleId] behaves per fuel context (#4276), learned from its
  /// canonical consumption evidence and full-to-full fill windows.
  ///
  /// Recomputed from the fill-up list and trip history whenever either
  /// changes, and never persisted — the UI (#4278) and the next-fill
  /// decision (#4277) read this one result instead of re-analysing.
  /// Every figure is a `BehaviourMetric`: a value with its interval, or
  /// insufficient with the reason. See `deriveFuelBehaviourProfile` for what
  /// the live history can and cannot supply today.
  FuelBehaviourProfileProvider._({
    required FuelBehaviourProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fuelBehaviourProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fuelBehaviourProfileHash();

  @override
  String toString() {
    return r'fuelBehaviourProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FuelBehaviourProfile> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FuelBehaviourProfile create(Ref ref) {
    final argument = this.argument as String;
    return fuelBehaviourProfile(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuelBehaviourProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuelBehaviourProfile>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FuelBehaviourProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fuelBehaviourProfileHash() =>
    r'210599765d13505b7839f0230b79a0419dc946b7';

/// How [vehicleId] behaves per fuel context (#4276), learned from its
/// canonical consumption evidence and full-to-full fill windows.
///
/// Recomputed from the fill-up list and trip history whenever either
/// changes, and never persisted — the UI (#4278) and the next-fill
/// decision (#4277) read this one result instead of re-analysing.
/// Every figure is a `BehaviourMetric`: a value with its interval, or
/// insufficient with the reason. See `deriveFuelBehaviourProfile` for what
/// the live history can and cannot supply today.

final class FuelBehaviourProfileFamily extends $Family
    with $FunctionalFamilyOverride<FuelBehaviourProfile, String> {
  FuelBehaviourProfileFamily._()
    : super(
        retry: null,
        name: r'fuelBehaviourProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How [vehicleId] behaves per fuel context (#4276), learned from its
  /// canonical consumption evidence and full-to-full fill windows.
  ///
  /// Recomputed from the fill-up list and trip history whenever either
  /// changes, and never persisted — the UI (#4278) and the next-fill
  /// decision (#4277) read this one result instead of re-analysing.
  /// Every figure is a `BehaviourMetric`: a value with its interval, or
  /// insufficient with the reason. See `deriveFuelBehaviourProfile` for what
  /// the live history can and cannot supply today.

  FuelBehaviourProfileProvider call(String vehicleId) =>
      FuelBehaviourProfileProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'fuelBehaviourProfileProvider';
}
