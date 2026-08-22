// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'shared_trips_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Trips shared WITH me by another TankSync account (#2240), surfaced
/// read-only on the Trajets tab.
///
/// Distinct from [tripHistoryListProvider], which holds the user's own
/// recorded trips. These entries are fetched live from the server via
/// the recipient-read RLS path and are NEVER persisted to the local
/// Hive box — sharing only grants read access, so a revoked share
/// simply disappears on the next refresh rather than leaving a stale
/// local copy the recipient can't account for.
///
/// Gated on [tripSharesSyncEnabled]: an anonymous / consent-off session
/// returns an empty result without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.
///
/// #3726 — the raw fetch also carries the trip → author map; UI
/// consumers watch [visibleSharedTrips] instead, which applies the
/// report/block moderation filter.

@ProviderFor(SharedTrips)
final sharedTripsProvider = SharedTripsProvider._();

/// Trips shared WITH me by another TankSync account (#2240), surfaced
/// read-only on the Trajets tab.
///
/// Distinct from [tripHistoryListProvider], which holds the user's own
/// recorded trips. These entries are fetched live from the server via
/// the recipient-read RLS path and are NEVER persisted to the local
/// Hive box — sharing only grants read access, so a revoked share
/// simply disappears on the next refresh rather than leaving a stale
/// local copy the recipient can't account for.
///
/// Gated on [tripSharesSyncEnabled]: an anonymous / consent-off session
/// returns an empty result without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.
///
/// #3726 — the raw fetch also carries the trip → author map; UI
/// consumers watch [visibleSharedTrips] instead, which applies the
/// report/block moderation filter.
final class SharedTripsProvider
    extends $AsyncNotifierProvider<SharedTrips, SharedTripsFetch> {
  /// Trips shared WITH me by another TankSync account (#2240), surfaced
  /// read-only on the Trajets tab.
  ///
  /// Distinct from [tripHistoryListProvider], which holds the user's own
  /// recorded trips. These entries are fetched live from the server via
  /// the recipient-read RLS path and are NEVER persisted to the local
  /// Hive box — sharing only grants read access, so a revoked share
  /// simply disappears on the next refresh rather than leaving a stale
  /// local copy the recipient can't account for.
  ///
  /// Gated on [tripSharesSyncEnabled]: an anonymous / consent-off session
  /// returns an empty result without a wire call, so the "Shared with me"
  /// section stays hidden exactly when sharing itself is unavailable.
  ///
  /// #3726 — the raw fetch also carries the trip → author map; UI
  /// consumers watch [visibleSharedTrips] instead, which applies the
  /// report/block moderation filter.
  SharedTripsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedTripsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedTripsHash();

  @$internal
  @override
  SharedTrips create() => SharedTrips();
}

String _$sharedTripsHash() => r'61a6dbcaa94c53b08c5ea3699d93e32d705e9c59';

/// Trips shared WITH me by another TankSync account (#2240), surfaced
/// read-only on the Trajets tab.
///
/// Distinct from [tripHistoryListProvider], which holds the user's own
/// recorded trips. These entries are fetched live from the server via
/// the recipient-read RLS path and are NEVER persisted to the local
/// Hive box — sharing only grants read access, so a revoked share
/// simply disappears on the next refresh rather than leaving a stale
/// local copy the recipient can't account for.
///
/// Gated on [tripSharesSyncEnabled]: an anonymous / consent-off session
/// returns an empty result without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.
///
/// #3726 — the raw fetch also carries the trip → author map; UI
/// consumers watch [visibleSharedTrips] instead, which applies the
/// report/block moderation filter.

abstract class _$SharedTrips extends $AsyncNotifier<SharedTripsFetch> {
  FutureOr<SharedTripsFetch> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SharedTripsFetch>, SharedTripsFetch>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SharedTripsFetch>, SharedTripsFetch>,
              AsyncValue<SharedTripsFetch>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The shared-with-me trips AFTER moderation (#3726): entries whose
/// author the viewer blocked, or which the viewer reported, are
/// filtered out. Every render surface (Trajets section, trip-detail
/// fallback) watches THIS, never the raw [sharedTripsProvider], so
/// blocked/reported content disappears everywhere at once.

@ProviderFor(visibleSharedTrips)
final visibleSharedTripsProvider = VisibleSharedTripsProvider._();

/// The shared-with-me trips AFTER moderation (#3726): entries whose
/// author the viewer blocked, or which the viewer reported, are
/// filtered out. Every render surface (Trajets section, trip-detail
/// fallback) watches THIS, never the raw [sharedTripsProvider], so
/// blocked/reported content disappears everywhere at once.

final class VisibleSharedTripsProvider
    extends
        $FunctionalProvider<
          SharedTripsFetch,
          SharedTripsFetch,
          SharedTripsFetch
        >
    with $Provider<SharedTripsFetch> {
  /// The shared-with-me trips AFTER moderation (#3726): entries whose
  /// author the viewer blocked, or which the viewer reported, are
  /// filtered out. Every render surface (Trajets section, trip-detail
  /// fallback) watches THIS, never the raw [sharedTripsProvider], so
  /// blocked/reported content disappears everywhere at once.
  VisibleSharedTripsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleSharedTripsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleSharedTripsHash();

  @$internal
  @override
  $ProviderElement<SharedTripsFetch> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharedTripsFetch create(Ref ref) {
    return visibleSharedTrips(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedTripsFetch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedTripsFetch>(value),
    );
  }
}

String _$visibleSharedTripsHash() =>
    r'f05af72d3a3dfec1359cc5229ed11a7c75f331de';
