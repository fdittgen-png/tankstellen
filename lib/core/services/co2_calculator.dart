// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../features/fill_ups/domain/entities/fill_up.dart';
import '../domain/fuel_type.dart';

/// Pure utility for estimating CO2e emissions from fuel consumption.
///
/// ## Scope and source (#4392)
///
/// Every constant below is a **well-to-wheel (WtW)** factor — upstream
/// (`Amont`: extraction, refining, transport, distribution) *plus*
/// combustion — in kilograms of CO2e per litre of fuel, or per kilogram
/// for CNG. They are the published totals of
/// **ADEME Base Carbone® v23.6** (updated 2026-06-30, Licence Ouverte),
/// boundary *France continentale*, category
/// `Combustibles > Fossiles > Liquides > Usage sources mobiles > Usage
/// routier`:
///
/// | Constant | ADEME element | WtW | of which combustion (TtW) |
/// |---|---|---|---|
/// | [kgCo2PerLiterE5] / [kgCo2PerLiterE98] | 25763 `Supercarburant sans plomb (95, 95-E10, 98)` | 2.69 | 2.20 |
/// | [kgCo2PerLiterE10] | 13988 `Essence E10` | 2.69 | 2.19 |
/// | [kgCo2PerLiterDiesel] / [kgCo2PerLiterDieselPremium] | 25775 `Gazole routier B7` | 3.10 | 2.49 |
/// | [kgCo2PerLiterE85] | 25766 `Essence E85` | 1.11 | 0.366 |
/// | [kgCo2PerLiterLpg] | 14031 `GPL pour véhicule routier` | 1.86 | 1.60 |
/// | [kgCo2PerKgCng] | 27095 `GNC pour véhicule routier` | 2.96 | 2.41 |
///
/// The tank-to-wheel halves are published beside these in
/// `EmissionFactorRegistry.ademeBaseCarbone`, which
/// `emission_factor_registry_test` pins to the constants here so the two
/// cannot drift apart.
///
/// Until #4392 these constants were 2.31 / 2.27 / 2.65 / 1.40 / 1.61 /
/// 2.54 attributed to "EU JEC WTW v5 (2020)". Those magnitudes are
/// *tank-to-wheel* combustion figures, so the dashboard understated
/// well-to-wheel emissions while claiming them, and no JEC table
/// publishes them per litre (JEC reports gCO2eq/MJ). The label was
/// right about what the app wants to show; the numbers were not, so the
/// numbers moved to a source that publishes both boundaries per litre
/// for the very grades the app sells.
///
/// These remain **class averages**, not measurements: real emissions
/// vary with blend, refining pathway and driving style. The goal of
/// this engine is *awareness*, not audit-grade accounting — the carbon
/// dashboard therefore names the boundary and the source on screen.
///
/// All functions are pure and side-effect free: no I/O, no globals,
/// no random values. They are safe to call from providers, background
/// isolates, and widgets alike.
class Co2Calculator {
  Co2Calculator._();

  /// The boundary every constant below is measured over — printed by the
  /// carbon dashboard so a figure is never shown without its scope.
  /// Not a translated string: `WtW` is the same abbreviation in every
  /// language (`EmissionScope.wellToWheel.label`). It is a constant, not
  /// a UI literal — the dashboard's translated scope wording lives in
  /// `carbonCo2ScopeWellToWheel`.
  static const String scopeLabel = 'WtW';

  /// The citation the dashboard prints beside a CO2e figure, through
  /// the `carbonCo2FactorSource` placeholder. A publication name and
  /// version — a proper noun, identical in every locale.
  static const String factorCitation = 'ADEME Base Carbone v23.6 (2026)';

  // ── Emission factors (kg CO2e per liter, well-to-wheel) ─────────────────

  /// E5 / SP95 petrol (up to 5% ethanol). ADEME element 25763
  /// `Supercarburant sans plomb (95, 95-E10, 98)`.
  static const double kgCo2PerLiterE5 = 2.69;

  /// E10 petrol (up to 10% ethanol). ADEME element 13988 `Essence E10`
  /// — the same 2.69 total as SP95/98 at the precision ADEME publishes;
  /// the blends differ by 0.01 kg/L on the combustion half alone.
  static const double kgCo2PerLiterE10 = 2.69;

