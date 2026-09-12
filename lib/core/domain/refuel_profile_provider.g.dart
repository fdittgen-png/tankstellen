// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'refuel_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The vehicle side of the refuel decision — consumption, and how much
/// the user typically buys (#4089, Epic #4087).
///
/// ## Why this is declared in core and implemented elsewhere
///
/// The results screen needs a profile to rank by Best Value, but the
/// numbers come from the fill-ups feature (measured consumption, the
/// user's own fill volumes). Having `features/search` read
/// `features/fill_ups` would add a cross-feature edge that
/// `feature_boundary_test` correctly refuses — `search` imports nothing
/// from `fill_ups` today.
///
/// So the dependency is inverted, the way the repo's decomposition rule
/// prescribes: this provider is declared here against the CORE type,
/// defaults to a profile with no consumption, and the composition root
/// (`AppInitializer`, which may import features) overrides it with the
/// real one via `refuelProfileOverrides()`. Search depends on core;
/// fill_ups supplies the value; neither knows about the other.
///
/// The default is deliberately empty rather than a plausible guess: with
/// no consumption the engine withholds Best Value and the UI says why,
/// which is the spec's first trust rule. A fabricated default would turn
/// a missing measurement into a confident recommendation.

@ProviderFor(refuelProfile)
final refuelProfileProvider = RefuelProfileProvider._();

/// The vehicle side of the refuel decision — consumption, and how much
/// the user typically buys (#4089, Epic #4087).
///
/// ## Why this is declared in core and implemented elsewhere
///
/// The results screen needs a profile to rank by Best Value, but the
/// numbers come from the fill-ups feature (measured consumption, the
/// user's own fill volumes). Having `features/search` read
/// `features/fill_ups` would add a cross-feature edge that
/// `feature_boundary_test` correctly refuses — `search` imports nothing
/// from `fill_ups` today.
///
/// So the dependency is inverted, the way the repo's decomposition rule
/// prescribes: this provider is declared here against the CORE type,
/// defaults to a profile with no consumption, and the composition root
/// (`AppInitializer`, which may import features) overrides it with the
/// real one via `refuelProfileOverrides()`. Search depends on core;
/// fill_ups supplies the value; neither knows about the other.
///
/// The default is deliberately empty rather than a plausible guess: with
/// no consumption the engine withholds Best Value and the UI says why,
/// which is the spec's first trust rule. A fabricated default would turn
/// a missing measurement into a confident recommendation.

final class RefuelProfileProvider
    extends $FunctionalProvider<RefuelProfile, RefuelProfile, RefuelProfile>
    with $Provider<RefuelProfile> {
  /// The vehicle side of the refuel decision — consumption, and how much
  /// the user typically buys (#4089, Epic #4087).
  ///
  /// ## Why this is declared in core and implemented elsewhere
  ///
  /// The results screen needs a profile to rank by Best Value, but the
  /// numbers come from the fill-ups feature (measured consumption, the
  /// user's own fill volumes). Having `features/search` read
  /// `features/fill_ups` would add a cross-feature edge that
  /// `feature_boundary_test` correctly refuses — `search` imports nothing
  /// from `fill_ups` today.
  ///
  /// So the dependency is inverted, the way the repo's decomposition rule
  /// prescribes: this provider is declared here against the CORE type,
  /// defaults to a profile with no consumption, and the composition root
  /// (`AppInitializer`, which may import features) overrides it with the
  /// real one via `refuelProfileOverrides()`. Search depends on core;
  /// fill_ups supplies the value; neither knows about the other.
  ///
  /// The default is deliberately empty rather than a plausible guess: with
  /// no consumption the engine withholds Best Value and the UI says why,
  /// which is the spec's first trust rule. A fabricated default would turn
  /// a missing measurement into a confident recommendation.
  RefuelProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refuelProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refuelProfileHash();

  @$internal
  @override
  $ProviderElement<RefuelProfile> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RefuelProfile create(Ref ref) {
    return refuelProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefuelProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefuelProfile>(value),
    );
  }
}

String _$refuelProfileHash() => r'39a424e1d9e239abf1d80589ab22181bb4abfe63';
