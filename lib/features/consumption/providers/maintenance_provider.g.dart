// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod wiring for the predictive-maintenance heuristics (#1124).
///
/// Three providers:
///
///   * [maintenanceSnoozeRepository] — singleton repository over the
///     `settings` Hive box. Always returns a real instance; the repo
///     itself defends against a closed box.
///   * [maintenanceSuggestions] — derived list. Watches the trip-
///     history provider, runs the analyzer over the last 30 days, and
///     filters out any signal currently in snooze. Empty when the
///     box is empty / not enough trips / nothing fires.
///   * [MaintenanceSuggestionsController] — actions. The card's
///     dismiss + snooze buttons go through this so a press triggers a
///     re-evaluation of the derived provider on the next frame.
///
/// Why a controller instead of `ref.read(snoozeRepositoryProvider).snooze`:
/// the snooze action needs to invalidate the suggestions provider so
/// the dismissed card disappears immediately. Wrapping the snooze in
/// a notifier makes the side effect explicit and lets widget tests
/// assert "tapping snooze removes the card" without timer plumbing.
/// Singleton snooze repository. `keepAlive: true` because the repo
/// itself is cheap (no state beyond the box reference) and we want
/// the same instance for the duration of the app session.

@ProviderFor(maintenanceSnoozeRepository)
final maintenanceSnoozeRepositoryProvider =
    MaintenanceSnoozeRepositoryProvider._();

/// Riverpod wiring for the predictive-maintenance heuristics (#1124).
///
/// Three providers:
///
///   * [maintenanceSnoozeRepository] — singleton repository over the
///     `settings` Hive box. Always returns a real instance; the repo
///     itself defends against a closed box.
///   * [maintenanceSuggestions] — derived list. Watches the trip-
///     history provider, runs the analyzer over the last 30 days, and
///     filters out any signal currently in snooze. Empty when the
///     box is empty / not enough trips / nothing fires.
///   * [MaintenanceSuggestionsController] — actions. The card's
///     dismiss + snooze buttons go through this so a press triggers a
///     re-evaluation of the derived provider on the next frame.
///
/// Why a controller instead of `ref.read(snoozeRepositoryProvider).snooze`:
/// the snooze action needs to invalidate the suggestions provider so
/// the dismissed card disappears immediately. Wrapping the snooze in
/// a notifier makes the side effect explicit and lets widget tests
/// assert "tapping snooze removes the card" without timer plumbing.
/// Singleton snooze repository. `keepAlive: true` because the repo
/// itself is cheap (no state beyond the box reference) and we want
/// the same instance for the duration of the app session.

final class MaintenanceSnoozeRepositoryProvider
    extends
        $FunctionalProvider<
          MaintenanceSnoozeRepository,
          MaintenanceSnoozeRepository,
          MaintenanceSnoozeRepository
        >
    with $Provider<MaintenanceSnoozeRepository> {
  /// Riverpod wiring for the predictive-maintenance heuristics (#1124).
  ///
  /// Three providers:
  ///
  ///   * [maintenanceSnoozeRepository] — singleton repository over the
  ///     `settings` Hive box. Always returns a real instance; the repo
  ///     itself defends against a closed box.
  ///   * [maintenanceSuggestions] — derived list. Watches the trip-
  ///     history provider, runs the analyzer over the last 30 days, and
  ///     filters out any signal currently in snooze. Empty when the
  ///     box is empty / not enough trips / nothing fires.
  ///   * [MaintenanceSuggestionsController] — actions. The card's
  ///     dismiss + snooze buttons go through this so a press triggers a
  ///     re-evaluation of the derived provider on the next frame.
  ///
  /// Why a controller instead of `ref.read(snoozeRepositoryProvider).snooze`:
  /// the snooze action needs to invalidate the suggestions provider so
  /// the dismissed card disappears immediately. Wrapping the snooze in
  /// a notifier makes the side effect explicit and lets widget tests
  /// assert "tapping snooze removes the card" without timer plumbing.
  /// Singleton snooze repository. `keepAlive: true` because the repo
  /// itself is cheap (no state beyond the box reference) and we want
  /// the same instance for the duration of the app session.
  MaintenanceSnoozeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maintenanceSnoozeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maintenanceSnoozeRepositoryHash();

  @$internal
  @override
  $ProviderElement<MaintenanceSnoozeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MaintenanceSnoozeRepository create(Ref ref) {
    return maintenanceSnoozeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MaintenanceSnoozeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MaintenanceSnoozeRepository>(value),
    );
  }
}

