// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radius_alerts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared [RadiusAlertStore] instance. Kept alive for the app's
/// lifetime so the async notifier below can re-read it without
/// re-instantiating a store per operation.

@ProviderFor(radiusAlertStore)
final radiusAlertStoreProvider = RadiusAlertStoreProvider._();

/// Shared [RadiusAlertStore] instance. Kept alive for the app's
/// lifetime so the async notifier below can re-read it without
/// re-instantiating a store per operation.

final class RadiusAlertStoreProvider
    extends
        $FunctionalProvider<
          RadiusAlertStore,
          RadiusAlertStore,
          RadiusAlertStore
        >
    with $Provider<RadiusAlertStore> {
  /// Shared [RadiusAlertStore] instance. Kept alive for the app's
  /// lifetime so the async notifier below can re-read it without
  /// re-instantiating a store per operation.
  RadiusAlertStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radiusAlertStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radiusAlertStoreHash();

  @$internal
  @override
  $ProviderElement<RadiusAlertStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RadiusAlertStore create(Ref ref) {
    return radiusAlertStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadiusAlertStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadiusAlertStore>(value),
    );
  }
}

String _$radiusAlertStoreHash() => r'379932ffed7a9f10c6a9a32f77e0195d9f167316';

/// Shared [RadiusAlertDedup] instance. Owns the per-(alert, station)
/// "last notified" state consumed by the BG runner (#578 phase 3).
/// Exposed here so the provider layer can purge dedup rows when a
/// radius alert is deleted — otherwise stale rows would leak in the
/// shared alerts box forever.

@ProviderFor(radiusAlertDedup)
final radiusAlertDedupProvider = RadiusAlertDedupProvider._();

/// Shared [RadiusAlertDedup] instance. Owns the per-(alert, station)
/// "last notified" state consumed by the BG runner (#578 phase 3).
/// Exposed here so the provider layer can purge dedup rows when a
/// radius alert is deleted — otherwise stale rows would leak in the
/// shared alerts box forever.

final class RadiusAlertDedupProvider
    extends
        $FunctionalProvider<
          RadiusAlertDedup,
          RadiusAlertDedup,
          RadiusAlertDedup
        >
    with $Provider<RadiusAlertDedup> {
  /// Shared [RadiusAlertDedup] instance. Owns the per-(alert, station)
  /// "last notified" state consumed by the BG runner (#578 phase 3).
  /// Exposed here so the provider layer can purge dedup rows when a
  /// radius alert is deleted — otherwise stale rows would leak in the
  /// shared alerts box forever.
  RadiusAlertDedupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radiusAlertDedupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radiusAlertDedupHash();

  @$internal
  @override
  $ProviderElement<RadiusAlertDedup> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RadiusAlertDedup create(Ref ref) {
    return radiusAlertDedup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadiusAlertDedup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadiusAlertDedup>(value),
    );
  }
}

String _$radiusAlertDedupHash() => r'4cbd5efc80bc437e286942ea63495d907ac35068';

/// Radius-watchlist state (#578 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] for the phase-2 UI layer. Mirrors the
/// per-station [AlertNotifier] shape so users of either can swap
/// between the two in follow-up PRs without relearning the surface.

@ProviderFor(RadiusAlerts)
final radiusAlertsProvider = RadiusAlertsProvider._();

/// Radius-watchlist state (#578 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] for the phase-2 UI layer. Mirrors the
/// per-station [AlertNotifier] shape so users of either can swap
/// between the two in follow-up PRs without relearning the surface.
final class RadiusAlertsProvider
    extends $AsyncNotifierProvider<RadiusAlerts, List<RadiusAlert>> {
  /// Radius-watchlist state (#578 phase 1).
  ///
  /// Loads the persisted list from the store on first read and exposes
  /// [add] / [remove] / [toggle] for the phase-2 UI layer. Mirrors the
  /// per-station [AlertNotifier] shape so users of either can swap
  /// between the two in follow-up PRs without relearning the surface.
  RadiusAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radiusAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radiusAlertsHash();

  @$internal
  @override
  RadiusAlerts create() => RadiusAlerts();
}

String _$radiusAlertsHash() => r'f061e4846f0e417feb7f40ebe3e52057c8a1f227';

/// Radius-watchlist state (#578 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] for the phase-2 UI layer. Mirrors the
/// per-station [AlertNotifier] shape so users of either can swap
/// between the two in follow-up PRs without relearning the surface.

abstract class _$RadiusAlerts extends $AsyncNotifier<List<RadiusAlert>> {
  FutureOr<List<RadiusAlert>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<RadiusAlert>>, List<RadiusAlert>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RadiusAlert>>, List<RadiusAlert>>,
              AsyncValue<List<RadiusAlert>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
