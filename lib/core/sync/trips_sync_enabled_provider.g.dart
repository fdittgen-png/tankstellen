// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_sync_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether recorded trajets sync to TankSync (#1665).
///
/// The single source of truth for the trajet-sync gate — `A ∧ B ∧ C`:
///  - **A** — a non-anonymous (email-backed) TankSync account
///    (`SyncConfig.hasEmail`);
///  - **B** — the master `cloudSync` GDPR consent;
///  - **C** — the `syncTrips` toggle.
///
/// Consulted at both trigger points — the `_saveToHistory` upload hook
/// in `trip_recording_provider` and the app-launch `_runTripsSyncMerge`
/// — so an anonymous session neither uploads nor merges trip rows.
/// `TripsSync` stays a pure I/O helper (its `currentUser == null`
/// early-return is a safety net); the gate lives here, not in the wire
/// layer.
///
/// `cloudSync` and `syncTrips` are checked explicitly rather than
/// relying on `GdprConsent.save()`'s `effectiveSyncTrips` coupling —
/// a fresh `build()` reads the raw stored values, so a stale
/// `syncTrips = true` under `cloudSync = false` must still gate off.

@ProviderFor(tripsSyncEnabled)
final tripsSyncEnabledProvider = TripsSyncEnabledProvider._();

/// Whether recorded trajets sync to TankSync (#1665).
///
/// The single source of truth for the trajet-sync gate — `A ∧ B ∧ C`:
///  - **A** — a non-anonymous (email-backed) TankSync account
///    (`SyncConfig.hasEmail`);
///  - **B** — the master `cloudSync` GDPR consent;
///  - **C** — the `syncTrips` toggle.
///
/// Consulted at both trigger points — the `_saveToHistory` upload hook
/// in `trip_recording_provider` and the app-launch `_runTripsSyncMerge`
/// — so an anonymous session neither uploads nor merges trip rows.
/// `TripsSync` stays a pure I/O helper (its `currentUser == null`
/// early-return is a safety net); the gate lives here, not in the wire
/// layer.
///
/// `cloudSync` and `syncTrips` are checked explicitly rather than
/// relying on `GdprConsent.save()`'s `effectiveSyncTrips` coupling —
/// a fresh `build()` reads the raw stored values, so a stale
/// `syncTrips = true` under `cloudSync = false` must still gate off.

final class TripsSyncEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether recorded trajets sync to TankSync (#1665).
  ///
  /// The single source of truth for the trajet-sync gate — `A ∧ B ∧ C`:
  ///  - **A** — a non-anonymous (email-backed) TankSync account
  ///    (`SyncConfig.hasEmail`);
  ///  - **B** — the master `cloudSync` GDPR consent;
  ///  - **C** — the `syncTrips` toggle.
  ///
  /// Consulted at both trigger points — the `_saveToHistory` upload hook
  /// in `trip_recording_provider` and the app-launch `_runTripsSyncMerge`
  /// — so an anonymous session neither uploads nor merges trip rows.
  /// `TripsSync` stays a pure I/O helper (its `currentUser == null`
  /// early-return is a safety net); the gate lives here, not in the wire
  /// layer.
  ///
  /// `cloudSync` and `syncTrips` are checked explicitly rather than
  /// relying on `GdprConsent.save()`'s `effectiveSyncTrips` coupling —
  /// a fresh `build()` reads the raw stored values, so a stale
  /// `syncTrips = true` under `cloudSync = false` must still gate off.
  TripsSyncEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripsSyncEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripsSyncEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return tripsSyncEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tripsSyncEnabledHash() => r'a97a4800280e788bed5f5255b944b91e6f1d8f0b';
