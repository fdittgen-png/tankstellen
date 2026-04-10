import '../../features/consumption/domain/entities/fill_up.dart';
import '../../features/search/domain/entities/fuel_type.dart';

/// Pure utility for estimating CO2 emissions from fuel consumption.
///
/// Emission factors are well-to-wheel (WTW) values expressed in
/// kilograms of CO2-equivalent per liter of fuel burned, based on the
/// EU Joint Research Centre (JEC) WTW report v5 (2020).
///
/// These are intentionally conservative averages — real-world emissions
/// vary with blend composition, refining pathway, and driving style.
/// The goal of this engine is *awareness*, not audit-grade accounting.
///
/// All functions are pure and side-effect free: no I/O, no globals,
/// no random values. They are safe to call from providers, background
/// isolates, and widgets alike.
class Co2Calculator {
  Co2Calculator._();

  // ── Emission factors (kg CO2 per liter, WTW) ────────────────────────────

  /// E5 / SP95 petrol (5% ethanol). Source: EU JEC WTW v5.
  static const double kgCo2PerLiterE5 = 2.31;

  /// E10 petrol (10% ethanol). Slightly lower than E5 due to bio content.
  static const double kgCo2PerLiterE10 = 2.27;

  /// Super 98 (SP98) petrol — treated like E5 for CO2 purposes.
  static const double kgCo2PerLiterE98 = 2.31;

  /// Standard diesel (B7, 7% biodiesel blend). Source: EU JEC WTW v5.
  static const double kgCo2PerLiterDiesel = 2.65;

  /// Diesel Premium — equivalent to standard diesel for CO2 purposes.
  static const double kgCo2PerLiterDieselPremium = 2.65;

  /// E85 / Bioethanol (85% ethanol). Much lower WTW emissions due to
  /// biogenic carbon uptake.
  static const double kgCo2PerLiterE85 = 1.40;

  /// LPG (Liquefied Petroleum Gas, butane/propane mix).
  static const double kgCo2PerLiterLpg = 1.61;

  /// CNG (Compressed Natural Gas) — sold per kg in most EU markets.
  /// Returned per-liter-equivalent for API symmetry; callers working
  /// with kg should multiply directly by [kgCo2PerKgCng].
  static const double kgCo2PerKgCng = 2.54;

  // ── Core lookup ──────────────────────────────────────────────────────────

  /// Returns the CO2 emission factor (kg CO2 per liter) for the given
  /// [fuelType]. Returns `null` for fuel types without a meaningful
  /// per-liter factor (electric, hydrogen, CNG sold per kg, meta).
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

  /// Compute CO2 emissions (kg) for a given volume of fuel.
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

  /// Compute CO2 emissions (kg) for a single [FillUp].
  static double co2ForFillUp(FillUp fillUp) =>
      co2ForLiters(fillUp.liters, fillUp.fuelType);

  /// Sum CO2 emissions (kg) across a list of fill-ups.
  static double cumulativeCo2(List<FillUp> fillUps) {
    double total = 0;
    for (final f in fillUps) {
      total += co2ForFillUp(f);
    }
    return total;
  }

  /// Compute CO2 emissions per kilometer (kg CO2 / km) for a fill-up,
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
