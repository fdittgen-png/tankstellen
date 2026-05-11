import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_widget_uri_provider.g.dart';

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
@Riverpod(keepAlive: true)
class PendingWidgetUri extends _$PendingWidgetUri {
  @override
  Uri? build() => null;

  /// Stores [uri] (or clears the stash when [uri] is `null`).
  void set(Uri? uri) {
    state = uri;
  }

  /// Returns the pending URI and clears the stash atomically. Returning
  /// `null` means there was nothing pending — callers should fall back
  /// to their default behaviour.
  Uri? consume() {
    final pending = state;
    if (pending != null) state = null;
    return pending;
  }

  /// Same contract as [consume] but defers the state mutation to a
  /// microtask so callers can safely invoke it from inside a widget
  /// build / Router redirect / other Riverpod-locked phase. Riverpod
  /// asserts when state is mutated while the widget tree is building;
  /// this helper sidesteps that without forcing the caller to wrap the
  /// call in `Future.microtask` itself.
  Uri? consumeDeferred() {
    final pending = state;
    if (pending != null) {
      Future.microtask(() => state = null);
    }
    return pending;
  }
}
