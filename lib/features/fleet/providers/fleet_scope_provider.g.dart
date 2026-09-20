// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fleet_scope_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sync facts fleet scope is derived from, as one overridable seam.
///
/// A test states "community backend" or "anonymous identity" by
/// overriding this with a plain [SyncConfig]; production reads the live
/// [syncStateProvider]. Without the seam the identity half would only be
/// reachable through `TankSyncClient`'s statics.

@ProviderFor(fleetSyncConfig)
final fleetSyncConfigProvider = FleetSyncConfigProvider._();

/// The sync facts fleet scope is derived from, as one overridable seam.
///
/// A test states "community backend" or "anonymous identity" by
/// overriding this with a plain [SyncConfig]; production reads the live
/// [syncStateProvider]. Without the seam the identity half would only be
/// reachable through `TankSyncClient`'s statics.

final class FleetSyncConfigProvider
    extends $FunctionalProvider<SyncConfig, SyncConfig, SyncConfig>
    with $Provider<SyncConfig> {
  /// The sync facts fleet scope is derived from, as one overridable seam.
  ///
  /// A test states "community backend" or "anonymous identity" by
  /// overriding this with a plain [SyncConfig]; production reads the live
  /// [syncStateProvider]. Without the seam the identity half would only be
  /// reachable through `TankSyncClient`'s statics.
  FleetSyncConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetSyncConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetSyncConfigHash();

  @$internal
  @override
  $ProviderElement<SyncConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncConfig create(Ref ref) {
    return fleetSyncConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncConfig>(value),
    );
  }
}

String _$fleetSyncConfigHash() => r'797e9f985799730cd85b9f656d2aaa8d89a1af6e';

/// The directory cache fleet scope reads. Overridden in tests with an
/// in-memory [FleetDirectoryCache]; production gets the encrypted box.

@ProviderFor(fleetDirectoryCache)
final fleetDirectoryCacheProvider = FleetDirectoryCacheProvider._();

/// The directory cache fleet scope reads. Overridden in tests with an
/// in-memory [FleetDirectoryCache]; production gets the encrypted box.

final class FleetDirectoryCacheProvider
    extends
        $FunctionalProvider<
          FleetDirectoryCache,
          FleetDirectoryCache,
          FleetDirectoryCache
        >
    with $Provider<FleetDirectoryCache> {
  /// The directory cache fleet scope reads. Overridden in tests with an
  /// in-memory [FleetDirectoryCache]; production gets the encrypted box.
  FleetDirectoryCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetDirectoryCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetDirectoryCacheHash();

  @$internal
  @override
  $ProviderElement<FleetDirectoryCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FleetDirectoryCache create(Ref ref) {
    return fleetDirectoryCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetDirectoryCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetDirectoryCache>(value),
    );
  }
}

String _$fleetDirectoryCacheHash() =>
    r'3bd7e0d8cbd144e7780524fccd7d71079d3e3832';

/// The device's current [FleetScope].
///
/// Order of judgement — each step is a different answer, never a
/// fallback to the next:
///
///   1. no configured/enabled sync → `unavailable(syncDisabled)`;
///   2. the community backend → `unavailable(communityBackend)` (D3:
///      an organisation never lives there);
///   3. an anonymous identity → `unavailable(identityRequired)` (D2);
///   4. no stored org membership → `none`;
///   5. no (readable) cached directory for THIS backend + account + org
///      → `none` — an offline device grants nothing;
///   6. otherwise the cache's own three-valued freshness verdict
///      (`fresh` → active, `stale`, `expired`).

@ProviderFor(fleetScope)
final fleetScopeProvider = FleetScopeProvider._();

/// The device's current [FleetScope].
///
/// Order of judgement — each step is a different answer, never a
/// fallback to the next:
///
///   1. no configured/enabled sync → `unavailable(syncDisabled)`;
///   2. the community backend → `unavailable(communityBackend)` (D3:
///      an organisation never lives there);
///   3. an anonymous identity → `unavailable(identityRequired)` (D2);
///   4. no stored org membership → `none`;
///   5. no (readable) cached directory for THIS backend + account + org
///      → `none` — an offline device grants nothing;
///   6. otherwise the cache's own three-valued freshness verdict
///      (`fresh` → active, `stale`, `expired`).

final class FleetScopeProvider
    extends $FunctionalProvider<FleetScope, FleetScope, FleetScope>
    with $Provider<FleetScope> {
  /// The device's current [FleetScope].
  ///
  /// Order of judgement — each step is a different answer, never a
  /// fallback to the next:
  ///
  ///   1. no configured/enabled sync → `unavailable(syncDisabled)`;
  ///   2. the community backend → `unavailable(communityBackend)` (D3:
  ///      an organisation never lives there);
  ///   3. an anonymous identity → `unavailable(identityRequired)` (D2);
  ///   4. no stored org membership → `none`;
  ///   5. no (readable) cached directory for THIS backend + account + org
  ///      → `none` — an offline device grants nothing;
  ///   6. otherwise the cache's own three-valued freshness verdict
  ///      (`fresh` → active, `stale`, `expired`).
  FleetScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetScopeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetScopeHash();

  @$internal
  @override
  $ProviderElement<FleetScope> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FleetScope create(Ref ref) {
    return fleetScope(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetScope value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetScope>(value),
    );
  }
}

String _$fleetScopeHash() => r'56ef19b5349744dec39103e367c442d2780de855';
