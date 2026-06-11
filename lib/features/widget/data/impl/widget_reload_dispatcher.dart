// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Platform dispatch for the "tell the native home-screen widgets to
/// re-render" step (#3171). Lives in `impl/` per the plugin-pattern rule
/// (#2350) — this is the one place the widget feature branches on the
/// runtime platform.
///
/// #2206 — the Android AppWidgetProvider lives in the Gradle **namespace**
/// `de.tankstellen.tankstellen` (the manifest `.FuelPriceWidgetProvider`
/// receiver), which differs from the **applicationId**
/// `de.tankstellen.fuelprices`. home_widget's `updateWidget` resolves the
/// short `androidName` against the applicationId
/// (`${packageName}.${androidName}`), so it looked for
/// `de.tankstellen.fuelprices.FuelPriceWidgetProvider` and threw
/// `ClassNotFoundException` on every update.
///
/// home_widget 0.9.2+ resolves the provider class as
/// `Class.forName(qualifiedAndroidName ?? "${packageName}.${androidName}")`
/// — when `qualifiedAndroidName` is non-null it is used **as-is** and the
/// short name is ignored for resolution. BUT the plugin's
/// `ClassNotFoundException` message always prints the SHORT `androidName`
/// ("No Widget found with Name FuelPriceWidgetProvider"), which made the
/// device log misleading. We therefore pass ONLY the fully-qualified name
/// (no short `androidName`), so the qualified class is always resolved and
/// a future failure message reports `null` rather than the wrong short
/// name. (#2207 field follow-up.)
// i18n-ignore: Android class identifier, not user-facing text.
const kWidgetQualifiedAndroidName =
    'de.tankstellen.tankstellen.FuelPriceWidgetProvider';

/// WidgetKit `kind` strings of every widget in the iOS
/// `TankstellenWidgetBundle` (#3171). MUST stay in lock-step with the
/// `kind` literals in `ios/TankstellenWidget/TankstellenWidget.swift` —
/// home_widget's iOS `updateWidget` maps each name straight to
/// `WidgetCenter.reloadTimelines(ofKind:)`, so a missing/misspelled entry
/// means that widget silently stops refreshing when the Dart side writes
/// new data.
// i18n-ignore: WidgetKit kind identifiers, not user-facing text.
const kIosWidgetKinds = <String>[
  'NearestStationsWidget',
  'FavoriteStationsWidget',
  'PredictiveStationsWidget',
];

/// App-Group UserDefaults key the iOS widget's AppIntent refresh button
/// (iOS 17+, #3171) writes an ISO-8601 timestamp to. The Dart foreground
/// heartbeat reads it and lets a request newer than the last completed
/// refresh bypass the #3157 freshness/movement gate — no new wake-ups,
/// the nudge is consumed by the existing 2-minute tick. Keep in lock-step
/// with `kWidgetManualRefreshRequestedAtKey` in
/// `ios/TankstellenWidget/WidgetRefreshIntent.swift`.
// i18n-ignore: storage key, not user-facing text.
const kWidgetManualRefreshRequestedAtKey =
    'widget_manual_refresh_requested_at';

/// Test seam: forces [notifyNativeWidgets] down the iOS (`true`) or
/// Android (`false`) branch regardless of the host platform, so both
/// dispatch shapes are assertable from a desktop test runner. Production
/// never sets it.
@visibleForTesting
bool? debugNotifyNativeWidgetsIsIos;

/// Ask the native side to re-render every home-screen widget after the
/// Dart writers have updated the shared store.
///
/// - **Android** — one `updateWidget` with the fully-qualified provider
///   class (#2206); the single `FuelPriceWidgetProvider` renders every
///   mode/variant itself.
/// - **iOS** — one `reloadTimelines(ofKind:)` per WidgetKit kind in
///   [kIosWidgetKinds] (#3171). The home_widget iOS plugin REQUIRES a
///   name: the previous Android-only call surfaced as a benign-looking
///   `PlatformException(-3)` and no iOS widget ever reloaded off a Dart
///   write — they coasted on their own 15-minute timeline policy.
Future<void> notifyNativeWidgets() async {
  final isIos =
      debugNotifyNativeWidgetsIsIos ?? (!kIsWeb && Platform.isIOS);
  if (isIos) {
    for (final kind in kIosWidgetKinds) {
      await HomeWidget.updateWidget(iOSName: kind);
    }
    return;
  }
  await HomeWidget.updateWidget(
    qualifiedAndroidName: kWidgetQualifiedAndroidName,
  );
}
