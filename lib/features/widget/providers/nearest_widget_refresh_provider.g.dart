// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearest_widget_refresh_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Foreground heartbeat that rebuilds the nearest home-screen widget every
/// [kNearestWidgetForegroundInterval].
///
/// WorkManager enforces a 15-minute floor on periodic tasks, so background
/// refresh alone can't meet the #609 target of "widget feels fresh". This
/// provider adds a foreground 2-minute tick that kicks the builder while
/// the app is running. When the app is backgrounded, the provider is
/// disposed by the framework; the background task takes over.
///
/// Reading the provider once (e.g. from the app's root widget) starts
/// the tick; the provider owns its own Timer and releases it in onDispose.

@ProviderFor(NearestWidgetRefresh)
final nearestWidgetRefreshProvider = NearestWidgetRefreshProvider._();

/// Foreground heartbeat that rebuilds the nearest home-screen widget every
/// [kNearestWidgetForegroundInterval].
///
/// WorkManager enforces a 15-minute floor on periodic tasks, so background
/// refresh alone can't meet the #609 target of "widget feels fresh". This
/// provider adds a foreground 2-minute tick that kicks the builder while
/// the app is running. When the app is backgrounded, the provider is
/// disposed by the framework; the background task takes over.
///
/// Reading the provider once (e.g. from the app's root widget) starts
/// the tick; the provider owns its own Timer and releases it in onDispose.
final class NearestWidgetRefreshProvider
    extends $NotifierProvider<NearestWidgetRefresh, void> {
  /// Foreground heartbeat that rebuilds the nearest home-screen widget every
  /// [kNearestWidgetForegroundInterval].
  ///
  /// WorkManager enforces a 15-minute floor on periodic tasks, so background
  /// refresh alone can't meet the #609 target of "widget feels fresh". This
  /// provider adds a foreground 2-minute tick that kicks the builder while
  /// the app is running. When the app is backgrounded, the provider is
  /// disposed by the framework; the background task takes over.
  ///
  /// Reading the provider once (e.g. from the app's root widget) starts
  /// the tick; the provider owns its own Timer and releases it in onDispose.
  NearestWidgetRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearestWidgetRefreshProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearestWidgetRefreshHash();

  @$internal
  @override
  NearestWidgetRefresh create() => NearestWidgetRefresh();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$nearestWidgetRefreshHash() =>
    r'4d4209e966c92c0919d9ff081c49fe34fb7c8f5c';

/// Foreground heartbeat that rebuilds the nearest home-screen widget every
/// [kNearestWidgetForegroundInterval].
///
/// WorkManager enforces a 15-minute floor on periodic tasks, so background
/// refresh alone can't meet the #609 target of "widget feels fresh". This
/// provider adds a foreground 2-minute tick that kicks the builder while
/// the app is running. When the app is backgrounded, the provider is
/// disposed by the framework; the background task takes over.
///
/// Reading the provider once (e.g. from the app's root widget) starts
/// the tick; the provider owns its own Timer and releases it in onDispose.

abstract class _$NearestWidgetRefresh extends $Notifier<void> {
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
