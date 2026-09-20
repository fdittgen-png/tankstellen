// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/data_value.dart';
import '../../../../core/domain/fleet/claim_class.dart';
import '../../../../core/utils/data_value_labels.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';

/// How a fleet [ClaimedValue] reaches a manager's eyes (#4216, #4219).
///
/// `DataValueLabels.qualify` already turns an [Estimated] into `≈ x`;
/// what this adds is the two fleet-specific rules ADR 0025's UI wording
/// section makes binding:
///
///  * an absence renders as **"Not calculated"** — never `0`, never a
///    bare dash, and not the station-flavoured reasons the personal
///    surfaces use ("Not published for this station" says nothing
///    useful about a fuel grade with no emission factor);
///  * a class-3 or class-5 figure is qualified **whatever** its
///    underlying [DataValue] says, because the claim class carries the
///    caveat even when the arithmetic happened to be exact.
String fleetFigure(
  AppLocalizations l,
  ClaimedValue<double> claimed,
  String Function(double value) format,
) {
  if (!claimed.value.isKnown) return l.fleetManagerNotCalculated;
  final rendered = claimed.value.qualify(l, format);
  if (claimed.claim.alwaysQualified && !claimed.value.isQualified) {
    return l.dataApproximate(rendered);
  }
  return rendered;
}

/// The one-line caveat under a fleet figure, or null when it needs
/// none. An unknown's caveat is carried by [fleetFigure] itself, so
/// this returns null rather than repeating "Not calculated" twice.
String? fleetCaveat(AppLocalizations l, ClaimedValue<double> claimed) =>
    claimed.value.isKnown ? claimed.value.caveat(l) : null;

/// The claim class in the user's language — the label beside a figure
/// that says what it may be used for (#4219's six classes, of which a
/// manager surface ever shows four).
String fleetClaimLabel(AppLocalizations l, ClaimClass claim) =>
    switch (claim) {
      ClaimClass.measuredFact => l.fleetManagerClaimMeasured,
      ClaimClass.calculatedOperational => l.fleetManagerClaimCalculated,
      ClaimClass.estimate => l.fleetManagerClaimEstimate,
      ClaimClass.environmentalEstimate => l.fleetManagerClaimEnvironmental,
      // Neither reaches an aggregate screen: an expense's class-4
      // status is rendered by its own pill, and class 6 is own-only by
      // construction (ADR 0025 D5). Labelled honestly rather than
      // crashing if one ever arrives.
      ClaimClass.accountingCandidate => l.fleetManagerClaimCalculated,
      ClaimClass.personalDataInference => l.fleetManagerClaimEstimate,
    };

/// The unit masks the manager surfaces format their figures with.
///
/// Gathered here rather than inlined in four screens so every fleet
/// number reads the same, and so the screens stay about layout. Each
/// one delegates to the app's existing formatter, which already knows
/// the country's units (gallons, miles) and the locale's separators.
abstract final class FleetFormats {
  /// Money in the expense's own currency — never the device's, because
  /// the figure is the organisation's spend, not the reader's.
  static String money(double value, String? currency) =>
      PriceFormatter.formatTotal(value, currencyOverride: currency);

  /// Cost per kilometre, at the three decimals a fraction of a
  /// currency unit needs, with the currency code after it.
  static String costPerKm(double value, String? currency) {
    final figure = PriceFormatter.formatPerKm(value);
    return currency == null ? figure : '$figure $currency';
  }

  static String litres(double value) => UnitFormatter.formatVolume(value);

  static String distance(double value) =>
      UnitFormatter.formatOdometer(value);

  static String consumption(double value) =>
      UnitFormatter.formatConsumption(value, isEv: false);

  /// Kilograms of CO2e. The unit symbol is language-neutral.
  static String co2eKg(double value) =>
      // i18n-ignore: language-neutral mass unit mask
      '${UnitFormatter.formatDecimal(value, fractionDigits: 1)} kg';

  /// A 0..1 share as whole percent.
  static String share(double value) =>
      // i18n-ignore: language-neutral percent mask
      '${UnitFormatter.formatDecimal(value * 100, fractionDigits: 0)} %';
}
