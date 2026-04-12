// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station_type_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls whether the search screen shows fuel or EV results.

@ProviderFor(ActiveStationTypeFilter)
final activeStationTypeFilterProvider = ActiveStationTypeFilterProvider._();

/// Controls whether the search screen shows fuel or EV results.
final class ActiveStationTypeFilterProvider
    extends $NotifierProvider<ActiveStationTypeFilter, StationTypeFilter> {
  /// Controls whether the search screen shows fuel or EV results.
  ActiveStationTypeFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeStationTypeFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeStationTypeFilterHash();

  @$internal
  @override
  ActiveStationTypeFilter create() => ActiveStationTypeFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StationTypeFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StationTypeFilter>(value),
    );
  }
}

String _$activeStationTypeFilterHash() =>
    r'3f9b2162b46ab16bf7defa0cbe01cfa89483632e';

/// Controls whether the search screen shows fuel or EV results.

abstract class _$ActiveStationTypeFilter extends $Notifier<StationTypeFilter> {
  StationTypeFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StationTypeFilter, StationTypeFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StationTypeFilter, StationTypeFilter>,
              StationTypeFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
