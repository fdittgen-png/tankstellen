// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ev_charging_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes an [EVChargingService] instance bound to the user's
/// OpenChargeMap API key (#728 part 2).
///
/// Previously each caller — `EVSearchState`, `RouteSearchProvider`,
/// `EVStationDetailScreen._refreshStation` — constructed its own
/// service inline, each time resolving the key from Hive and creating
/// a fresh Dio. That meant a hot UI path (build / setState) touched
/// secure storage and spun up a new HTTP client on every call, with
/// no request coalescing across the three call sites.
///
/// This provider:
/// * reads the EV API key from [apiKeyStorageProvider];
/// * returns `null` when no key is set (callers surface the
///   "configure your key" empty-state instead of throwing);
/// * uses `keepAlive` so the service survives screen rebuilds and
///   any cache / coalescing the service adds in the future applies
///   across the whole app.

@ProviderFor(evChargingService)
final evChargingServiceProvider = EvChargingServiceProvider._();

/// Exposes an [EVChargingService] instance bound to the user's
/// OpenChargeMap API key (#728 part 2).
///
/// Previously each caller — `EVSearchState`, `RouteSearchProvider`,
/// `EVStationDetailScreen._refreshStation` — constructed its own
/// service inline, each time resolving the key from Hive and creating
/// a fresh Dio. That meant a hot UI path (build / setState) touched
/// secure storage and spun up a new HTTP client on every call, with
/// no request coalescing across the three call sites.
///
/// This provider:
/// * reads the EV API key from [apiKeyStorageProvider];
/// * returns `null` when no key is set (callers surface the
///   "configure your key" empty-state instead of throwing);
/// * uses `keepAlive` so the service survives screen rebuilds and
///   any cache / coalescing the service adds in the future applies
///   across the whole app.

final class EvChargingServiceProvider
    extends
        $FunctionalProvider<
          EVChargingService?,
          EVChargingService?,
          EVChargingService?
        >
    with $Provider<EVChargingService?> {
  /// Exposes an [EVChargingService] instance bound to the user's
  /// OpenChargeMap API key (#728 part 2).
  ///
  /// Previously each caller — `EVSearchState`, `RouteSearchProvider`,
  /// `EVStationDetailScreen._refreshStation` — constructed its own
  /// service inline, each time resolving the key from Hive and creating
  /// a fresh Dio. That meant a hot UI path (build / setState) touched
  /// secure storage and spun up a new HTTP client on every call, with
  /// no request coalescing across the three call sites.
  ///
  /// This provider:
  /// * reads the EV API key from [apiKeyStorageProvider];
  /// * returns `null` when no key is set (callers surface the
  ///   "configure your key" empty-state instead of throwing);
  /// * uses `keepAlive` so the service survives screen rebuilds and
  ///   any cache / coalescing the service adds in the future applies
  ///   across the whole app.
  EvChargingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'evChargingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$evChargingServiceHash();

  @$internal
  @override
  $ProviderElement<EVChargingService?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EVChargingService? create(Ref ref) {
    return evChargingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EVChargingService? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EVChargingService?>(value),
    );
  }
}

String _$evChargingServiceHash() => r'0e2375042bf9c47db0e5f60c0cb9d7e1bb37816b';
