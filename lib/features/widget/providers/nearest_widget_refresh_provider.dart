import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/service_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/home_widget_service.dart';

part 'nearest_widget_refresh_provider.g.dart';

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
@Riverpod(keepAlive: true)
class NearestWidgetRefresh extends _$NearestWidgetRefresh {
  Timer? _timer;

  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer ??= Timer.periodic(
      kNearestWidgetForegroundInterval,
      (_) => _tick(),
    );
    // Fire one immediate refresh so the widget reflects the current
    // session as soon as the user opens the app (don't wait two minutes).
    unawaited(_tick());
  }

  Future<void> _tick() async {
    try {
      final storage = ref.read(storageRepositoryProvider);
      final stationService = ref.read(stationServiceProvider);
      await HomeWidgetService.updateNearestWidget(
        storage,
        storage,
        profileStorage: storage,
        stationService: stationService,
      );
    } catch (e, st) {
      debugPrint('NearestWidgetRefresh: tick failed: $e\n$st');
    }
  }
}

/// Foreground refresh interval. Kept short so the nearest widget stays
/// responsive while the app is open; the background WorkManager task
/// handles longer-term refreshes under Android's 15-minute floor.
const Duration kNearestWidgetForegroundInterval = Duration(minutes: 2);
