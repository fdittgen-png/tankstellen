// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_manager.dart' show CacheKey, CacheTtl;
import '../../../core/data/storage_repository.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/storage/storage_keys.dart';
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

  /// #3157 — when the last nearest-widget network refresh completed, and
  /// the cache-key-rounded position it ran for. A periodic/resume tick is
  /// skipped while the last refresh is younger than the search cache TTL
  /// AND the stored position hasn't left its cache-key cell — the search
  /// would only re-serve the same cached result, so the heartbeat was
  /// burning a station search every 2 minutes for nothing. The first tick
  /// after arming always runs (`_lastNearestRefreshAt == null`).
  DateTime? _lastNearestRefreshAt;
  String? _lastNearestRefreshPosKey;

  /// #3157 — injectable clock so the freshness gate is testable without
  /// waiting out the real TTL. Production never touches it.
  @visibleForTesting
  DateTime Function() debugNow = DateTime.now;

  /// #3157 — drive one tick directly in tests (the periodic timer's
  /// 2-minute cadence is impractical to wait for).
  @visibleForTesting
  Future<void> debugTick() => _tick();

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
      // #2703 — the nearest-widget refresh hits the network (the active
      // country's StationService). When the device is offline the call is
      // doomed and ERROR-logged (the field-log offline home-widget refresh),
      // so skip it silently — the favorites variant above is a local-only
      // read and still ran. The existing stale-fallback in
      // NearestWidgetDataBuilder remains the safety net once we DO refresh.
      final isOnline = await ref.read(currentConnectivityProvider.future);
      if (!isOnline) return;
      // #3157 — freshness/movement gate: skip the network refresh while the
      // last successful one is younger than the search cache TTL and the
      // stored position is still inside the same cache-key cell (the same
      // rounding `CacheKey.stationSearch` uses) — the search chain would
      // only re-serve its cached result anyway.
      final posKey = _positionCellKey(storage);
      final last = _lastNearestRefreshAt;
      if (last != null &&
          debugNow().difference(last) < CacheTtl.stationSearch &&
          posKey == _lastNearestRefreshPosKey) {
        return;
      }
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
      // #3157 — record the completed refresh + the cell it ran for.
      _lastNearestRefreshAt = debugNow();
      _lastNearestRefreshPosKey = posKey;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'NearestWidgetRefresh: tick failed'}));
    }
  }

  /// The cache-key cell the stored user position falls into, using the
  /// SAME 3-decimal rounding as [CacheKey.stationSearch] (#3157). Null when
  /// no position is stored yet (the no-GPS empty state) — a null-to-null
  /// comparison still counts as "not moved", which is correct: with no fix
  /// the nearest builder can only re-render the same no-GPS placeholder.
  String? _positionCellKey(StorageRepository storage) {
    final lat = storage.getSetting(StorageKeys.userPositionLat) as double?;
    final lng = storage.getSetting(StorageKeys.userPositionLng) as double?;
    if (lat == null || lng == null) return null;
    return '${CacheKey.roundedSearchCoord(lat)}'
        ':${CacheKey.roundedSearchCoord(lng)}';
  }
}

/// Foreground refresh interval. Kept short so the nearest widget stays
/// responsive while the app is open; the background WorkManager task
/// handles longer-term refreshes under Android's 15-minute floor.
const Duration kNearestWidgetForegroundInterval = Duration(minutes: 2);
