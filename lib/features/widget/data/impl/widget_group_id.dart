// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io' show Platform;

/// Platform-correct home-widget data scope (#3172, epic #2332 burn-down —
/// the last inline `Platform.isIOS` in `home_widget_service.dart`, moved
/// here so the fork lives in `impl/` like `widget_reload_dispatcher.dart`).
/// The same `HomeWidget.saveWidgetData` call goes through this string —
/// Android treats it as the prefs file name, iOS as a
/// `UserDefaults(suiteName:)` argument backed by the App Group container.

/// Android: the SharedPreferences file the `home_widget` plugin writes
/// to. Must match the prefs file that `StationWidgetRenderer.kt` reads
/// — keep the two literals in lock-step.
const String _androidWidgetGroupId = 'de.tankstellen.fuelprices.widget';

/// iOS: the App Group identifier the WidgetKit extension shares with
/// the host app. MUST start with `group.` (Apple convention) and
/// match the entitlements on BOTH targets:
/// - `ios/Runner/Runner.entitlements`
/// - `ios/TankstellenWidget/TankstellenWidget.entitlements`
/// — and `kTankstellenAppGroupId` in
/// `ios/TankstellenWidget/NearestStationsProvider.swift`. All four
/// strings break together; keep them in lock-step.
const String _iosWidgetGroupId = 'group.de.tankstellen.tankstellen';

/// The widget-data scope for the running platform.
String get platformWidgetGroupId =>
    Platform.isIOS ? _iosWidgetGroupId : _androidWidgetGroupId;
