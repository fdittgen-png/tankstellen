// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
    /// #2600 / #3171 — true on the cheapest priced row(s) of the rendered
    /// set; the views colour that price green (mirrors the Android
    /// renderer's `widget_price_cheap`).
    let isCheapest: Bool?
    /// #1121 / #3171 — predictive "best time to fill" fields the Dart side
    /// attaches per row when the on-device predictor has an actionable
    /// forecast (see `buildPredictivePayload` in
    /// `lib/features/widget/data/predictive_payload.dart`). All nil when
    /// the prediction isn't actionable — the row then falls back to the
    /// default price-only appearance, same rule as
    /// `StationWidgetRenderer.kt`'s VARIANT_PREDICTIVE branch.
    let predictiveBestLabel: String?
    let predictiveBestPrice: Double?

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
        case isCheapest
        case predictiveBestLabel = "predictive_best_label"
        case predictiveBestPrice = "predictive_best_price"
    }

    /// Decode-only alias (#3171): the nearest real-search payload writes
    /// the camelCase `distanceKm` while the favorites payload writes the
    /// legacy snake_case `distance_km` — the Kotlin renderer reads both,
    /// and so must we (the snake-only decode silently dropped the distance
    /// pill on every real-search row).
    private enum LegacyKeys: String, CodingKey {
        case distanceKm
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

    /// Best displayable price text + the currency symbol, or nil when the
    /// row has no usable price. Mirrors the Kotlin renderer's fallback
    /// chain (#3171 favorites parity): the Dart pre-formatted string wins
    /// (nearest payload), then the raw preferred-fuel double (favorites
    /// payload), then the e10 fallback.
    var displayPrice: String? {
        if let formatted = priceFormatted, !formatted.isEmpty {
            return appendCurrency(to: formatted)
        }
        if let price = preferredFuelPrice {
            return appendCurrency(to: String(format: "%.3f", price))
        }
        if let fallback = e10 {
            return appendCurrency(to: String(format: "%.3f", fallback))
        }
        return nil
    }

    /// The predictive second line, or nil when the Dart side attached no
    /// actionable forecast. Format mirrors `StationWidgetRenderer.kt`:
    /// "now 1.840 € · Prices typically drop Tuesday 6-8 PM ~1.790 €".
    var predictiveLine: String? {
        guard
            let label = predictiveBestLabel, !label.isEmpty,
            let bestPrice = predictiveBestPrice
        else { return nil }
        let best = appendCurrency(to: String(format: "%.3f", bestPrice))
        if let now = displayPrice {
            return "now \(now) · \(label) ~\(best)"
        }
        return "\(label) ~\(best)"
    }

    private func appendCurrency(to text: String) -> String {
        guard let currency = currency, !currency.isEmpty else { return text }
        return "\(text) \(currency)"
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

extension StationRow {
    /// Custom decode so the snake/camel distance aliases both land in
    /// [distanceKm]. Everything else is a plain `decodeIfPresent` mirror
    /// of the synthesized decoder. (Lives in an extension so the
    /// memberwise initializer the placeholder entries use stays
    /// synthesized.)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        brand = try c.decodeIfPresent(String.self, forKey: .brand)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        street = try c.decodeIfPresent(String.self, forKey: .street)
        postCode = try c.decodeIfPresent(String.self, forKey: .postCode)
        place = try c.decodeIfPresent(String.self, forKey: .place)
        e5 = try c.decodeIfPresent(Double.self, forKey: .e5)
        e10 = try c.decodeIfPresent(Double.self, forKey: .e10)
        diesel = try c.decodeIfPresent(Double.self, forKey: .diesel)
        preferredFuelCode =
            try c.decodeIfPresent(String.self, forKey: .preferredFuelCode)
        preferredFuelPrice =
            try c.decodeIfPresent(Double.self, forKey: .preferredFuelPrice)
        let legacy = try decoder.container(keyedBy: LegacyKeys.self)
        distanceKm = try c.decodeIfPresent(Double.self, forKey: .distanceKm)
            ?? legacy.decodeIfPresent(Double.self, forKey: .distanceKm)
        isOpen = try c.decodeIfPresent(Bool.self, forKey: .isOpen)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
        priceFormatted =
            try c.decodeIfPresent(String.self, forKey: .priceFormatted)
        isCheapest = try c.decodeIfPresent(Bool.self, forKey: .isCheapest)
        predictiveBestLabel =
            try c.decodeIfPresent(String.self, forKey: .predictiveBestLabel)
        predictiveBestPrice =
            try c.decodeIfPresent(Double.self, forKey: .predictiveBestPrice)
    }
}
