// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tank_level_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current tank-level estimate for [vehicleId] (#1195).
///
/// Composes the vehicle profile, the fill-up list filtered to that
/// vehicle, and the trip history filtered to trips recorded since the
/// most recent fill-up. The pure [estimateTankLevel] function does the
/// math; this provider just wires inputs together and stays per-screen
/// (no `keepAlive`).
///
/// Returns [TankLevelEstimate.unknown] when:
/// * [vehicleId] does not match any stored vehicle profile
/// * the vehicle has no fill-ups logged yet

@ProviderFor(tankLevel)
final tankLevelProvider = TankLevelFamily._();

/// Current tank-level estimate for [vehicleId] (#1195).
///
/// Composes the vehicle profile, the fill-up list filtered to that
/// vehicle, and the trip history filtered to trips recorded since the
/// most recent fill-up. The pure [estimateTankLevel] function does the
/// math; this provider just wires inputs together and stays per-screen
/// (no `keepAlive`).
///
/// Returns [TankLevelEstimate.unknown] when:
/// * [vehicleId] does not match any stored vehicle profile
/// * the vehicle has no fill-ups logged yet

final class TankLevelProvider
    extends
        $FunctionalProvider<
          TankLevelEstimate,
          TankLevelEstimate,
          TankLevelEstimate
        >
    with $Provider<TankLevelEstimate> {
  /// Current tank-level estimate for [vehicleId] (#1195).
  ///
  /// Composes the vehicle profile, the fill-up list filtered to that
  /// vehicle, and the trip history filtered to trips recorded since the
  /// most recent fill-up. The pure [estimateTankLevel] function does the
  /// math; this provider just wires inputs together and stays per-screen
  /// (no `keepAlive`).
  ///
  /// Returns [TankLevelEstimate.unknown] when:
  /// * [vehicleId] does not match any stored vehicle profile
  /// * the vehicle has no fill-ups logged yet
  TankLevelProvider._({
    required TankLevelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tankLevelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tankLevelHash();

  @override
  String toString() {
    return r'tankLevelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TankLevelEstimate> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TankLevelEstimate create(Ref ref) {
    final argument = this.argument as String;
    return tankLevel(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TankLevelEstimate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TankLevelEstimate>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TankLevelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tankLevelHash() => r'baa693c62ec9c5252dafab00acab04293a788d06';

/// Current tank-level estimate for [vehicleId] (#1195).
///
/// Composes the vehicle profile, the fill-up list filtered to that
/// vehicle, and the trip history filtered to trips recorded since the
/// most recent fill-up. The pure [estimateTankLevel] function does the
/// math; this provider just wires inputs together and stays per-screen
/// (no `keepAlive`).
///
/// Returns [TankLevelEstimate.unknown] when:
/// * [vehicleId] does not match any stored vehicle profile
/// * the vehicle has no fill-ups logged yet

final class TankLevelFamily extends $Family
    with $FunctionalFamilyOverride<TankLevelEstimate, String> {
  TankLevelFamily._()
    : super(
        retry: null,
        name: r'tankLevelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Current tank-level estimate for [vehicleId] (#1195).
  ///
  /// Composes the vehicle profile, the fill-up list filtered to that
  /// vehicle, and the trip history filtered to trips recorded since the
  /// most recent fill-up. The pure [estimateTankLevel] function does the
  /// math; this provider just wires inputs together and stays per-screen
  /// (no `keepAlive`).
  ///
  /// Returns [TankLevelEstimate.unknown] when:
  /// * [vehicleId] does not match any stored vehicle profile
  /// * the vehicle has no fill-ups logged yet

  TankLevelProvider call(String vehicleId) =>
      TankLevelProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'tankLevelProvider';
}
