// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approach_simulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-app simulator that injects a synthetic [ApproachState] (#2163).
///
/// Exists so the maintainer can verify the PiP price-layout flip on a
/// desk, without driving to a station. The debug button on the
/// trip-recording screen drives this notifier; the real-data
/// [approachStateProvider] is unaffected.
///
/// Flow:
/// 1. `simulate(station)` → emits [ApproachInRadius] for `duration`.
/// 2. After `duration` → emits [ApproachLeaving] for
///    [ApproachDetector.exitGrace] (matches the real detector).
/// 3. After grace → clears (`null`).
///
/// `clear()` aborts at any phase and returns to `null` immediately.

@ProviderFor(ApproachSimulator)
final approachSimulatorProvider = ApproachSimulatorProvider._();

/// In-app simulator that injects a synthetic [ApproachState] (#2163).
///
/// Exists so the maintainer can verify the PiP price-layout flip on a
/// desk, without driving to a station. The debug button on the
/// trip-recording screen drives this notifier; the real-data
/// [approachStateProvider] is unaffected.
///
/// Flow:
/// 1. `simulate(station)` → emits [ApproachInRadius] for `duration`.
/// 2. After `duration` → emits [ApproachLeaving] for
///    [ApproachDetector.exitGrace] (matches the real detector).
/// 3. After grace → clears (`null`).
///
/// `clear()` aborts at any phase and returns to `null` immediately.
final class ApproachSimulatorProvider
    extends $NotifierProvider<ApproachSimulator, ApproachState?> {
  /// In-app simulator that injects a synthetic [ApproachState] (#2163).
  ///
  /// Exists so the maintainer can verify the PiP price-layout flip on a
  /// desk, without driving to a station. The debug button on the
  /// trip-recording screen drives this notifier; the real-data
  /// [approachStateProvider] is unaffected.
  ///
  /// Flow:
  /// 1. `simulate(station)` → emits [ApproachInRadius] for `duration`.
  /// 2. After `duration` → emits [ApproachLeaving] for
  ///    [ApproachDetector.exitGrace] (matches the real detector).
  /// 3. After grace → clears (`null`).
  ///
  /// `clear()` aborts at any phase and returns to `null` immediately.
  ApproachSimulatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approachSimulatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approachSimulatorHash();

  @$internal
  @override
  ApproachSimulator create() => ApproachSimulator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApproachState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApproachState?>(value),
    );
  }
}

String _$approachSimulatorHash() => r'5be2df269df90d443ec4bd4dc86958cd3cc385c4';

/// In-app simulator that injects a synthetic [ApproachState] (#2163).
///
/// Exists so the maintainer can verify the PiP price-layout flip on a
/// desk, without driving to a station. The debug button on the
/// trip-recording screen drives this notifier; the real-data
/// [approachStateProvider] is unaffected.
///
/// Flow:
/// 1. `simulate(station)` → emits [ApproachInRadius] for `duration`.
/// 2. After `duration` → emits [ApproachLeaving] for
///    [ApproachDetector.exitGrace] (matches the real detector).
/// 3. After grace → clears (`null`).
///
/// `clear()` aborts at any phase and returns to `null` immediately.

abstract class _$ApproachSimulator extends $Notifier<ApproachState?> {
  ApproachState? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ApproachState?, ApproachState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ApproachState?, ApproachState?>,
              ApproachState?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