  /// Super 98 (SP98) petrol — named by ADEME element 25763 alongside
  /// SP95 and SP95-E10, so it carries the same factor.
  static const double kgCo2PerLiterE98 = 2.69;

  /// Standard diesel (B7, up to 7% FAME). ADEME element 25775
  /// `Gazole routier B7`.
  static const double kgCo2PerLiterDiesel = 3.10;

  /// Diesel Premium — ADEME publishes one road-diesel grade (B7); the
  /// premium additive package does not change the carbon content.
  static const double kgCo2PerLiterDieselPremium = 3.10;

  /// E85 / Bioethanol (85% ethanol). ADEME element 25766 `Essence E85`.
  /// Far lower than petrol because the biogenic CO2 released at the
  /// tailpipe is balanced by the uptake booked upstream — ADEME's own
  /// `CO2b` bookkeeping, not a credit this app applies.
  static const double kgCo2PerLiterE85 = 1.11;

  /// LPG (Liquefied Petroleum Gas, butane/propane mix). ADEME element
  /// 14031 `GPL pour véhicule routier`, per litre.
  static const double kgCo2PerLiterLpg = 1.86;

  /// CNG (Compressed Natural Gas) — sold per kg in most EU markets.
  /// ADEME element 27095 `GNC, Gaz Naturel Comprimé pour véhicule
  /// routier`, per **kilogram**: callers pass kg where the other
  /// constants take litres.
  static const double kgCo2PerKgCng = 2.96;

  // ── Core lookup ──────────────────────────────────────────────────────────

  /// Returns the CO2e emission factor (kg CO2e per liter) for the given
  /// [fuelType]. Returns `null` for fuel types without a meaningful
  /// per-liter factor (electric, hydrogen, meta) — CNG returns its
  /// per-kilogram factor, because that is the unit it is sold in.
  static double? emissionFactorFor(FuelType fuelType) {
    return switch (fuelType) {
      FuelTypeE5() => kgCo2PerLiterE5,
      FuelTypeE10() => kgCo2PerLiterE10,
      FuelTypeE98() => kgCo2PerLiterE98,
      FuelTypeDiesel() => kgCo2PerLiterDiesel,
      FuelTypeDieselPremium() => kgCo2PerLiterDieselPremium,
      FuelTypeE85() => kgCo2PerLiterE85,
      FuelTypeLpg() => kgCo2PerLiterLpg,
      FuelTypeCng() => kgCo2PerKgCng, // caller passes kg, not L
      FuelTypeHydrogen() => null,
      FuelTypeElectric() => null,
      FuelTypeAll() => null,
    };
  }

  /// Compute CO2e emissions (kg) for a given volume of fuel.
  ///
  /// Negative [liters] is clamped to zero. Unknown or unsupported fuel
  /// types (electric, hydrogen, all) return 0 — callers wanting to
  /// distinguish "unsupported" from "zero emissions" should check
  /// [emissionFactorFor] first.
  static double co2ForLiters(double liters, FuelType fuelType) {
    if (liters <= 0) return 0;
    final factor = emissionFactorFor(fuelType);
    if (factor == null) return 0;
    return liters * factor;
  }

  /// Compute CO2e emissions (kg) for a single [FillUp].
  static double co2ForFillUp(FillUp fillUp) =>
      co2ForLiters(fillUp.liters, fillUp.fuelType);

  /// Sum CO2e emissions (kg) across a list of fill-ups.
  static double cumulativeCo2(List<FillUp> fillUps) {
    double total = 0;
    for (final f in fillUps) {
      total += co2ForFillUp(f);
    }
    return total;
  }

  /// Compute CO2e emissions per kilometer (kg CO2e / km) for a fill-up,
  /// given the distance [km] driven on that tank.
  ///
  /// Returns `null` when [km] is non-positive (distance unknown or zero)
  /// so callers can distinguish "no data" from "zero".
  static double? co2PerKm(FillUp fillUp, double km) {
    if (km <= 0) return null;
    final co2 = co2ForFillUp(fillUp);
    if (co2 == 0) return null;
    return co2 / km;
  }
}
