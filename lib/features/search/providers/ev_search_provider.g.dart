// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ev_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The EV price/access enricher applied after the OCM search returns
/// (#2618). Defaults to the France IRVE enricher, which is itself a
/// no-op for any result set with no FR stations — so non-FR searches
/// make zero extra network calls. Overridable in tests.

@ProviderFor(evPriceEnricher)
final evPriceEnricherProvider = EvPriceEnricherProvider._();

/// The EV price/access enricher applied after the OCM search returns
/// (#2618). Defaults to the France IRVE enricher, which is itself a
/// no-op for any result set with no FR stations — so non-FR searches
/// make zero extra network calls. Overridable in tests.

final class EvPriceEnricherProvider
    extends
        $FunctionalProvider<EvPriceEnricher, EvPriceEnricher, EvPriceEnricher>
    with $Provider<EvPriceEnricher> {
  /// The EV price/access enricher applied after the OCM search returns
  /// (#2618). Defaults to the France IRVE enricher, which is itself a
  /// no-op for any result set with no FR stations — so non-FR searches
  /// make zero extra network calls. Overridable in tests.
  EvPriceEnricherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evPriceEnricherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evPriceEnricherHash();

  @$internal
  @override
  $ProviderElement<EvPriceEnricher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EvPriceEnricher create(Ref ref) {
    return evPriceEnricher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvPriceEnricher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvPriceEnricher>(value),
    );
  }
}

String _$evPriceEnricherHash() => r'2da95b963489e3094a783a14f1eb40f6ebed396d';

/// Manages EV charging station search, parallel to [SearchState] for fuel.
///
/// Uses `keepAlive` because SearchState dispatches to this notifier
/// asynchronously — without keepAlive, the auto-dispose fires mid-request
/// when nothing is watching, causing UnmountedRefException (#550).

@ProviderFor(EVSearchState)
final eVSearchStateProvider = EVSearchStateProvider._();

/// Manages EV charging station search, parallel to [SearchState] for fuel.
///
/// Uses `keepAlive` because SearchState dispatches to this notifier
/// asynchronously — without keepAlive, the auto-dispose fires mid-request
/// when nothing is watching, causing UnmountedRefException (#550).
final class EVSearchStateProvider
    extends
        $NotifierProvider<
          EVSearchState,
          AsyncValue<ServiceResult<List<ChargingStation>>>
        > {
  /// Manages EV charging station search, parallel to [SearchState] for fuel.
  ///
  /// Uses `keepAlive` because SearchState dispatches to this notifier
  /// asynchronously — without keepAlive, the auto-dispose fires mid-request
  /// when nothing is watching, causing UnmountedRefException (#550).
  EVSearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eVSearchStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eVSearchStateHash();

  @$internal
  @override
  EVSearchState create() => EVSearchState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<ServiceResult<List<ChargingStation>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<ServiceResult<List<ChargingStation>>>>(
            value,
          ),
    );
  }
}

String _$eVSearchStateHash() => r'cf50b050b303acd2ba9709c6a384721f6818b583';

/// Manages EV charging station search, parallel to [SearchState] for fuel.
///
/// Uses `keepAlive` because SearchState dispatches to this notifier
/// asynchronously — without keepAlive, the auto-dispose fires mid-request
/// when nothing is watching, causing UnmountedRefException (#550).

abstract class _$EVSearchState
    extends $Notifier<AsyncValue<ServiceResult<List<ChargingStation>>>> {
  AsyncValue<ServiceResult<List<ChargingStation>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ServiceResult<List<ChargingStation>>>,
              AsyncValue<ServiceResult<List<ChargingStation>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ServiceResult<List<ChargingStation>>>,
                AsyncValue<ServiceResult<List<ChargingStation>>>
              >,
              AsyncValue<ServiceResult<List<ChargingStation>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
