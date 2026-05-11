// Decodable mirror of the Dart-side widget row (see
// `lib/features/widget/data/home_widget_service.dart` /
// `nearest_widget_data_builder.dart`).
//
// Keep the JSON keys in lock-step with the Dart writer — the Android
// renderer (`StationWidgetRenderer.kt`) reads the same keys, and any
// drift between the three readers shows up as missing prices /
// distance-less rows in production. When a new field lands on Dart,
// add the same `CodingKey` here and on the Android side.

import Foundation

struct StationRow: Codable, Identifiable, Equatable {
    let id: String
    let brand: String?
    let name: String?
    let street: String?
    let postCode: String?
    let place: String?
    let e5: Double?
    let e10: Double?
    let diesel: Double?
    let preferredFuelCode: String?
    let preferredFuelPrice: Double?
    let distanceKm: Double?
    let isOpen: Bool?
    let currency: String?
    /// Pre-formatted price string (e.g. "1.45⁹ €"). The Dart layer
    /// formats it because the locale / currency / fractional-cent
    /// convention varies per country and we don't want to duplicate
    /// the rules in Swift.
    let priceFormatted: String?

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case name
        case street
        case postCode
        case place
        case e5
        case e10
        case diesel
        case preferredFuelCode = "preferred_fuel_code"
        case preferredFuelPrice = "preferred_fuel_price"
        case distanceKm = "distance_km"
        case isOpen
        case currency
        case priceFormatted
    }

    /// Convenience: best non-empty display label for the row. Mirrors
    /// the Dart `StationDisplay.displayName` ordering — brand wins
    /// when it isn't a generic "Station" placeholder; otherwise fall
    /// back to street, then place.
    var displayName: String {
        if let brand = brand,
           !brand.isEmpty,
           brand.lowercased() != "station",
           brand.lowercased() != "autoroute" {
            return brand
        }
        if let street = street, !street.isEmpty { return street }
        if let name = name, !name.isEmpty { return name }
        return place ?? id
    }

    /// `widgetURL(_:)` target — exact mirror of the Android
    /// `tankstellenwidget://station?id=<id>` PendingIntent URI the
    /// `StationWidgetRenderer` emits. The Flutter app's
    /// `widgetUriToPath` parses this scheme and routes to
    /// `/station/<id>` (or `/ev-station/<id>` for OCM-prefixed ids).
    var deepLink: URL {
        URL(string: "tankstellenwidget://station?id=\(id)")
            ?? URL(string: "tankstellenwidget://station")!
    }
}
