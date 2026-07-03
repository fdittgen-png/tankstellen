// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_shares_sync_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether cross-account trip SHARING is available (#2240).
///
/// Cross-account sharing is a strict superset of the per-account trip
/// sync gate: you can only share a trip that's syncing in the first
/// place, and the same conditions apply (`cloudSync` consent ∧
/// `syncTrips` toggle — #3448 dropped the former email requirement).
/// Rather than duplicate that logic, this derives from
/// [tripsSyncEnabled] — so a future change to the trip-sync gate
/// automatically flows through to the share affordances, and the share
/// Action / "shared with me" section stay hidden for consent-off
/// sessions.

@ProviderFor(tripSharesSyncEnabled)
final tripSharesSyncEnabledProvider = TripSharesSyncEnabledProvider._();

/// Whether cross-account trip SHARING is available (#2240).
///
/// Cross-account sharing is a strict superset of the per-account trip
/// sync gate: you can only share a trip that's syncing in the first
/// place, and the same conditions apply (`cloudSync` consent ∧
/// `syncTrips` toggle — #3448 dropped the former email requirement).
/// Rather than duplicate that logic, this derives from
/// [tripsSyncEnabled] — so a future change to the trip-sync gate
/// automatically flows through to the share affordances, and the share
/// Action / "shared with me" section stay hidden for consent-off
/// sessions.

final class TripSharesSyncEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether cross-account trip SHARING is available (#2240).
  ///
  /// Cross-account sharing is a strict superset of the per-account trip
  /// sync gate: you can only share a trip that's syncing in the first
  /// place, and the same conditions apply (`cloudSync` consent ∧
  /// `syncTrips` toggle — #3448 dropped the former email requirement).
  /// Rather than duplicate that logic, this derives from
  /// [tripsSyncEnabled] — so a future change to the trip-sync gate
  /// automatically flows through to the share affordances, and the share
  /// Action / "shared with me" section stay hidden for consent-off
  /// sessions.
  TripSharesSyncEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripSharesSyncEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripSharesSyncEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return tripSharesSyncEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tripSharesSyncEnabledHash() =>
    r'36f29d273fd8aa9ce87c340229b172aa05dfeb60';
