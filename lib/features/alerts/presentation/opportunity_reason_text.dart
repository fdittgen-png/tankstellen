// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Rendering for [OpportunityReason] (#4152).
///
/// The ONE place a reason becomes text. Detectors produce structured
/// facts and this turns them into the user's language — which is what
/// keeps the list translatable, keeps it honest, and keeps a
/// notification site from inventing a claim the model cannot support.
///
/// A reason with no data never reaches here: `OpportunityReasons.of`
/// omits it rather than emitting a variant with nothing in it, so this
/// has no empty-bullet case to handle.
library;


import '../../../core/services/provider_capability.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/unit_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_confidence.dart';
import '../domain/opportunity_reasons.dart';

/// One reason, in the user's language.
String opportunityReasonText(AppLocalizations l, OpportunityReason r) =>
    switch (r) {
      NetSavingReason(:final netSaving) =>
        l.alertReasonNetSaving(PriceFormatter.formatTotal(netSaving)),
      BelowReferenceReason(:final perLitreDelta, :final reference) =>
        _belowText(l, reference, PriceFormatter.formatTotal(perLitreDelta)),
      DistanceReason(:final distanceKm) =>
        l.alertReasonDistance(UnitFormatter.formatDistance(distanceKm)),
      PriceAgeReason(:final age) =>
        l.alertReasonPriceAge(formatElapsedDuration(l, age)),
      PriceAgeUnknownReason() => l.alertReasonPriceAgeUnknown,
      ProviderConfidenceReason(:final confidence) =>
        confidence == DataConfidence.medium
            ? l.alertReasonSourceMedium
            : l.alertReasonSourceLow,
    };

/// Every reason for [o], in order, already rendered.
List<String> opportunityReasonLines(AppLocalizations l, Opportunity o) =>
    [for (final r in OpportunityReasons.of(o)) opportunityReasonText(l, r)];

/// How a [band] qualifies the claim above the reasons, or null when it
/// needs no qualification.
///
/// High says nothing: an alert that announces its own trustworthiness is
/// one the reader learns to distrust. Low never reaches a notification
/// at all (`OpportunityConfidence.mayNotify`), so the only band with
/// something to say here is medium.
String? alertConfidencePrefix(AppLocalizations l, AlertConfidence band) =>
    band == AlertConfidence.medium ? l.alertConfidenceMediumPrefix : null;

/// Which "below X" line applies — the enum decides, never the detector.
String _belowText(
  AppLocalizations l,
  OpportunityReference reference,
  String delta,
) =>
    switch (reference) {
      OpportunityReference.thresholdYouSet =>
        l.alertReasonBelowThreshold(delta),
      OpportunityReference.yourMedian => l.alertReasonBelowYourMedian(delta),
      OpportunityReference.localMedian => l.alertReasonBelowLocalMedian(delta),
      OpportunityReference.priceEarlier => l.alertReasonBelowEarlier(delta),
      OpportunityReference.cheapestOnRoute =>
        l.alertReasonBelowCheapestOnRoute(delta),
      OpportunityReference.cheapestNearby =>
        l.alertReasonBelowCheapestNearby(delta),
    };
