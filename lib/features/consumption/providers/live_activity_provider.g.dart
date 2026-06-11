// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single app-wide [LiveActivityController] (#3170) — the channel
/// admits exactly one native counterpart, so one Dart binding mirrors
/// the [PipController] singleton convention.

@ProviderFor(liveActivityController)
final liveActivityControllerProvider = LiveActivityControllerProvider._();

/// The single app-wide [LiveActivityController] (#3170) — the channel
/// admits exactly one native counterpart, so one Dart binding mirrors
/// the [PipController] singleton convention.

final class LiveActivityControllerProvider
    extends
        $FunctionalProvider<
          LiveActivityController,
          LiveActivityController,
          LiveActivityController
        >
    with $Provider<LiveActivityController> {
  /// The single app-wide [LiveActivityController] (#3170) — the channel
  /// admits exactly one native counterpart, so one Dart binding mirrors
  /// the [PipController] singleton convention.
  LiveActivityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveActivityControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveActivityControllerHash();

  @$internal
  @override
  $ProviderElement<LiveActivityController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LiveActivityController create(Ref ref) {
    return liveActivityController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveActivityController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveActivityController>(value),
    );
  }
}

String _$liveActivityControllerHash() =>
    r'3f8ade6e06fb4c261ca2a54dfb26df691c207f14';

/// The single app-wide [LiveActivityCoordinator] — keepAlive so its
/// throttle state (last-sent content / timestamps) survives across
/// [LiveActivitySync] rebuilds, which happen on every recorder emit.

@ProviderFor(liveActivityCoordinator)
final liveActivityCoordinatorProvider = LiveActivityCoordinatorProvider._();

/// The single app-wide [LiveActivityCoordinator] — keepAlive so its
/// throttle state (last-sent content / timestamps) survives across
/// [LiveActivitySync] rebuilds, which happen on every recorder emit.

final class LiveActivityCoordinatorProvider
    extends
        $FunctionalProvider<
          LiveActivityCoordinator,
          LiveActivityCoordinator,
          LiveActivityCoordinator
        >
    with $Provider<LiveActivityCoordinator> {
  /// The single app-wide [LiveActivityCoordinator] — keepAlive so its
  /// throttle state (last-sent content / timestamps) survives across
  /// [LiveActivitySync] rebuilds, which happen on every recorder emit.
  LiveActivityCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveActivityCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveActivityCoordinatorHash();

  @$internal
  @override
  $ProviderElement<LiveActivityCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LiveActivityCoordinator create(Ref ref) {
    return liveActivityCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveActivityCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveActivityCoordinator>(value),
    );
  }
}

String _$liveActivityCoordinatorHash() =>
    r'9780e89f3a4c8d68537b5d45fa3872dce2e699d8';

/// Keeps the iOS Live Activity (lock screen + Dynamic Island, #3170) in
/// lock-step with the live trip/approach state — the iOS counterpart of
/// the Android PiP tile's data wiring in `TripRecordingBanner`.
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), so the sync runs no matter which route is
/// visible when the user backgrounds the app for their navigation app.
///
/// Watches the SAME sources the PiP tile renders from — the recorder
/// state, the effective approach state, the polling-radar fallback, the
/// effective fuel and the profile radius — builds one formatted
/// [LiveActivityContent] snapshot per emit and hands it to the
/// [LiveActivityCoordinator], which owns the start/update/end decision
/// and the ActivityKit cadence budget.
///
/// Every auxiliary watch is guarded exactly like the banner's PiP
/// watches (#2163): under a harness without the full graph the snapshot
/// degrades (no radar lead, default fuel) instead of crashing.

@ProviderFor(LiveActivitySync)
final liveActivitySyncProvider = LiveActivitySyncProvider._();

/// Keeps the iOS Live Activity (lock screen + Dynamic Island, #3170) in
/// lock-step with the live trip/approach state — the iOS counterpart of
/// the Android PiP tile's data wiring in `TripRecordingBanner`.
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), so the sync runs no matter which route is
/// visible when the user backgrounds the app for their navigation app.
///
/// Watches the SAME sources the PiP tile renders from — the recorder
/// state, the effective approach state, the polling-radar fallback, the
/// effective fuel and the profile radius — builds one formatted
/// [LiveActivityContent] snapshot per emit and hands it to the
/// [LiveActivityCoordinator], which owns the start/update/end decision
/// and the ActivityKit cadence budget.
///
/// Every auxiliary watch is guarded exactly like the banner's PiP
/// watches (#2163): under a harness without the full graph the snapshot
/// degrades (no radar lead, default fuel) instead of crashing.
final class LiveActivitySyncProvider
    extends $NotifierProvider<LiveActivitySync, void> {
  /// Keeps the iOS Live Activity (lock screen + Dynamic Island, #3170) in
  /// lock-step with the live trip/approach state — the iOS counterpart of
  /// the Android PiP tile's data wiring in `TripRecordingBanner`.
  ///
  /// Armed by `TripRecordingBanner` (which wraps every screen via
  /// `MaterialApp.builder`), so the sync runs no matter which route is
  /// visible when the user backgrounds the app for their navigation app.
  ///
  /// Watches the SAME sources the PiP tile renders from — the recorder
  /// state, the effective approach state, the polling-radar fallback, the
  /// effective fuel and the profile radius — builds one formatted
  /// [LiveActivityContent] snapshot per emit and hands it to the
  /// [LiveActivityCoordinator], which owns the start/update/end decision
  /// and the ActivityKit cadence budget.
  ///
  /// Every auxiliary watch is guarded exactly like the banner's PiP
  /// watches (#2163): under a harness without the full graph the snapshot
  /// degrades (no radar lead, default fuel) instead of crashing.
  LiveActivitySyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveActivitySyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveActivitySyncHash();

  @$internal
  @override
  LiveActivitySync create() => LiveActivitySync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$liveActivitySyncHash() => r'6b551cc8f221281a76fc2a30cddff113188293f1';

/// Keeps the iOS Live Activity (lock screen + Dynamic Island, #3170) in
/// lock-step with the live trip/approach state — the iOS counterpart of
/// the Android PiP tile's data wiring in `TripRecordingBanner`.
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), so the sync runs no matter which route is
/// visible when the user backgrounds the app for their navigation app.
///
/// Watches the SAME sources the PiP tile renders from — the recorder
/// state, the effective approach state, the polling-radar fallback, the
/// effective fuel and the profile radius — builds one formatted
/// [LiveActivityContent] snapshot per emit and hands it to the
/// [LiveActivityCoordinator], which owns the start/update/end decision
/// and the ActivityKit cadence budget.
///
/// Every auxiliary watch is guarded exactly like the banner's PiP
/// watches (#2163): under a harness without the full graph the snapshot
/// degrades (no radar lead, default fuel) instead of crashing.

abstract class _$LiveActivitySync extends $Notifier<void> {
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