String _$maintenanceSnoozeRepositoryHash() =>
    r'2ea4debad04b6e5a6e2cf5f96375763a0010b093';

/// List of currently-active maintenance suggestions for the user.
///
/// Pipeline:
///   1. Watch the trip-history provider so a new trip retriggers the
///      analyzer.
///   2. Run [analyzeMaintenance] over the in-window trips.
///   3. Filter out signals whose snooze timestamp is in the future.
///
/// Sorting: confidence descending — the heuristic the analyzer is
/// most sure of lands first. Ties keep the analyzer's natural order
/// (idle creep before MAF deviation), which matches the order they
/// were introduced in the issue body.

@ProviderFor(maintenanceSuggestions)
final maintenanceSuggestionsProvider = MaintenanceSuggestionsProvider._();

/// List of currently-active maintenance suggestions for the user.
///
/// Pipeline:
///   1. Watch the trip-history provider so a new trip retriggers the
///      analyzer.
///   2. Run [analyzeMaintenance] over the in-window trips.
///   3. Filter out signals whose snooze timestamp is in the future.
///
/// Sorting: confidence descending — the heuristic the analyzer is
/// most sure of lands first. Ties keep the analyzer's natural order
/// (idle creep before MAF deviation), which matches the order they
/// were introduced in the issue body.

final class MaintenanceSuggestionsProvider
    extends
        $FunctionalProvider<
          List<MaintenanceSuggestion>,
          List<MaintenanceSuggestion>,
          List<MaintenanceSuggestion>
        >
    with $Provider<List<MaintenanceSuggestion>> {
  /// List of currently-active maintenance suggestions for the user.
  ///
  /// Pipeline:
  ///   1. Watch the trip-history provider so a new trip retriggers the
  ///      analyzer.
  ///   2. Run [analyzeMaintenance] over the in-window trips.
  ///   3. Filter out signals whose snooze timestamp is in the future.
  ///
  /// Sorting: confidence descending — the heuristic the analyzer is
  /// most sure of lands first. Ties keep the analyzer's natural order
  /// (idle creep before MAF deviation), which matches the order they
  /// were introduced in the issue body.
  MaintenanceSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maintenanceSuggestionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maintenanceSuggestionsHash();

  @$internal
  @override
  $ProviderElement<List<MaintenanceSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MaintenanceSuggestion> create(Ref ref) {
    return maintenanceSuggestions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MaintenanceSuggestion> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MaintenanceSuggestion>>(value),
    );
  }
}

String _$maintenanceSuggestionsHash() =>
    r'cecebc2b87923ed902342a1ead710a574a490066';

/// Action surface for the maintenance card. Wraps the snooze repo
/// so widget tests can stub it via the standard Riverpod override
/// path and so a snooze invalidates [maintenanceSuggestionsProvider]
/// on the next frame.

@ProviderFor(MaintenanceSuggestionsController)
final maintenanceSuggestionsControllerProvider =
    MaintenanceSuggestionsControllerProvider._();

/// Action surface for the maintenance card. Wraps the snooze repo
/// so widget tests can stub it via the standard Riverpod override
/// path and so a snooze invalidates [maintenanceSuggestionsProvider]
/// on the next frame.
final class MaintenanceSuggestionsControllerProvider
    extends $NotifierProvider<MaintenanceSuggestionsController, void> {
  /// Action surface for the maintenance card. Wraps the snooze repo
  /// so widget tests can stub it via the standard Riverpod override
  /// path and so a snooze invalidates [maintenanceSuggestionsProvider]
  /// on the next frame.
  MaintenanceSuggestionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maintenanceSuggestionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maintenanceSuggestionsControllerHash();

  @$internal
  @override
  MaintenanceSuggestionsController create() =>
      MaintenanceSuggestionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$maintenanceSuggestionsControllerHash() =>
    r'34f84c3c575f5b1f3d743820a858890c20da89c2';

/// Action surface for the maintenance card. Wraps the snooze repo
/// so widget tests can stub it via the standard Riverpod override
/// path and so a snooze invalidates [maintenanceSuggestionsProvider]
/// on the next frame.

abstract class _$MaintenanceSuggestionsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
