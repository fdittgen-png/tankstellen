// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Interactive AppIntent behind the widgets' refresh button (#3171,
// iOS 17+ — iOS 16 widgets are render-only, the button is simply not
// shown there).
//
// A widget extension has no network stack and no Dart runtime, so the
// intent cannot fetch fresh prices itself (unlike the Android
// ACTION_REFRESH broadcast, which enqueues the `widgetRefreshScan`
// WorkManager task — an OS capability iOS widgets don't have; see the
// issue's "refresh-triggered SCAN stays Android-only" note). What it CAN
// do, and does:
//
//   1. Write a manual-refresh request timestamp into the shared App-Group
//      store (`widget_manual_refresh_requested_at` — same key the Dart
//      foreground heartbeat reads, see
//      `lib/features/widget/data/impl/widget_reload_dispatcher.dart`).
//      The next heartbeat tick lets the request bypass the #3157
//      freshness/movement gate, so a running/next-opened app re-fetches
//      immediately — no new background wake-ups are added.
//   2. Reload every widget timeline so the views re-read whatever is in
//      the store right now (instant feedback when the host app already
//      wrote fresher data than the last timeline snapshot).

import AppIntents
import Foundation
import WidgetKit

@available(iOS 17.0, *)
struct WidgetRefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh prices"
    static var description = IntentDescription(
        "Re-reads the latest synced prices and asks Sparkilo to fetch fresh ones."
    )

    /// Keep in lock-step with `kWidgetManualRefreshRequestedAtKey` on the
    /// Dart side (`impl/widget_reload_dispatcher.dart`).
    static let manualRefreshKey = "widget_manual_refresh_requested_at"

    func perform() async throws -> some IntentResult {
        if let defaults = UserDefaults(suiteName: kTankstellenAppGroupId) {
            defaults.set(
                ISO8601DateFormatter().string(from: Date()),
                forKey: Self.manualRefreshKey
            )
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
