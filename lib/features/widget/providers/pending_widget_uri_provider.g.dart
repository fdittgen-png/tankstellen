// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_widget_uri_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot stash for the URI a home-screen widget tap delivered to the
/// app on cold start.
///
/// Set by `AppInitializer.run()` right after the [ProviderContainer] is
/// created but BEFORE `runApp` — when the platform reports a non-null
/// `HomeWidget.initiallyLaunchedFromHomeWidget()` value, we save it
/// here so the very first redirect pass on the router can consume it
/// and navigate directly to the matching station detail.
///
/// Without this stash the cold-start flow visibly flashed the landing
/// screen for the duration of the redirect chain, and racing
/// post-frame callbacks could lose the deep link entirely (the user's
/// repro on #widget-deeplink). The stash makes the destination
/// authoritative from the first frame the router paints.
///
/// **Lifecycle**: `set(uri)` writes; `consume()` returns the current
/// value and clears the field in the same call so subsequent redirect
/// evaluations don't keep re-routing back to the same station. Warm
/// clicks go through `home_widget`'s `widgetClicked` stream — they do
/// NOT touch this provider.

@ProviderFor(PendingWidgetUri)
final pendingWidgetUriProvider = PendingWidgetUriProvider._();

/// One-shot stash for the URI a home-screen widget tap delivered to the
/// app on cold start.
///
/// Set by `AppInitializer.run()` right after the [ProviderContainer] is
/// created but BEFORE `runApp` — when the platform reports a non-null
/// `HomeWidget.initiallyLaunchedFromHomeWidget()` value, we save it
/// here so the very first redirect pass on the router can consume it
/// and navigate directly to the matching station detail.
///
/// Without this stash the cold-start flow visibly flashed the landing
/// screen for the duration of the redirect chain, and racing
/// post-frame callbacks could lose the deep link entirely (the user's
/// repro on #widget-deeplink). The stash makes the destination
/// authoritative from the first frame the router paints.
///
/// **Lifecycle**: `set(uri)` writes; `consume()` returns the current
/// value and clears the field in the same call so subsequent redirect
/// evaluations don't keep re-routing back to the same station. Warm
/// clicks go through `home_widget`'s `widgetClicked` stream — they do
/// NOT touch this provider.
final class PendingWidgetUriProvider
    extends $NotifierProvider<PendingWidgetUri, Uri?> {
  /// One-shot stash for the URI a home-screen widget tap delivered to the
  /// app on cold start.
  ///
  /// Set by `AppInitializer.run()` right after the [ProviderContainer] is
  /// created but BEFORE `runApp` — when the platform reports a non-null
  /// `HomeWidget.initiallyLaunchedFromHomeWidget()` value, we save it
  /// here so the very first redirect pass on the router can consume it
  /// and navigate directly to the matching station detail.
  ///
  /// Without this stash the cold-start flow visibly flashed the landing
  /// screen for the duration of the redirect chain, and racing
  /// post-frame callbacks could lose the deep link entirely (the user's
  /// repro on #widget-deeplink). The stash makes the destination
  /// authoritative from the first frame the router paints.
  ///
  /// **Lifecycle**: `set(uri)` writes; `consume()` returns the current
  /// value and clears the field in the same call so subsequent redirect
  /// evaluations don't keep re-routing back to the same station. Warm
  /// clicks go through `home_widget`'s `widgetClicked` stream — they do
  /// NOT touch this provider.
  PendingWidgetUriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingWidgetUriProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingWidgetUriHash();

  @$internal
  @override
  PendingWidgetUri create() => PendingWidgetUri();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uri? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uri?>(value),
    );
  }
}

String _$pendingWidgetUriHash() => r'c59e2978fe9e947372c3282738f813b78a4fd6d3';

/// One-shot stash for the URI a home-screen widget tap delivered to the
/// app on cold start.
///
/// Set by `AppInitializer.run()` right after the [ProviderContainer] is
/// created but BEFORE `runApp` — when the platform reports a non-null
/// `HomeWidget.initiallyLaunchedFromHomeWidget()` value, we save it
/// here so the very first redirect pass on the router can consume it
/// and navigate directly to the matching station detail.
///
/// Without this stash the cold-start flow visibly flashed the landing
/// screen for the duration of the redirect chain, and racing
/// post-frame callbacks could lose the deep link entirely (the user's
/// repro on #widget-deeplink). The stash makes the destination
/// authoritative from the first frame the router paints.
///
/// **Lifecycle**: `set(uri)` writes; `consume()` returns the current
/// value and clears the field in the same call so subsequent redirect
/// evaluations don't keep re-routing back to the same station. Warm
/// clicks go through `home_widget`'s `widgetClicked` stream — they do
/// NOT touch this provider.

abstract class _$PendingWidgetUri extends $Notifier<Uri?> {
  Uri? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Uri?, Uri?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Uri?, Uri?>,
              Uri?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
