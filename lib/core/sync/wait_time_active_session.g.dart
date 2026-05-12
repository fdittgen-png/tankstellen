// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wait_time_active_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for the active-session store. `keepAlive: true`
/// so the wait-time UI on the station-detail screen + the toggle on
/// any other surface share the same Hive-backed instance.

@ProviderFor(waitTimeActiveSessionStore)
final waitTimeActiveSessionStoreProvider =
    WaitTimeActiveSessionStoreProvider._();

/// Riverpod provider for the active-session store. `keepAlive: true`
/// so the wait-time UI on the station-detail screen + the toggle on
/// any other surface share the same Hive-backed instance.

final class WaitTimeActiveSessionStoreProvider
    extends
        $FunctionalProvider<
          WaitTimeActiveSessionStore,
          WaitTimeActiveSessionStore,
          WaitTimeActiveSessionStore
        >
    with $Provider<WaitTimeActiveSessionStore> {
  /// Riverpod provider for the active-session store. `keepAlive: true`
  /// so the wait-time UI on the station-detail screen + the toggle on
  /// any other surface share the same Hive-backed instance.
  WaitTimeActiveSessionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waitTimeActiveSessionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waitTimeActiveSessionStoreHash();

  @$internal
  @override
  $ProviderElement<WaitTimeActiveSessionStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WaitTimeActiveSessionStore create(Ref ref) {
    return waitTimeActiveSessionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaitTimeActiveSessionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaitTimeActiveSessionStore>(value),
    );
  }
}

String _$waitTimeActiveSessionStoreHash() =>
    r'e98a696b440eae638506c658577a7cc81a6bd1b3';

/// Riverpod-exposed snapshot of the current active session. Returns
/// null when no session is in flight.
///
/// State changes are pushed by the toggle UI calling
/// `ref.invalidate(waitTimeActiveSessionProvider)` after `start` /
/// `clear` so consumers re-render. Mirrors the deliberate
/// invalidation pattern used by the favourites + ratings providers
/// rather than wiring a Hive listenable.

@ProviderFor(waitTimeActiveSession)
final waitTimeActiveSessionProvider = WaitTimeActiveSessionProvider._();

/// Riverpod-exposed snapshot of the current active session. Returns
/// null when no session is in flight.
///
/// State changes are pushed by the toggle UI calling
/// `ref.invalidate(waitTimeActiveSessionProvider)` after `start` /
/// `clear` so consumers re-render. Mirrors the deliberate
/// invalidation pattern used by the favourites + ratings providers
/// rather than wiring a Hive listenable.

final class WaitTimeActiveSessionProvider
    extends
        $FunctionalProvider<
          WaitTimeActiveSession?,
          WaitTimeActiveSession?,
          WaitTimeActiveSession?
        >
    with $Provider<WaitTimeActiveSession?> {
  /// Riverpod-exposed snapshot of the current active session. Returns
  /// null when no session is in flight.
  ///
  /// State changes are pushed by the toggle UI calling
  /// `ref.invalidate(waitTimeActiveSessionProvider)` after `start` /
  /// `clear` so consumers re-render. Mirrors the deliberate
  /// invalidation pattern used by the favourites + ratings providers
  /// rather than wiring a Hive listenable.
  WaitTimeActiveSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waitTimeActiveSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waitTimeActiveSessionHash();

  @$internal
  @override
  $ProviderElement<WaitTimeActiveSession?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WaitTimeActiveSession? create(Ref ref) {
    return waitTimeActiveSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaitTimeActiveSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaitTimeActiveSession?>(value),
    );
  }
}

String _$waitTimeActiveSessionHash() =>
    r'ba2c8f88950bcf1ae8036449e7583b9bd9a73cf5';
