// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'tank_mix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fuel mix of the current tank content for [vehicleId] (#3652), read from
/// the one mix model the app has: the evidence-only tank blend (#4322).
///
/// It is [tankBlendProvider] reduced to the [TankMixView] the Fuel & Tank
/// surface renders, so a mix line anywhere else (the tank level card) can
/// never disagree with that surface — guaranteed minimums, the unknown
/// share said out loud. The grades this vehicle was filled with or is
/// approved for bound [TankMixView.plausibleMaxEthanolShare], the upper
/// ethanol bound the trip lessons excuse lean trims with (#3701).
///
/// Null when the vehicle is unknown or not flagged multi-fuel capable
/// (#2885) — a single-fuel vehicle's tank is trivially 100 % of its grade
/// and surfacing that would be noise.

@ProviderFor(tankMix)
final tankMixProvider = TankMixFamily._();

/// Fuel mix of the current tank content for [vehicleId] (#3652), read from
/// the one mix model the app has: the evidence-only tank blend (#4322).
///
/// It is [tankBlendProvider] reduced to the [TankMixView] the Fuel & Tank
/// surface renders, so a mix line anywhere else (the tank level card) can
/// never disagree with that surface — guaranteed minimums, the unknown
/// share said out loud. The grades this vehicle was filled with or is
/// approved for bound [TankMixView.plausibleMaxEthanolShare], the upper
/// ethanol bound the trip lessons excuse lean trims with (#3701).
///
/// Null when the vehicle is unknown or not flagged multi-fuel capable
/// (#2885) — a single-fuel vehicle's tank is trivially 100 % of its grade
/// and surfacing that would be noise.

final class TankMixProvider
    extends $FunctionalProvider<TankMixView?, TankMixView?, TankMixView?>
    with $Provider<TankMixView?> {
  /// Fuel mix of the current tank content for [vehicleId] (#3652), read from
  /// the one mix model the app has: the evidence-only tank blend (#4322).
  ///
  /// It is [tankBlendProvider] reduced to the [TankMixView] the Fuel & Tank
  /// surface renders, so a mix line anywhere else (the tank level card) can
  /// never disagree with that surface — guaranteed minimums, the unknown
  /// share said out loud. The grades this vehicle was filled with or is
  /// approved for bound [TankMixView.plausibleMaxEthanolShare], the upper
  /// ethanol bound the trip lessons excuse lean trims with (#3701).
  ///
  /// Null when the vehicle is unknown or not flagged multi-fuel capable
  /// (#2885) — a single-fuel vehicle's tank is trivially 100 % of its grade
  /// and surfacing that would be noise.
  TankMixProvider._({
    required TankMixFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tankMixProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tankMixHash();

  @override
  String toString() {
    return r'tankMixProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TankMixView?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TankMixView? create(Ref ref) {
    final argument = this.argument as String;
    return tankMix(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TankMixView? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TankMixView?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TankMixProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tankMixHash() => r'bc4247bddbde8b2fc2ddbbc95aa00551558b0807';

/// Fuel mix of the current tank content for [vehicleId] (#3652), read from
/// the one mix model the app has: the evidence-only tank blend (#4322).
///
/// It is [tankBlendProvider] reduced to the [TankMixView] the Fuel & Tank
/// surface renders, so a mix line anywhere else (the tank level card) can
/// never disagree with that surface — guaranteed minimums, the unknown
/// share said out loud. The grades this vehicle was filled with or is
/// approved for bound [TankMixView.plausibleMaxEthanolShare], the upper
/// ethanol bound the trip lessons excuse lean trims with (#3701).
///
/// Null when the vehicle is unknown or not flagged multi-fuel capable
/// (#2885) — a single-fuel vehicle's tank is trivially 100 % of its grade
/// and surfacing that would be noise.

final class TankMixFamily extends $Family
    with $FunctionalFamilyOverride<TankMixView?, String> {
  TankMixFamily._()
    : super(
        retry: null,
        name: r'tankMixProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fuel mix of the current tank content for [vehicleId] (#3652), read from
  /// the one mix model the app has: the evidence-only tank blend (#4322).
  ///
  /// It is [tankBlendProvider] reduced to the [TankMixView] the Fuel & Tank
  /// surface renders, so a mix line anywhere else (the tank level card) can
  /// never disagree with that surface — guaranteed minimums, the unknown
  /// share said out loud. The grades this vehicle was filled with or is
  /// approved for bound [TankMixView.plausibleMaxEthanolShare], the upper
  /// ethanol bound the trip lessons excuse lean trims with (#3701).
  ///
  /// Null when the vehicle is unknown or not flagged multi-fuel capable
  /// (#2885) — a single-fuel vehicle's tank is trivially 100 % of its grade
  /// and surfacing that would be noise.

  TankMixProvider call(String vehicleId) =>
      TankMixProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'tankMixProvider';
}
