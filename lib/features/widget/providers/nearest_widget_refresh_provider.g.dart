// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearest_widget_refresh_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Foreground heartbeat that rebuilds the home-screen widget — both the
/// favorites and the nearest variants — every
/// [kNearestWidgetForegroundInterval], once immediately on app open,
/// and again whenever the app returns to the foreground (#1803).
///
/// WorkManager enforces a 15-minute floor on periodic tasks, so background
/// refresh alone can't meet the #609 target of "widget feels fresh". This
/// provider adds a foreground 2-minute tick that kicks the builder while
/// the app is running.
///
/// #1803 — the resume hook keeps the widget fresh whenever the app
/// returns to the foreground. #2600 — the widget's own refresh button no
/// longer launches the app: it is a native broadcast that re-fetches
/// prices in place (`FuelPriceWidgetProvider.ACTION_REFRESH` → the
/// `widgetRefreshScan` WorkManager task), so the former explicit
/// `refresh()` entry point this provider exposed was removed.
///
/// Reading the provider once (e.g. from the app's root widget) starts
/// the tick; the provider owns its Timer + [AppLifecycleListener] and
/// releases both in onDispose.

@ProviderFor(NearestWidgetRefresh)
final nearestWidgetRefreshProvider = NearestWidgetRefreshProvider._();

/// Foreground heartbeat that rebuilds the home-screen widget — both the
/// favorites and the nearest variants — every
/// [kNearestWidgetForegroundInterval], once immediately on app open,
/// and again whenever the app returns to the foreground (#1803).
///
/// WorkManager enforces a 15-minute floor on periodic tasks, so background
/// refresh alone can't meet the #609 target of "widget feels fresh". This
/// provider adds a foreground 2-minute tick that kicks the builder while
/// the app is running.
///
/// #1803 — the resume hook keeps the widget fresh whenever the app
/// returns to the foreground. #2600 — the widget's own refresh button no
/// longer launches the app: it is a native broadcast that re-fetches
/// prices in place (`FuelPriceWidgetProvider.ACTION_REFRESH` → the
/// `widgetRefreshScan` WorkManager task), so the former explicit
/// `refresh()` entry point this provider exposed was removed.
///
/// Reading the provider once (e.g. from the app's root widget) starts
/// the tick; the provider owns its Timer + [AppLifecycleListener] and
/// releases both in onDispose.
final class NearestWidgetRefreshProvider
    extends $NotifierProvider<NearestWidgetRefresh, void> {
  /// Foreground heartbeat that rebuilds the home-screen widget — both the
  /// favorites and the nearest variants — every
  /// [kNearestWidgetForegroundInterval], once immediately on app open,
  /// and again whenever the app returns to the foreground (#1803).
  ///
  /// WorkManager enforces a 15-minute floor on periodic tasks, so background
  /// refresh alone can't meet the #609 target of "widget feels fresh". This
  /// provider adds a foreground 2-minute tick that kicks the builder while
  /// the app is running.
  ///
  /// #1803 — the resume hook keeps the widget fresh whenever the app
  /// returns to the foreground. #2600 — the widget's own refresh button no
  /// longer launches the app: it is a native broadcast that re-fetches
  /// prices in place (`FuelPriceWidgetProvider.ACTION_REFRESH` → the
  /// `widgetRefreshScan` WorkManager task), so the former explicit
  /// `refresh()` entry point this provider exposed was removed.
  ///
  /// Reading the provider once (e.g. from the app's root widget) starts
  /// the tick; the provider owns its Timer + [AppLifecycleListener] and
  /// releases both in onDispose.
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
    r'2f266f61976160afb58de2ba78898124e1aa79e8';

/// Foreground heartbeat that rebuilds the home-screen widget — both the
/// favorites and the nearest variants — every
/// [kNearestWidgetForegroundInterval], once immediately on app open,
/// and again whenever the app returns to the foreground (#1803).
///
/// WorkManager enforces a 15-minute floor on periodic tasks, so background
/// refresh alone can't meet the #609 target of "widget feels fresh". This
/// provider adds a foreground 2-minute tick that kicks the builder while
/// the app is running.
///
/// #1803 — the resume hook keeps the widget fresh whenever the app
/// returns to the foreground. #2600 — the widget's own refresh button no
/// longer launches the app: it is a native broadcast that re-fetches
/// prices in place (`FuelPriceWidgetProvider.ACTION_REFRESH` → the
/// `widgetRefreshScan` WorkManager task), so the former explicit
/// `refresh()` entry point this provider exposed was removed.
///
/// Reading the provider once (e.g. from the app's root widget) starts
/// the tick; the provider owns its Timer + [AppLifecycleListener] and
/// releases both in onDispose.

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
