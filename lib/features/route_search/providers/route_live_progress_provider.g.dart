// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'route_live_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A non-recording, lifecycle-owned position listener for the route
/// results on screen (#4432).
///
/// While a CURRENT-LOCATION route is visible, each accepted foreground
/// fix moves a [RouteProgressTracker] along that route: passed stops
/// retire (with its hysteresis, so they never flicker back) and leaving
/// the route is detected. No fix ever triggers a routing request; the
/// surfaces offer "Update route from your position" instead.
///
/// ## Ownership
///
/// * Auto-dispose: the subscription lives only while a route surface
///   watches this provider, and is cancelled in `onDispose`.
/// * The surface calls [pause] when it is hidden (an offstage tab) or
///   the app is backgrounded, and [resume] when it is shown again.
/// * It joins the SHARED position source (#2646) as a non-recording
///   consumer with the light on-search radar profile, so it never
///   reconfigures an active trip recording, and the source's refcount
///   closes the platform stream when the last listener leaves.
/// * The source replays its latest fix to late joiners; each fix is
///   validated with the route-origin freshness/accuracy policy
///   ([acceptAsCurrentFix]) before it moves anything.

@ProviderFor(RouteLiveProgressController)
final routeLiveProgressControllerProvider =
    RouteLiveProgressControllerProvider._();

/// A non-recording, lifecycle-owned position listener for the route
/// results on screen (#4432).
///
/// While a CURRENT-LOCATION route is visible, each accepted foreground
/// fix moves a [RouteProgressTracker] along that route: passed stops
/// retire (with its hysteresis, so they never flicker back) and leaving
/// the route is detected. No fix ever triggers a routing request; the
/// surfaces offer "Update route from your position" instead.
///
/// ## Ownership
///
/// * Auto-dispose: the subscription lives only while a route surface
///   watches this provider, and is cancelled in `onDispose`.
/// * The surface calls [pause] when it is hidden (an offstage tab) or
///   the app is backgrounded, and [resume] when it is shown again.
/// * It joins the SHARED position source (#2646) as a non-recording
///   consumer with the light on-search radar profile, so it never
///   reconfigures an active trip recording, and the source's refcount
///   closes the platform stream when the last listener leaves.
/// * The source replays its latest fix to late joiners; each fix is
///   validated with the route-origin freshness/accuracy policy
///   ([acceptAsCurrentFix]) before it moves anything.
final class RouteLiveProgressControllerProvider
    extends $NotifierProvider<RouteLiveProgressController, RouteLiveProgress> {
  /// A non-recording, lifecycle-owned position listener for the route
  /// results on screen (#4432).
  ///
  /// While a CURRENT-LOCATION route is visible, each accepted foreground
  /// fix moves a [RouteProgressTracker] along that route: passed stops
  /// retire (with its hysteresis, so they never flicker back) and leaving
  /// the route is detected. No fix ever triggers a routing request; the
  /// surfaces offer "Update route from your position" instead.
  ///
  /// ## Ownership
  ///
  /// * Auto-dispose: the subscription lives only while a route surface
  ///   watches this provider, and is cancelled in `onDispose`.
  /// * The surface calls [pause] when it is hidden (an offstage tab) or
  ///   the app is backgrounded, and [resume] when it is shown again.
  /// * It joins the SHARED position source (#2646) as a non-recording
  ///   consumer with the light on-search radar profile, so it never
  ///   reconfigures an active trip recording, and the source's refcount
  ///   closes the platform stream when the last listener leaves.
  /// * The source replays its latest fix to late joiners; each fix is
  ///   validated with the route-origin freshness/accuracy policy
  ///   ([acceptAsCurrentFix]) before it moves anything.
  RouteLiveProgressControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeLiveProgressControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeLiveProgressControllerHash();

  @$internal
  @override
  RouteLiveProgressController create() => RouteLiveProgressController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteLiveProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteLiveProgress>(value),
    );
  }
}

String _$routeLiveProgressControllerHash() =>
    r'4a3c75200a386252780ff90b858f0b2bac453767';

/// A non-recording, lifecycle-owned position listener for the route
/// results on screen (#4432).
///
/// While a CURRENT-LOCATION route is visible, each accepted foreground
/// fix moves a [RouteProgressTracker] along that route: passed stops
/// retire (with its hysteresis, so they never flicker back) and leaving
/// the route is detected. No fix ever triggers a routing request; the
/// surfaces offer "Update route from your position" instead.
///
/// ## Ownership
///
/// * Auto-dispose: the subscription lives only while a route surface
///   watches this provider, and is cancelled in `onDispose`.
/// * The surface calls [pause] when it is hidden (an offstage tab) or
///   the app is backgrounded, and [resume] when it is shown again.
/// * It joins the SHARED position source (#2646) as a non-recording
///   consumer with the light on-search radar profile, so it never
///   reconfigures an active trip recording, and the source's refcount
///   closes the platform stream when the last listener leaves.
/// * The source replays its latest fix to late joiners; each fix is
///   validated with the route-origin freshness/accuracy policy
///   ([acceptAsCurrentFix]) before it moves anything.

abstract class _$RouteLiveProgressController
    extends $Notifier<RouteLiveProgress> {
  RouteLiveProgress build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RouteLiveProgress, RouteLiveProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RouteLiveProgress, RouteLiveProgress>,
              RouteLiveProgress,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
