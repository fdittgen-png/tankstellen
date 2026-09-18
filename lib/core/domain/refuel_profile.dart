// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The vehicle-and-intent side of the refuel decision (#4089), plus the
/// constants that shape it.
///
/// Split out of `refuel_economics.dart` when #4361 gave the profile a
/// comparison currency and a rate snapshot and that file reached the
/// 400-line cap. A real seam rather than a length dodge: WHO is driving
/// and WHAT they intend to buy is a different concern from what a refuel
/// costs, and `refuel_profile_provider.dart` supplies only this half.
///
/// Re-exported by `refuel_economics.dart`, so every existing caller keeps
/// one import.
library;

import 'package:meta/meta.dart';

import 'data_value.dart';
import 'money.dart';

/// The default litres a refuel is assumed to buy when the user has no
/// fill-up history to measure (#4089).
///
/// A round European tankful.
///
/// ## What Q does, and what it does NOT do (corrected by #4158)
///
/// The effective price works out to `p + detourCost / Q`, and
/// `detourCost` does not depend on Q. So Q is the divisor that
/// **amortises the detour**: the more litres you buy, the less the drive
/// to get there costs per litre.
///
/// This docstring previously claimed Q "moves the effective price by
/// cents, never the sign of a comparison". **That is false**, and a
/// property test found the counterexample on its first run:
///
/// ```
/// a: €1.47/L at 0.7 km      b: €1.40/L at 7.7 km      6 L/100 km
///   Q=20 → a 1.4794, b 1.4981   a wins
///   Q=80 → a 1.4723, b 1.4245   b wins
/// ```
///
/// That behaviour is CORRECT — a cheaper station further away genuinely
/// becomes worth the drive once you are buying enough — but it means Q
/// is a real input to the ranking, not a harmless scale factor. It is
/// why `RefuelProfile.litresIntended` is measured from the user's own
/// median fill (#4150) rather than defaulted, and why #4095 lets them
/// change it.
///
/// What IS invariant, and is tested:
///
///  * at **equal distance** the effective price is proportional to the
///    pump price, so Q never reorders two stations the same distance
///    away;
///  * raising Q moves every effective price monotonically **toward** its
///    pump price, never away.
///
const double kDefaultRefuelLitres = 40;

/// Crow-flies → road distance correction (#4089).
///
/// Straight-line distance systematically understates driving, and an
/// understated detour is exactly the error that would talk a user into a
/// pointless one. 1.3 is the conventional detour index for European road
/// networks; it applies only when the caller has no real road distance
/// (`RefuelCandidate.isRoadDistance == false`).
const double kCrowFliesRoadFactor = 1.3;

/// There and back (the default) — the errand case, where the station is
/// not on the way to anywhere.
const double kRoundTripFactor = 2;

/// How fresh a price must be for Best Value to LEAD rather than merely
/// rank (spec §3.1, #4139).
///
/// A day: every source the app uses refreshes at least daily, so a price
/// older than this is one the provider itself has stopped standing
/// behind.
const Duration kConfidentPickMaxPriceAge = Duration(hours: 24);

/// One way — the station is on a route the user is driving anyway, so
/// only the deviation counts. The route layer supplies the real
/// deviation as a road distance.
const double kEnRouteTripFactor = 1;

/// The vehicle and intent side of the calculation.
///
/// [consumptionLPer100km] is nullable ON PURPOSE: no consumption means
/// no Best Value ranking, and the UI says so rather than substituting a
/// number the user never gave (spec §4.1). [consumptionIsEstimated]
/// travels with it so an explanation built on a model reads as one.
@immutable
class RefuelProfile {
  const RefuelProfile({
    this.consumptionLPer100km,
    this.consumptionIsEstimated = false,
    this.litresIntended = kDefaultRefuelLitres,
    this.tripFactor = kRoundTripFactor,
    this.roadFactor = kCrowFliesRoadFactor,
    this.comparisonCurrency,
    this.rates = const ExchangeRateSnapshot.empty(),
  });

  /// Vehicle consumption in L/100 km — measured from fill-ups when the
  /// user has them, else a reference estimate, else null.
  final double? consumptionLPer100km;

  /// Whether [consumptionLPer100km] is modelled rather than measured.
  final bool consumptionIsEstimated;

  /// The NET refill this decision is priced for — the fuel the driver is
  /// better off by after the trip (#4360, `RefuelPurchaseQuantity.netIncrease`).
  /// The user's own median fill-up when known — the whole point of
  /// [kDefaultRefuelLitres] being a fallback and not a question.
  ///
  /// Not the litres dispensed: the pump delivers this plus the fuel the
  /// trip burns ([RefuelQuote.litresToDispense]).
  final double litresIntended;

  /// 2 there-and-back, 1 en route. See [kRoundTripFactor].
  final double tripFactor;

  /// Applied to crow-flies distances only. See [kCrowFliesRoadFactor].
  final double roadFactor;

  /// The ONE currency every money ranking is decided in (#4361).
  ///
  /// Null falls back to the single currency the candidates themselves
  /// state — and to the legacy currency-free behaviour when none of them
  /// states any. It is never a default like "EUR": a comparison the app
  /// silently re-denominated is exactly the failure this field exists to
  /// stop.
  final String? comparisonCurrency;

  /// The rates [comparisonCurrency] is reached by, with their source and
  /// timestamp. Empty by default: no rate is not 1:1 (#4361).
  final ExchangeRateSnapshot rates;

  /// The same pair in the app-wide shape (#4160).
  ///
  /// [consumptionLPer100km] and [consumptionIsEstimated] are a value with
  /// a flag beside it, which is exactly the arrangement a `≈` goes
  /// missing from: nothing stops the flag being dropped on the way to a
  /// widget. Both fields stay — the arithmetic below wants a plain
  /// `double?` and always will — but a rendering path takes this getter
  /// instead, and the provenance cannot be left behind.
  ///
  /// A null consumption is [DataUnknownReason.notMeasuredYet]: it means
  /// the user has no fill-up history, and trust rule 1 requires saying
  /// which missing input it is rather than showing an empty figure.
  DataValue<double> get consumption {
    final value = consumptionLPer100km;
    if (value == null) {
      return const DataValue.unknown(
        reason: DataUnknownReason.notMeasuredYet,
      );
    }
    return consumptionIsEstimated
        ? DataValue.estimated(value, basis: DataBasis.fleetAverage)
        : DataValue.measured(value);
  }

  /// The same profile decided in [currency] at [rates] (#4361).
  ///
  /// The vehicle side of the profile is supplied by the fill-ups feature
  /// through `refuelProfileProvider`; the currency side is a property of
  /// where the driver is, not of the car. This keeps the two independent
  /// instead of pushing an FX dependency into the fill-ups override.
  RefuelProfile withComparison({
    required String currency,
    required ExchangeRateSnapshot rates,
  }) =>
      RefuelProfile(
        consumptionLPer100km: consumptionLPer100km,
        consumptionIsEstimated: consumptionIsEstimated,
        litresIntended: litresIntended,
        tripFactor: tripFactor,
        roadFactor: roadFactor,
        comparisonCurrency: currency,
        rates: rates,
      );

  /// Whether an economic ranking can be computed at all.
  bool get canRankByValue =>
      (consumptionLPer100km ?? 0) > 0 && litresIntended > 0;
}
