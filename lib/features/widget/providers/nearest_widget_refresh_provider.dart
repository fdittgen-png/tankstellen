// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/service_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../price_history/providers/price_prediction_provider.dart';
import '../data/home_widget_service.dart';
import '../../../core/logging/error_logger.dart';

part 'nearest_widget_refresh_provider.g.dart';

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
@Riverpod(keepAlive: true)
class NearestWidgetRefresh extends _$NearestWidgetRefresh {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    _timer ??= Timer.periodic(
      kNearestWidgetForegroundInterval,
      (_) => _tick(),
    );
    // #1803 — refresh again whenever the app returns to the foreground,
    // so the widget's refresh button (which opens the app, #1801) and
    // any ordinary resume leave the widget up to date.
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(_tick()));
    // Fire one immediate refresh so the widget reflects the current
    // session as soon as the user opens the app (don't wait two minutes).
    unawaited(_tick());
  }

  Future<void> _tick() async {
    try {
      final storage = ref.read(storageRepositoryProvider);
      final stationService = ref.read(stationServiceProvider);
      // #1803 — refresh the favorites variant too. It's a cheap local
      // read (favorite ids + their stored prices, no network), so
      // running it on every tick keeps the favorites widget from going
      // stale between favorites edits.
      await HomeWidgetService.updateWidget(
        storage,
        profileStorage: storage,
        settingsStorage: storage,
        pricePredictor: (stationId, fuelType) => ref.read(
          pricePredictionProvider(stationId, fuelType),
        ),
      );
      await HomeWidgetService.updateNearestWidget(
        storage,
        storage,
        profileStorage: storage,
        stationService: stationService,
        // Wire the on-device predictor (#1121). Reads through the same
        // Riverpod provider the in-app `BestTimeBanner` uses, so the
        // widget shows the same recommendation without any new background
        // work — it just runs while the foreground tick is alive.
        pricePredictor: (stationId, fuelType) => ref.read(
          pricePredictionProvider(stationId, fuelType),
        ),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'NearestWidgetRefresh: tick failed'}));
    }
  }
}

/// Foreground refresh interval. Kept short so the nearest widget stays
/// responsive while the app is open; the background WorkManager task
/// handles longer-term refreshes under Android's 15-minute floor.
const Duration kNearestWidgetForegroundInterval = Duration(minutes: 2);
