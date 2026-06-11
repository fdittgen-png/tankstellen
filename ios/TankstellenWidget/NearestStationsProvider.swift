// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// TimelineProvider that reads the latest Nearest-Stations payload from
// the shared App Group container, plus the shared payload loader the
// Favorites provider reuses (#3171).
//
// Refresh cadence: the host app updates the container whenever a new
// search resolves (typically every few minutes when the app is open).
// We schedule a `Timeline` reload every 15 minutes from the last entry
// so the widget refreshes even when the host hasn't run — WidgetKit
// budgets ~40 reloads per day so 15 minutes is comfortably under the
// throttle ceiling.

import Foundation
import WidgetKit

/// App Group identifier — MUST match the one declared in
/// `Runner.entitlements` and `TankstellenWidget.entitlements`, AND the
/// `_iosGroupId` constant on the Dart side
/// (`lib/features/widget/data/home_widget_service.dart`). All three
/// strings break together; keep them in lock-step.
let kTankstellenAppGroupId = "group.de.tankstellen.tankstellen"

/// Shared App-Group payload loader for the station-list widgets (#3171).
/// The Nearest widget reads the `nearest_*` keys, the Favorites widget the
/// `stations_json` / favorites keys — same JSON row shape (`StationRow`),
/// so one decode path serves both providers.
enum StationListPayload {
    /// Read + decode one station-list payload from the App Group store.
    ///
    /// - `jsonKey`: the UserDefaults key holding the JSON-encoded rows.
    /// - `emptyReasonKey`: optional key with a Dart-written empty-reason
    ///   code; nil when the payload has no reason concept (favorites).
    /// - `staleKey`: optional key with the Dart-written stale flag; nil
    ///   when the payload has no stale concept (favorites).
    /// - `noDataCopy` / `emptyListCopy`: the fallback texts for "host app
    ///   never wrote this key" vs "key exists but the list is empty".
    static func loadEntry(
        jsonKey: String,
        emptyReasonKey: String?,
        staleKey: String?,
        noDataCopy: String,
        emptyListCopy: String
    ) -> NearestStationsEntry {
        guard let defaults = UserDefaults(suiteName: kTankstellenAppGroupId) else {
            return NearestStationsEntry.empty(
                reason: "App Group not configured"
            )
        }
        // The Dart side writes the rows as a JSON-encoded string (see
        // `HomeWidgetService` / `NearestWidgetDataBuilder`). A missing key
        // means the host app has never run / never produced this payload.
        guard let raw = defaults.string(forKey: jsonKey) else {
            return NearestStationsEntry.empty(
                reason: emptyReason(defaults, key: emptyReasonKey)
                    ?? noDataCopy
            )
        }
        guard let data = raw.data(using: .utf8) else {
            return NearestStationsEntry.empty(
                reason: "Couldn't decode widget data"
            )
        }
        do {
            let rows = try JSONDecoder().decode([StationRow].self, from: data)
            if rows.isEmpty {
                return NearestStationsEntry.empty(
                    reason: emptyReason(defaults, key: emptyReasonKey)
                        ?? emptyListCopy
                )
            }
            return NearestStationsEntry(
                date: Date(),
                rows: rows,
                isStale: staleKey.map { defaults.bool(forKey: $0) } ?? false,
                emptyReason: nil
            )
        } catch {
            return NearestStationsEntry.empty(
                reason: "Couldn't read widget data"
            )
        }
    }

    /// 15-minute `.after` reload policy shared by every provider in the
    /// bundle — see the cadence note in the file header.
    static func timeline(for entry: NearestStationsEntry) -> Timeline<NearestStationsEntry> {
        let nextRefresh = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: entry.date
        ) ?? entry.date.addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    /// Map the Dart-written empty-reason CODE to user copy. The Dart side
    /// writes machine codes (`no_gps`, `no_network`, `no_favorites` — see
    /// `NearestWidgetDataBuilder` / `HomeWidgetService`); the Android
    /// renderer maps them the same way. Unknown non-empty values are shown
    /// verbatim (forward compatibility with future Dart-localized copy).
    private static func emptyReason(
        _ defaults: UserDefaults,
        key: String?
    ) -> String? {
        guard let key = key,
              let code = defaults.string(forKey: key),
              !code.isEmpty else { return nil }
        switch code {
        case "no_gps":
            return "Turn on location in the app to see nearby stations"
        case "no_network":
            return "Open Sparkilo to load nearby prices"
        case "no_favorites":
            return "Add favorite stations in Sparkilo to see them here"
        default:
            return code
        }
    }
}

struct NearestStationsProvider: TimelineProvider {
    typealias Entry = NearestStationsEntry

    func placeholder(in context: Context) -> Entry {
        NearestStationsEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> Void
    ) {
        completion(StationListPayload.timeline(for: currentEntry()))
    }

    // MARK: - private

    private func currentEntry() -> Entry {
        StationListPayload.loadEntry(
            jsonKey: "nearest_json",
            emptyReasonKey: "nearest_empty_reason",
            staleKey: "nearest_is_stale",
            noDataCopy: "Open Sparkilo to load nearby prices",
            emptyListCopy: "No nearby stations"
        )
    }
}
