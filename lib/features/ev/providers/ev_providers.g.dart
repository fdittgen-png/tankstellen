// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ev_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for reading/writing cached [ChargingStation] entries.

@ProviderFor(evStationRepository)
final evStationRepositoryProvider = EvStationRepositoryProvider._();

/// Repository for reading/writing cached [ChargingStation] entries.

final class EvStationRepositoryProvider
    extends
        $FunctionalProvider<
          EvStationRepository,
          EvStationRepository,
          EvStationRepository
        >
    with $Provider<EvStationRepository> {
  /// Repository for reading/writing cached [ChargingStation] entries.
  EvStationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evStationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evStationRepositoryHash();

  @$internal
  @override
  $ProviderElement<EvStationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EvStationRepository create(Ref ref) {
    return evStationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvStationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvStationRepository>(value),
    );
  }
}

String _$evStationRepositoryHash() =>
    r'd52b16691f4b66e428cb48969c05797bd4d88f03';

/// Concrete [EvStationService] used by the app.
///
/// Plain `@riverpod` (not keepAlive) so a future settings change can swap
/// in a real API key without a restart.

@ProviderFor(evStationService)
final evStationServiceProvider = EvStationServiceProvider._();

/// Concrete [EvStationService] used by the app.
///
/// Plain `@riverpod` (not keepAlive) so a future settings change can swap
/// in a real API key without a restart.

final class EvStationServiceProvider
    extends
        $FunctionalProvider<
          EvStationService,
          EvStationService,
          EvStationService
        >
    with $Provider<EvStationService> {
  /// Concrete [EvStationService] used by the app.
  ///
  /// Plain `@riverpod` (not keepAlive) so a future settings change can swap
  /// in a real API key without a restart.
  EvStationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evStationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evStationServiceHash();

  @$internal
  @override
  $ProviderElement<EvStationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EvStationService create(Ref ref) {
    return evStationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvStationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvStationService>(value),
    );
  }
}

String _$evStationServiceHash() => r'1d977c9206aebfb49e6f452730f35e05f49b83b6';

/// Whether EV charging stations should be overlaid on the map.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` — existing fuel-station users shouldn't
/// suddenly see extra markers on upgrade.

@ProviderFor(EvShowOnMap)
final evShowOnMapProvider = EvShowOnMapProvider._();

/// Whether EV charging stations should be overlaid on the map.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` — existing fuel-station users shouldn't
/// suddenly see extra markers on upgrade.
final class EvShowOnMapProvider extends $NotifierProvider<EvShowOnMap, bool> {
  /// Whether EV charging stations should be overlaid on the map.
  ///
  /// Persisted to the settings box so the user's preference survives
  /// restarts. Defaults to `false` — existing fuel-station users shouldn't
  /// suddenly see extra markers on upgrade.
  EvShowOnMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evShowOnMapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evShowOnMapHash();

  @$internal
  @override
  EvShowOnMap create() => EvShowOnMap();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$evShowOnMapHash() => r'4d7004b1a48703495c01b69847b7c13339f3947e';

/// Whether EV charging stations should be overlaid on the map.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` — existing fuel-station users shouldn't
/// suddenly see extra markers on upgrade.

abstract class _$EvShowOnMap extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// User-editable filter for EV stations.
///
/// Seeded from the active vehicle profile's `supportedConnectors` so a
/// driver with a CCS-only car doesn't see incompatible plugs by default.

@ProviderFor(EvFilterController)
final evFilterControllerProvider = EvFilterControllerProvider._();

/// User-editable filter for EV stations.
///
/// Seeded from the active vehicle profile's `supportedConnectors` so a
/// driver with a CCS-only car doesn't see incompatible plugs by default.
final class EvFilterControllerProvider
    extends $NotifierProvider<EvFilterController, EvFilter> {
  /// User-editable filter for EV stations.
  ///
  /// Seeded from the active vehicle profile's `supportedConnectors` so a
  /// driver with a CCS-only car doesn't see incompatible plugs by default.
  EvFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evFilterControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evFilterControllerHash();

  @$internal
  @override
  EvFilterController create() => EvFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvFilter>(value),
    );
  }
}

String _$evFilterControllerHash() =>
    r'bdb0e5cd2c758eb6104e44ace63b1a2ef9a7bb05';

/// User-editable filter for EV stations.
///
/// Seeded from the active vehicle profile's `supportedConnectors` so a
/// driver with a CCS-only car doesn't see incompatible plugs by default.

abstract class _$EvFilterController extends $Notifier<EvFilter> {
  EvFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EvFilter, EvFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EvFilter, EvFilter>,
              EvFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetches charging stations for the given [viewport] and writes them
/// through the local repository cache. Applies the current
/// [evFilterControllerProvider] before returning.

@ProviderFor(evStations)
final evStationsProvider = EvStationsFamily._();

/// Fetches charging stations for the given [viewport] and writes them
/// through the local repository cache. Applies the current
/// [evFilterControllerProvider] before returning.

final class EvStationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChargingStation>>,
          List<ChargingStation>,
          FutureOr<List<ChargingStation>>
        >
    with
        $FutureModifier<List<ChargingStation>>,
        $FutureProvider<List<ChargingStation>> {
  /// Fetches charging stations for the given [viewport] and writes them
  /// through the local repository cache. Applies the current
  /// [evFilterControllerProvider] before returning.
  EvStationsProvider._({
    required EvStationsFamily super.from,
    required EvViewport super.argument,
  }) : super(
         retry: null,
         name: r'evStationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$evStationsHash();

  @override
  String toString() {
    return r'evStationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ChargingStation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChargingStation>> create(Ref ref) {
    final argument = this.argument as EvViewport;
    return evStations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EvStationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$evStationsHash() => r'0afe64b089a8c1e725069db89d3b1deb0137ae0e';

/// Fetches charging stations for the given [viewport] and writes them
/// through the local repository cache. Applies the current
/// [evFilterControllerProvider] before returning.

final class EvStationsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<ChargingStation>>, EvViewport> {
  EvStationsFamily._()
    : super(
        retry: null,
        name: r'evStationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches charging stations for the given [viewport] and writes them
  /// through the local repository cache. Applies the current
  /// [evFilterControllerProvider] before returning.

  EvStationsProvider call(EvViewport viewport) =>
      EvStationsProvider._(argument: viewport, from: this);

  @override
  String toString() => r'evStationsProvider';
}
