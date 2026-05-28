// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_ve_recompute_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #1858 — retroactive η_v recompute trigger.
///
/// A keep-alive listener that watches [vehicleProfileListProvider] and,
/// whenever a vehicle's effective η_v changes via a manual profile
/// save, rescales that vehicle's η_v-recalculable trips in the
/// trip-history box (see [recomputeTripForVe]).
///
/// Scoped to **manual** edits by construction: the VeLearner writes
/// the vehicle-profile *repository* directly, not the
/// [VehicleProfileList] notifier, so its converging per-fill-up
/// micro-adjustments never reach this provider — only a deliberate
/// edit through the notifier does, which is the intended trigger.
///
/// Instantiated once at startup (`app_initializer`) so the listener is
/// live for the whole session; it holds no state of its own.

@ProviderFor(TripVeRecomputeListener)
final tripVeRecomputeListenerProvider = TripVeRecomputeListenerProvider._();

/// #1858 — retroactive η_v recompute trigger.
///
/// A keep-alive listener that watches [vehicleProfileListProvider] and,
/// whenever a vehicle's effective η_v changes via a manual profile
/// save, rescales that vehicle's η_v-recalculable trips in the
/// trip-history box (see [recomputeTripForVe]).
///
/// Scoped to **manual** edits by construction: the VeLearner writes
/// the vehicle-profile *repository* directly, not the
/// [VehicleProfileList] notifier, so its converging per-fill-up
/// micro-adjustments never reach this provider — only a deliberate
/// edit through the notifier does, which is the intended trigger.
///
/// Instantiated once at startup (`app_initializer`) so the listener is
/// live for the whole session; it holds no state of its own.
final class TripVeRecomputeListenerProvider
    extends $NotifierProvider<TripVeRecomputeListener, void> {
  /// #1858 — retroactive η_v recompute trigger.
  ///
  /// A keep-alive listener that watches [vehicleProfileListProvider] and,
  /// whenever a vehicle's effective η_v changes via a manual profile
  /// save, rescales that vehicle's η_v-recalculable trips in the
  /// trip-history box (see [recomputeTripForVe]).
  ///
  /// Scoped to **manual** edits by construction: the VeLearner writes
  /// the vehicle-profile *repository* directly, not the
  /// [VehicleProfileList] notifier, so its converging per-fill-up
  /// micro-adjustments never reach this provider — only a deliberate
  /// edit through the notifier does, which is the intended trigger.
  ///
  /// Instantiated once at startup (`app_initializer`) so the listener is
  /// live for the whole session; it holds no state of its own.
  TripVeRecomputeListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripVeRecomputeListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripVeRecomputeListenerHash();

  @$internal
  @override
  TripVeRecomputeListener create() => TripVeRecomputeListener();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$tripVeRecomputeListenerHash() =>
    r'339ed9907aa5c03fd872d3b0693246418dfc4be0';

/// #1858 — retroactive η_v recompute trigger.
///
/// A keep-alive listener that watches [vehicleProfileListProvider] and,
/// whenever a vehicle's effective η_v changes via a manual profile
/// save, rescales that vehicle's η_v-recalculable trips in the
/// trip-history box (see [recomputeTripForVe]).
///
/// Scoped to **manual** edits by construction: the VeLearner writes
/// the vehicle-profile *repository* directly, not the
/// [VehicleProfileList] notifier, so its converging per-fill-up
/// micro-adjustments never reach this provider — only a deliberate
/// edit through the notifier does, which is the intended trigger.
///
/// Instantiated once at startup (`app_initializer`) so the listener is
/// live for the whole session; it holds no state of its own.

abstract class _$TripVeRecomputeListener extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
