// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'cross_border_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injectable factory for resolving the neighbor country's station service.
///
/// Production path delegates to `stationServiceForCountry`, which goes
/// through `CountryServiceRegistry` + `StationServiceChain` so the call
/// is fully cached and request-coalesced (see #1118 acceptance: "coalesce
/// duplicate API calls — already supported by chain").
///
/// Tests override this with a closure returning a small in-memory fake.
///
/// #4381 — `keepAlive`: the returned closure captures this `Ref` and is
/// called once per neighbour inside [crossBorderSuggestion]'s probe loop,
/// i.e. across awaits. As an auto-dispose provider its element was gone by
/// the second neighbour, and `Cannot use the Ref ... after it has been
/// disposed` was swallowed by `_safeNeighborSearch` into an empty result —
/// the banner just silently stopped appearing. The resolver only reaches
/// keepAlive providers ([perCountryStationServiceProvider]), so
/// container-lifetime is its correct scope.

@ProviderFor(crossBorderStationServiceFactory)
final crossBorderStationServiceFactoryProvider =
    CrossBorderStationServiceFactoryProvider._();

/// Injectable factory for resolving the neighbor country's station service.
///
/// Production path delegates to `stationServiceForCountry`, which goes
/// through `CountryServiceRegistry` + `StationServiceChain` so the call
/// is fully cached and request-coalesced (see #1118 acceptance: "coalesce
/// duplicate API calls — already supported by chain").
///
/// Tests override this with a closure returning a small in-memory fake.
///
/// #4381 — `keepAlive`: the returned closure captures this `Ref` and is
/// called once per neighbour inside [crossBorderSuggestion]'s probe loop,
/// i.e. across awaits. As an auto-dispose provider its element was gone by
/// the second neighbour, and `Cannot use the Ref ... after it has been
/// disposed` was swallowed by `_safeNeighborSearch` into an empty result —
/// the banner just silently stopped appearing. The resolver only reaches
/// keepAlive providers ([perCountryStationServiceProvider]), so
/// container-lifetime is its correct scope.

final class CrossBorderStationServiceFactoryProvider
    extends
        $FunctionalProvider<
          CrossBorderStationServiceFactory,
          CrossBorderStationServiceFactory,
          CrossBorderStationServiceFactory
        >
    with $Provider<CrossBorderStationServiceFactory> {
  /// Injectable factory for resolving the neighbor country's station service.
  ///
  /// Production path delegates to `stationServiceForCountry`, which goes
  /// through `CountryServiceRegistry` + `StationServiceChain` so the call
  /// is fully cached and request-coalesced (see #1118 acceptance: "coalesce
  /// duplicate API calls — already supported by chain").
  ///
  /// Tests override this with a closure returning a small in-memory fake.
  ///
  /// #4381 — `keepAlive`: the returned closure captures this `Ref` and is
  /// called once per neighbour inside [crossBorderSuggestion]'s probe loop,
  /// i.e. across awaits. As an auto-dispose provider its element was gone by
  /// the second neighbour, and `Cannot use the Ref ... after it has been
  /// disposed` was swallowed by `_safeNeighborSearch` into an empty result —
  /// the banner just silently stopped appearing. The resolver only reaches
  /// keepAlive providers ([perCountryStationServiceProvider]), so
  /// container-lifetime is its correct scope.
  CrossBorderStationServiceFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossBorderStationServiceFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossBorderStationServiceFactoryHash();

  @$internal
  @override
  $ProviderElement<CrossBorderStationServiceFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CrossBorderStationServiceFactory create(Ref ref) {
    return crossBorderStationServiceFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrossBorderStationServiceFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrossBorderStationServiceFactory>(
        value,
      ),
    );
  }
}

String _$crossBorderStationServiceFactoryHash() =>
    r'7977e3b17b582bc31e956fd30ce10043e83a8a5f';

