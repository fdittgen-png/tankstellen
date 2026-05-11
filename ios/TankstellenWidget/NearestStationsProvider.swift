// TimelineProvider that reads the latest Nearest-Stations payload from
// the shared App Group container.
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
        let entry = currentEntry()
        let nextRefresh = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: entry.date
        ) ?? entry.date.addingTimeInterval(15 * 60)
        completion(
            Timeline(entries: [entry], policy: .after(nextRefresh))
        )
    }

    // MARK: - private

    private func currentEntry() -> Entry {
        let defaults = UserDefaults(suiteName: kTankstellenAppGroupId)
        guard let defaults = defaults else {
            return NearestStationsEntry.empty(
                reason: "App Group not configured"
            )
        }
        // The Dart side writes the rows as a JSON-encoded string under
        // the `nearest_json` key (see `HomeWidgetService.updateWidget`).
        // If the key is missing the host app has never run, never
        // resolved a location, or never had any nearby results — the
        // empty-reason copy disambiguates the latter two.
        guard let raw = defaults.string(forKey: "nearest_json") else {
            return NearestStationsEntry.empty(
                reason: defaults.string(forKey: "nearest_empty_reason")
                    ?? "Open Sparkilo to load nearby prices"
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
                    reason: defaults.string(forKey: "nearest_empty_reason")
                        ?? "No nearby stations"
                )
            }
            return NearestStationsEntry(
                date: Date(),
                rows: rows,
                isStale: defaults.bool(forKey: "nearest_is_stale"),
                emptyReason: nil
            )
        } catch {
            return NearestStationsEntry.empty(
                reason: "Couldn't read widget data"
            )
        }
    }
}
