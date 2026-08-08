// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'motorway_exits_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one [MotorwayExitsService] (#3633). keepAlive — it owns the
/// per-country in-memory datasets and their freshness clocks.

@ProviderFor(motorwayExitsService)
final motorwayExitsServiceProvider = MotorwayExitsServiceProvider._();

/// The one [MotorwayExitsService] (#3633). keepAlive — it owns the
/// per-country in-memory datasets and their freshness clocks.

final class MotorwayExitsServiceProvider
    extends
        $FunctionalProvider<
          MotorwayExitsService,
          MotorwayExitsService,
          MotorwayExitsService
        >
    with $Provider<MotorwayExitsService> {
  /// The one [MotorwayExitsService] (#3633). keepAlive — it owns the
  /// per-country in-memory datasets and their freshness clocks.
  MotorwayExitsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'motorwayExitsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$motorwayExitsServiceHash();

  @$internal
  @override
  $ProviderElement<MotorwayExitsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MotorwayExitsService create(Ref ref) {
    return motorwayExitsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MotorwayExitsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MotorwayExitsService>(value),
    );
  }
}

String _$motorwayExitsServiceHash() =>
    r'8b26b65dc6201b6e77764c49d25fbd5f3a517f4c';

/// The active-country motorway exits currently in memory (#3633).
///
/// Synchronous by design: the radar ranking runs synchronously per GPS
/// poll, so it reads whatever is loaded NOW. [ensureLoaded] kicks the
/// async fetch/rehydrate (called by the radar when highway mode is
/// active); until it lands the state is empty and highway mode behaves
/// exactly like exit-less v1.

@ProviderFor(MotorwayExits)
final motorwayExitsProvider = MotorwayExitsProvider._();

/// The active-country motorway exits currently in memory (#3633).
///
/// Synchronous by design: the radar ranking runs synchronously per GPS
/// poll, so it reads whatever is loaded NOW. [ensureLoaded] kicks the
/// async fetch/rehydrate (called by the radar when highway mode is
/// active); until it lands the state is empty and highway mode behaves
/// exactly like exit-less v1.
final class MotorwayExitsProvider
    extends $NotifierProvider<MotorwayExits, List<MotorwayExit>> {
  /// The active-country motorway exits currently in memory (#3633).
  ///
  /// Synchronous by design: the radar ranking runs synchronously per GPS
  /// poll, so it reads whatever is loaded NOW. [ensureLoaded] kicks the
  /// async fetch/rehydrate (called by the radar when highway mode is
  /// active); until it lands the state is empty and highway mode behaves
  /// exactly like exit-less v1.
  MotorwayExitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'motorwayExitsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$motorwayExitsHash();

  @$internal
  @override
  MotorwayExits create() => MotorwayExits();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MotorwayExit> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MotorwayExit>>(value),
    );
  }
}

String _$motorwayExitsHash() => r'4cd4988dcaee0bbc21effc0ea5edbe42f4d49541';

/// The active-country motorway exits currently in memory (#3633).
///
/// Synchronous by design: the radar ranking runs synchronously per GPS
/// poll, so it reads whatever is loaded NOW. [ensureLoaded] kicks the
/// async fetch/rehydrate (called by the radar when highway mode is
/// active); until it lands the state is empty and highway mode behaves
/// exactly like exit-less v1.

abstract class _$MotorwayExits extends $Notifier<List<MotorwayExit>> {
  List<MotorwayExit> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<MotorwayExit>, List<MotorwayExit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<MotorwayExit>, List<MotorwayExit>>,
              List<MotorwayExit>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Per-station exit annotations for the CURRENT radar list (#3633),
/// written by the radar search provider after each ranked poll and
/// consumed by the station card ("via exit {ref} · +{km} km") — the
/// same map-shaped side-channel pattern as `roadDistancesProvider`
/// (#3634), so the card wiring stays identical.

@ProviderFor(HighwayExitInfoMap)
final highwayExitInfoMapProvider = HighwayExitInfoMapProvider._();

/// Per-station exit annotations for the CURRENT radar list (#3633),
/// written by the radar search provider after each ranked poll and
/// consumed by the station card ("via exit {ref} · +{km} km") — the
/// same map-shaped side-channel pattern as `roadDistancesProvider`
/// (#3634), so the card wiring stays identical.
final class HighwayExitInfoMapProvider
    extends
        $NotifierProvider<HighwayExitInfoMap, Map<String, HighwayExitInfo>> {
  /// Per-station exit annotations for the CURRENT radar list (#3633),
  /// written by the radar search provider after each ranked poll and
  /// consumed by the station card ("via exit {ref} · +{km} km") — the
  /// same map-shaped side-channel pattern as `roadDistancesProvider`
  /// (#3634), so the card wiring stays identical.
  HighwayExitInfoMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'highwayExitInfoMapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$highwayExitInfoMapHash();

  @$internal
  @override
  HighwayExitInfoMap create() => HighwayExitInfoMap();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, HighwayExitInfo> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, HighwayExitInfo>>(value),
    );
  }
}

String _$highwayExitInfoMapHash() =>
    r'2d7d7329a06b049ced636fd4d9defc41d9696733';

/// Per-station exit annotations for the CURRENT radar list (#3633),
/// written by the radar search provider after each ranked poll and
/// consumed by the station card ("via exit {ref} · +{km} km") — the
/// same map-shaped side-channel pattern as `roadDistancesProvider`
/// (#3634), so the card wiring stays identical.

abstract class _$HighwayExitInfoMap
    extends $Notifier<Map<String, HighwayExitInfo>> {
  Map<String, HighwayExitInfo> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, HighwayExitInfo>, Map<String, HighwayExitInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, HighwayExitInfo>,
                Map<String, HighwayExitInfo>
              >,
              Map<String, HighwayExitInfo>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
