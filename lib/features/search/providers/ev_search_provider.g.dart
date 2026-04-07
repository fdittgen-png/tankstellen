// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ev_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages EV charging station search, parallel to [SearchState] for fuel.

@ProviderFor(EVSearchState)
final eVSearchStateProvider = EVSearchStateProvider._();

/// Manages EV charging station search, parallel to [SearchState] for fuel.
final class EVSearchStateProvider
    extends
        $NotifierProvider<
          EVSearchState,
          AsyncValue<ServiceResult<List<ChargingStation>>>
        > {
  /// Manages EV charging station search, parallel to [SearchState] for fuel.
  EVSearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eVSearchStateProvider',
        isAutoDispose: true,
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

String _$eVSearchStateHash() => r'e9bdc4fe2b271863aaa7e258337af59b538588e6';

/// Manages EV charging station search, parallel to [SearchState] for fuel.

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