/// Async suggestion of "the neighbor country has cheaper fuel right now".
///
/// Returns `null` when:
///  * the user's position is unknown,
///  * the user is not within [crossBorderThresholdKm] of any neighbor,
///  * the active fuel type is not supported by the neighbor (we don't
///    propose an EV-only neighbor for a diesel user, and vice versa),
///  * the neighbor's station service returns no usable prices,
///  * the current-country average is empty (we'd have nothing to compare
///    against),
///  * the neighbor is not actually cheaper (delta <= 0).
///
/// When non-null, the result encodes a positive `priceDeltaPerLiter` —
/// callers (the banner) can render it directly without re-checking the
/// sign.

@ProviderFor(crossBorderSuggestion)
final crossBorderSuggestionProvider = CrossBorderSuggestionProvider._();

/// Async suggestion of "the neighbor country has cheaper fuel right now".
///
/// Returns `null` when:
///  * the user's position is unknown,
///  * the user is not within [crossBorderThresholdKm] of any neighbor,
///  * the active fuel type is not supported by the neighbor (we don't
///    propose an EV-only neighbor for a diesel user, and vice versa),
///  * the neighbor's station service returns no usable prices,
///  * the current-country average is empty (we'd have nothing to compare
///    against),
///  * the neighbor is not actually cheaper (delta <= 0).
///
/// When non-null, the result encodes a positive `priceDeltaPerLiter` —
/// callers (the banner) can render it directly without re-checking the
/// sign.

final class CrossBorderSuggestionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CrossBorderSuggestion?>,
          CrossBorderSuggestion?,
          FutureOr<CrossBorderSuggestion?>
        >
    with
        $FutureModifier<CrossBorderSuggestion?>,
        $FutureProvider<CrossBorderSuggestion?> {
  /// Async suggestion of "the neighbor country has cheaper fuel right now".
  ///
  /// Returns `null` when:
  ///  * the user's position is unknown,
  ///  * the user is not within [crossBorderThresholdKm] of any neighbor,
  ///  * the active fuel type is not supported by the neighbor (we don't
  ///    propose an EV-only neighbor for a diesel user, and vice versa),
  ///  * the neighbor's station service returns no usable prices,
  ///  * the current-country average is empty (we'd have nothing to compare
  ///    against),
  ///  * the neighbor is not actually cheaper (delta <= 0).
  ///
  /// When non-null, the result encodes a positive `priceDeltaPerLiter` —
  /// callers (the banner) can render it directly without re-checking the
  /// sign.
  CrossBorderSuggestionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossBorderSuggestionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossBorderSuggestionHash();

  @$internal
  @override
  $FutureProviderElement<CrossBorderSuggestion?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CrossBorderSuggestion?> create(Ref ref) {
    return crossBorderSuggestion(ref);
  }
}

String _$crossBorderSuggestionHash() =>
    r'94789eb3147da0736e6490d83daf77a739721e1d';

/// Set of neighbor country codes the user has dismissed during this
/// session. Resets on app restart (StateNotifier with no persistence).

@ProviderFor(CrossBorderBannerDismissed)
final crossBorderBannerDismissedProvider =
    CrossBorderBannerDismissedProvider._();

/// Set of neighbor country codes the user has dismissed during this
/// session. Resets on app restart (StateNotifier with no persistence).
final class CrossBorderBannerDismissedProvider
    extends $NotifierProvider<CrossBorderBannerDismissed, Set<String>> {
  /// Set of neighbor country codes the user has dismissed during this
  /// session. Resets on app restart (StateNotifier with no persistence).
  CrossBorderBannerDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossBorderBannerDismissedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossBorderBannerDismissedHash();

  @$internal
  @override
  CrossBorderBannerDismissed create() => CrossBorderBannerDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$crossBorderBannerDismissedHash() =>
    r'b3371d52fb8171f3e1ba222721b84c921a2a7683';

/// Set of neighbor country codes the user has dismissed during this
/// session. Resets on app restart (StateNotifier with no persistence).

abstract class _$CrossBorderBannerDismissed extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
