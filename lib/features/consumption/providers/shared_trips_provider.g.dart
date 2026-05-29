// GENERATED CODE - DO NOT MODIFY BY HAND

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
/// returns an empty list without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.

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
/// returns an empty list without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.
final class SharedTripsProvider
    extends $AsyncNotifierProvider<SharedTrips, List<TripHistoryEntry>> {
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
  /// returns an empty list without a wire call, so the "Shared with me"
  /// section stays hidden exactly when sharing itself is unavailable.
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

String _$sharedTripsHash() => r'74c71b5823f8c0d1beece02503233ee2820198e1';

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
/// returns an empty list without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.

abstract class _$SharedTrips extends $AsyncNotifier<List<TripHistoryEntry>> {
  FutureOr<List<TripHistoryEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TripHistoryEntry>>, List<TripHistoryEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TripHistoryEntry>>,
                List<TripHistoryEntry>
              >,
              AsyncValue<List<TripHistoryEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
