// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The localized notification copy the velocity and radius runners build.
///
/// Moved out of `background_scan_runners.dart` at #4183, which turned
/// that file into detection paths only and pushed it past the 400-line
/// norm. It is a real seam, not a length dodge: "what a detector found"
/// and "how that reads in the user's language" are different concerns,
/// and #4183's whole point is that the second one now travels as data
/// ([OpportunityCandidate.copy]) rather than being posted on the spot.
///
/// #2306 — every string here comes from the [BackgroundNotificationTemplates]
/// the MAIN isolate resolved for the active in-app language; nothing is
/// composed from a literal.
library;

import '../../alerts/data/radius_alert_runner.dart';
import '../../alerts/domain/velocity_alert_detector.dart';
import '../../alerts/data/velocity_alert_runner.dart';
import '../../../core/services/country_service_registry.dart';
import 'notification_templates.dart';

/// Build notification copy for a velocity event. #2306 — copy comes from the
/// localized [BackgroundNotificationTemplates] the main isolate resolved for
/// the active in-app language.
VelocityAlertCopy buildVelocityCopy(
  VelocityAlertEvent event,
  BackgroundNotificationTemplates templates,
) {
  // #4301 — the grade name now travels in the templates blob, resolved
  // by the main isolate for the active in-app language, like every other
  // string here. Resolving it locally was never an option: this isolate's
  // own locale is the DEVICE locale, which is the bug #2306 fixed.
  //
  // The `.toUpperCase()` this line used to carry is gone. The template is
  // `{fuelLabel} dropped at nearby stations`, so the label opens a
  // sentence: upper-casing it shouted `AUTOGAS (LPG)` mid-sentence, and
  // Dart's `toUpperCase` is not locale-aware (the Turkish dotless-i
  // class of bug). It was emphasis on a short English token, and it does
  // not survive translation.
  final fuelLabel = templates.fuelLabelFor(event.fuelType.apiValue);
  return VelocityAlertCopy(
    title: templates.renderVelocityTitle(fuelLabel: fuelLabel),
    body: templates.renderVelocityBody(
      count: event.stationCount,
      cents: event.maxDropCents.round(),
    ),
  );
}

/// Build notification copy for a grouped radius alert (#1012 phase 2). #2306
/// — copy comes from the localized [BackgroundNotificationTemplates].
///
/// #2864 — the currency is resolved from the radius centre's country (via the
/// registry bounding box), so a GB / DK / … radius alert renders in £ / kr
/// instead of a forced euro. A centre outside every registered box falls back
/// to the template's default (euro).
RadiusAlertCopy buildRadiusAlertCopy(
  RadiusAlertGroupedEvent event,
  BackgroundNotificationTemplates templates,
) {
  final threshold = event.alert.threshold.toStringAsFixed(3);
  final label = event.alert.label;
  final country = CountryServiceRegistry.countryForLatLng(
      event.alert.centerLat, event.alert.centerLng);
  final currency = templates.currencyForCountry(country);
  final total = event.matches.length + event.truncatedMoreCount;
  final lines = event.matches
      // #2211 — show the station name, not the raw id. The per-line
      // "name price currency" mask is language-neutral.
      .map((m) => '${m.name} ${m.pricePerLiter.toStringAsFixed(3)} $currency')
      .toList();
  if (event.truncatedMoreCount > 0) {
    lines.add(templates.renderRadiusMore(count: event.truncatedMoreCount));
  }
  return RadiusAlertCopy(
    title: templates.renderRadiusTitle(
      label: label,
      count: total,
      threshold: threshold,
      currency: currency,
    ),
    body: lines.join('\n'),
  );
}
