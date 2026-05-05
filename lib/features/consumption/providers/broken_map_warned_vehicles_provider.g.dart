// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broken_map_warned_vehicles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory set of vehicle ids for which the
/// `brokenMapSnackbarUnreliable` warning has already fired this app
/// session (#1423 phase 5).
///
/// Lives only for the lifetime of the [ProviderContainer]: a fresh app
/// launch (or pulling down to "Discard data" in the privacy dashboard
/// which disposes the container) replays a single warning per vehicle
/// once the belief crosses the 0.7 threshold again.
///
/// Intentionally NOT persisted: the spec says "fire ONCE per session
/// per vehicle when crossing into this band", and persisting would
/// silently swallow the warning forever after the user dismissed it
/// once — a regression we'd never know about. A weekly relapse on
/// a flaky adapter is the desired UX.

@ProviderFor(BrokenMapWarnedVehicles)
final brokenMapWarnedVehiclesProvider = BrokenMapWarnedVehiclesProvider._();

/// In-memory set of vehicle ids for which the
/// `brokenMapSnackbarUnreliable` warning has already fired this app
/// session (#1423 phase 5).
///
/// Lives only for the lifetime of the [ProviderContainer]: a fresh app
/// launch (or pulling down to "Discard data" in the privacy dashboard
/// which disposes the container) replays a single warning per vehicle
/// once the belief crosses the 0.7 threshold again.
///
/// Intentionally NOT persisted: the spec says "fire ONCE per session
/// per vehicle when crossing into this band", and persisting would
/// silently swallow the warning forever after the user dismissed it
/// once — a regression we'd never know about. A weekly relapse on
/// a flaky adapter is the desired UX.
final class BrokenMapWarnedVehiclesProvider
    extends $NotifierProvider<BrokenMapWarnedVehicles, Set<String>> {
  /// In-memory set of vehicle ids for which the
  /// `brokenMapSnackbarUnreliable` warning has already fired this app
  /// session (#1423 phase 5).
  ///
  /// Lives only for the lifetime of the [ProviderContainer]: a fresh app
  /// launch (or pulling down to "Discard data" in the privacy dashboard
  /// which disposes the container) replays a single warning per vehicle
  /// once the belief crosses the 0.7 threshold again.
  ///
  /// Intentionally NOT persisted: the spec says "fire ONCE per session
  /// per vehicle when crossing into this band", and persisting would
  /// silently swallow the warning forever after the user dismissed it
  /// once — a regression we'd never know about. A weekly relapse on
  /// a flaky adapter is the desired UX.
  BrokenMapWarnedVehiclesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brokenMapWarnedVehiclesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brokenMapWarnedVehiclesHash();

  @$internal
  @override
  BrokenMapWarnedVehicles create() => BrokenMapWarnedVehicles();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$brokenMapWarnedVehiclesHash() =>
    r'2b44b8aee20f71ae61322688bd7d468c078c4021';

/// In-memory set of vehicle ids for which the
/// `brokenMapSnackbarUnreliable` warning has already fired this app
/// session (#1423 phase 5).
///
/// Lives only for the lifetime of the [ProviderContainer]: a fresh app
/// launch (or pulling down to "Discard data" in the privacy dashboard
/// which disposes the container) replays a single warning per vehicle
/// once the belief crosses the 0.7 threshold again.
///
/// Intentionally NOT persisted: the spec says "fire ONCE per session
/// per vehicle when crossing into this band", and persisting would
/// silently swallow the warning forever after the user dismissed it
/// once — a regression we'd never know about. A weekly relapse on
/// a flaky adapter is the desired UX.

abstract class _$BrokenMapWarnedVehicles extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
