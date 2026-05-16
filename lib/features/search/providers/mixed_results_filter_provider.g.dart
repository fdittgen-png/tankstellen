// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixed_results_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active [ResultKind] filter. Defaults to [ResultKind.both] — the
/// whole point of the unified list is the mixed feed.

@ProviderFor(ResultKindFilter)
final resultKindFilterProvider = ResultKindFilterProvider._();

/// The active [ResultKind] filter. Defaults to [ResultKind.both] — the
/// whole point of the unified list is the mixed feed.
final class ResultKindFilterProvider
    extends $NotifierProvider<ResultKindFilter, ResultKind> {
  /// The active [ResultKind] filter. Defaults to [ResultKind.both] — the
  /// whole point of the unified list is the mixed feed.
  ResultKindFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resultKindFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resultKindFilterHash();

  @$internal
  @override
  ResultKindFilter create() => ResultKindFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResultKind value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResultKind>(value),
    );
  }
}

String _$resultKindFilterHash() => r'0ee1c87fa68005f702c896916a440f777639a016';

/// The active [ResultKind] filter. Defaults to [ResultKind.both] — the
/// whole point of the unified list is the mixed feed.

abstract class _$ResultKindFilter extends $Notifier<ResultKind> {
  ResultKind build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ResultKind, ResultKind>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ResultKind, ResultKind>,
              ResultKind,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Selected EV connector-type filter. An empty set is a no-op (all
/// connector types pass). Applied only to EV rows by
/// `filteredSortedSearchResults`; fuel rows are never routed through it.

@ProviderFor(EvConnectorFilter)
final evConnectorFilterProvider = EvConnectorFilterProvider._();

/// Selected EV connector-type filter. An empty set is a no-op (all
/// connector types pass). Applied only to EV rows by
/// `filteredSortedSearchResults`; fuel rows are never routed through it.
final class EvConnectorFilterProvider
    extends $NotifierProvider<EvConnectorFilter, Set<ConnectorType>> {
  /// Selected EV connector-type filter. An empty set is a no-op (all
  /// connector types pass). Applied only to EV rows by
  /// `filteredSortedSearchResults`; fuel rows are never routed through it.
  EvConnectorFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evConnectorFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evConnectorFilterHash();

  @$internal
  @override
  EvConnectorFilter create() => EvConnectorFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<ConnectorType> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<ConnectorType>>(value),
    );
  }
}

String _$evConnectorFilterHash() => r'ae1d3a30f2dcfd3435203fae7928210f49d400a6';

/// Selected EV connector-type filter. An empty set is a no-op (all
/// connector types pass). Applied only to EV rows by
/// `filteredSortedSearchResults`; fuel rows are never routed through it.

abstract class _$EvConnectorFilter extends $Notifier<Set<ConnectorType>> {
  Set<ConnectorType> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<ConnectorType>, Set<ConnectorType>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<ConnectorType>, Set<ConnectorType>>,
              Set<ConnectorType>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Minimum charging power (kW) filter. `0` means no minimum. Applied
/// only to EV rows.

@ProviderFor(EvMinPowerFilter)
final evMinPowerFilterProvider = EvMinPowerFilterProvider._();

/// Minimum charging power (kW) filter. `0` means no minimum. Applied
/// only to EV rows.
final class EvMinPowerFilterProvider
    extends $NotifierProvider<EvMinPowerFilter, double> {
  /// Minimum charging power (kW) filter. `0` means no minimum. Applied
  /// only to EV rows.
  EvMinPowerFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evMinPowerFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evMinPowerFilterHash();

  @$internal
  @override
  EvMinPowerFilter create() => EvMinPowerFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$evMinPowerFilterHash() => r'7f106b7e9e577a1caa5232c9f086fe4a9e71a503';

/// Minimum charging power (kW) filter. `0` means no minimum. Applied
/// only to EV rows.

abstract class _$EvMinPowerFilter extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
