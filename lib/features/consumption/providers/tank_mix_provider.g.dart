// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tank_mix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fuel mix of the current tank content for [vehicleId] (#3652).
///
/// Null when the vehicle is unknown, has no physical fills, or is not
/// flagged multi-fuel capable (#2885) — a single-fuel vehicle's tank is
/// trivially 100 % of its grade and surfacing that would be noise.

@ProviderFor(tankMix)
final tankMixProvider = TankMixFamily._();

/// Fuel mix of the current tank content for [vehicleId] (#3652).
///
/// Null when the vehicle is unknown, has no physical fills, or is not
/// flagged multi-fuel capable (#2885) — a single-fuel vehicle's tank is
/// trivially 100 % of its grade and surfacing that would be noise.

final class TankMixProvider
    extends
        $FunctionalProvider<
          TankMixEstimate?,
          TankMixEstimate?,
          TankMixEstimate?
        >
    with $Provider<TankMixEstimate?> {
  /// Fuel mix of the current tank content for [vehicleId] (#3652).
  ///
  /// Null when the vehicle is unknown, has no physical fills, or is not
  /// flagged multi-fuel capable (#2885) — a single-fuel vehicle's tank is
  /// trivially 100 % of its grade and surfacing that would be noise.
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
  $ProviderElement<TankMixEstimate?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TankMixEstimate? create(Ref ref) {
    final argument = this.argument as String;
    return tankMix(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TankMixEstimate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TankMixEstimate?>(value),
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

String _$tankMixHash() => r'41debfda129284296b5cba7e1faa08ba8cec571d';

/// Fuel mix of the current tank content for [vehicleId] (#3652).
///
/// Null when the vehicle is unknown, has no physical fills, or is not
/// flagged multi-fuel capable (#2885) — a single-fuel vehicle's tank is
/// trivially 100 % of its grade and surfacing that would be noise.

final class TankMixFamily extends $Family
    with $FunctionalFamilyOverride<TankMixEstimate?, String> {
  TankMixFamily._()
    : super(
        retry: null,
        name: r'tankMixProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fuel mix of the current tank content for [vehicleId] (#3652).
  ///
  /// Null when the vehicle is unknown, has no physical fills, or is not
  /// flagged multi-fuel capable (#2885) — a single-fuel vehicle's tank is
  /// trivially 100 % of its grade and surfacing that would be noise.

  TankMixProvider call(String vehicleId) =>
      TankMixProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'tankMixProvider';
}
