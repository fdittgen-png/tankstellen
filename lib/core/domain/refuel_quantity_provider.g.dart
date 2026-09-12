// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'refuel_quantity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The quantity the user says they usually buy, when they have said so
/// (#4095).
///
/// `null` — the default, and the state most users will stay in — means
/// "work it out". `realRefuelProfileProvider` then uses the MEDIAN of
/// their own fill volumes, which is already personal from the first few
/// fills and needs no question asked. This provider exists for the case
/// the measurement cannot cover: a driver who knows they always put in
/// 20 litres, or one with no fill-up history yet who would rather say
/// than wait.
///
/// It is declared in core, beside `refuelProfileProvider`, for the same
/// reason: the results screen reads it and `features/fill_ups` writes
/// the profile that consumes it, and neither may import the other.
///
/// ## Why this is not tank capacity
///
/// Capacity is a CEILING on this number, never the number itself, and
/// never a prerequisite (`docs/specs/refuel-economics.md` §2: tank
/// capacity is not in the formula). The "full tank" choice in the UI
/// resolves to the active vehicle's capacity where one is configured and
/// is simply absent where it is not — the app must never require a
/// capacity to work.

@ProviderFor(RefuelQuantity)
final refuelQuantityProvider = RefuelQuantityProvider._();

/// The quantity the user says they usually buy, when they have said so
/// (#4095).
///
/// `null` — the default, and the state most users will stay in — means
/// "work it out". `realRefuelProfileProvider` then uses the MEDIAN of
/// their own fill volumes, which is already personal from the first few
/// fills and needs no question asked. This provider exists for the case
/// the measurement cannot cover: a driver who knows they always put in
/// 20 litres, or one with no fill-up history yet who would rather say
/// than wait.
///
/// It is declared in core, beside `refuelProfileProvider`, for the same
/// reason: the results screen reads it and `features/fill_ups` writes
/// the profile that consumes it, and neither may import the other.
///
/// ## Why this is not tank capacity
///
/// Capacity is a CEILING on this number, never the number itself, and
/// never a prerequisite (`docs/specs/refuel-economics.md` §2: tank
/// capacity is not in the formula). The "full tank" choice in the UI
/// resolves to the active vehicle's capacity where one is configured and
/// is simply absent where it is not — the app must never require a
/// capacity to work.
final class RefuelQuantityProvider
    extends $NotifierProvider<RefuelQuantity, double?> {
  /// The quantity the user says they usually buy, when they have said so
  /// (#4095).
  ///
  /// `null` — the default, and the state most users will stay in — means
  /// "work it out". `realRefuelProfileProvider` then uses the MEDIAN of
  /// their own fill volumes, which is already personal from the first few
  /// fills and needs no question asked. This provider exists for the case
  /// the measurement cannot cover: a driver who knows they always put in
  /// 20 litres, or one with no fill-up history yet who would rather say
  /// than wait.
  ///
  /// It is declared in core, beside `refuelProfileProvider`, for the same
  /// reason: the results screen reads it and `features/fill_ups` writes
  /// the profile that consumes it, and neither may import the other.
  ///
  /// ## Why this is not tank capacity
  ///
  /// Capacity is a CEILING on this number, never the number itself, and
  /// never a prerequisite (`docs/specs/refuel-economics.md` §2: tank
  /// capacity is not in the formula). The "full tank" choice in the UI
  /// resolves to the active vehicle's capacity where one is configured and
  /// is simply absent where it is not — the app must never require a
  /// capacity to work.
  RefuelQuantityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refuelQuantityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refuelQuantityHash();

  @$internal
  @override
  RefuelQuantity create() => RefuelQuantity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }
}

String _$refuelQuantityHash() => r'49fb691ede03a936f16fa3b2cf8f7d2d044187f3';

/// The quantity the user says they usually buy, when they have said so
/// (#4095).
///
/// `null` — the default, and the state most users will stay in — means
/// "work it out". `realRefuelProfileProvider` then uses the MEDIAN of
/// their own fill volumes, which is already personal from the first few
/// fills and needs no question asked. This provider exists for the case
/// the measurement cannot cover: a driver who knows they always put in
/// 20 litres, or one with no fill-up history yet who would rather say
/// than wait.
///
/// It is declared in core, beside `refuelProfileProvider`, for the same
/// reason: the results screen reads it and `features/fill_ups` writes
/// the profile that consumes it, and neither may import the other.
///
/// ## Why this is not tank capacity
///
/// Capacity is a CEILING on this number, never the number itself, and
/// never a prerequisite (`docs/specs/refuel-economics.md` §2: tank
/// capacity is not in the formula). The "full tank" choice in the UI
/// resolves to the active vehicle's capacity where one is configured and
/// is simply absent where it is not — the app must never require a
/// capacity to work.

abstract class _$RefuelQuantity extends $Notifier<double?> {
  double? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double?, double?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double?, double?>,
              double?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
