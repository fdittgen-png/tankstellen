// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'tank_blend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The versioned, evidence-only tank blend of [vehicleId] (#4279).
///
/// Recomputed from the fill-up list and the trip history whenever either
/// changes — never persisted, so there is no derived state to go stale,
/// migrate, or double-apply after a restart. A vehicle with no history
/// yields a fully unknown blend (confidence 0), never an empty tank.
///
/// Read [TankBlendSnapshot.confidence] / [TankBlendSnapshot.exactShare] to
/// tell an established blend from a partly unknown one: this is the
/// "estimated, not measured" signal a summary must surface (#4278).

@ProviderFor(tankBlend)
final tankBlendProvider = TankBlendFamily._();

/// The versioned, evidence-only tank blend of [vehicleId] (#4279).
///
/// Recomputed from the fill-up list and the trip history whenever either
/// changes — never persisted, so there is no derived state to go stale,
/// migrate, or double-apply after a restart. A vehicle with no history
/// yields a fully unknown blend (confidence 0), never an empty tank.
///
/// Read [TankBlendSnapshot.confidence] / [TankBlendSnapshot.exactShare] to
/// tell an established blend from a partly unknown one: this is the
/// "estimated, not measured" signal a summary must surface (#4278).

final class TankBlendProvider
    extends
        $FunctionalProvider<
          TankBlendSnapshot,
          TankBlendSnapshot,
          TankBlendSnapshot
        >
    with $Provider<TankBlendSnapshot> {
  /// The versioned, evidence-only tank blend of [vehicleId] (#4279).
  ///
  /// Recomputed from the fill-up list and the trip history whenever either
  /// changes — never persisted, so there is no derived state to go stale,
  /// migrate, or double-apply after a restart. A vehicle with no history
  /// yields a fully unknown blend (confidence 0), never an empty tank.
  ///
  /// Read [TankBlendSnapshot.confidence] / [TankBlendSnapshot.exactShare] to
  /// tell an established blend from a partly unknown one: this is the
  /// "estimated, not measured" signal a summary must surface (#4278).
  TankBlendProvider._({
    required TankBlendFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tankBlendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tankBlendHash();

  @override
  String toString() {
    return r'tankBlendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TankBlendSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TankBlendSnapshot create(Ref ref) {
    final argument = this.argument as String;
    return tankBlend(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TankBlendSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TankBlendSnapshot>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TankBlendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tankBlendHash() => r'18233f67f543af9aa6c6473918a0cfea11dcf159';

/// The versioned, evidence-only tank blend of [vehicleId] (#4279).
///
/// Recomputed from the fill-up list and the trip history whenever either
/// changes — never persisted, so there is no derived state to go stale,
/// migrate, or double-apply after a restart. A vehicle with no history
/// yields a fully unknown blend (confidence 0), never an empty tank.
///
/// Read [TankBlendSnapshot.confidence] / [TankBlendSnapshot.exactShare] to
/// tell an established blend from a partly unknown one: this is the
/// "estimated, not measured" signal a summary must surface (#4278).

final class TankBlendFamily extends $Family
    with $FunctionalFamilyOverride<TankBlendSnapshot, String> {
  TankBlendFamily._()
    : super(
        retry: null,
        name: r'tankBlendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The versioned, evidence-only tank blend of [vehicleId] (#4279).
  ///
  /// Recomputed from the fill-up list and the trip history whenever either
  /// changes — never persisted, so there is no derived state to go stale,
  /// migrate, or double-apply after a restart. A vehicle with no history
  /// yields a fully unknown blend (confidence 0), never an empty tank.
  ///
  /// Read [TankBlendSnapshot.confidence] / [TankBlendSnapshot.exactShare] to
  /// tell an established blend from a partly unknown one: this is the
  /// "estimated, not measured" signal a summary must surface (#4278).

  TankBlendProvider call(String vehicleId) =>
      TankBlendProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'tankBlendProvider';
}
