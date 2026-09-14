// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Why the user is seeing this alert, as DATA (#4152, epic #4148).
///
/// Every line is a fact already on the [Opportunity], named — never a
/// sentence written at the notification site. Two reasons for that, and
/// the second is the one that matters:
///
///  1. A detector runs in a background isolate with no `BuildContext`,
///     so a sentence it composed itself could not be translated
///     (HARD RULE #1).
///  2. **A reason that cannot be filled from the model is a reason the
///     app cannot support.** Structuring them this way makes an
///     unsupportable claim impossible to write rather than merely
///     discouraged — the same move `ProviderCapability` made for
///     provider claims in #4156.
///
/// The UI renders these; it does not compose them. A reason with no data
/// is ABSENT, never an empty bullet.
library;

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';
import 'opportunity.dart';

/// One "why am I seeing this" line.
///
/// A sealed type rather than a `(kind, value)` pair so each variant
/// carries exactly the fields its rendering needs and no others — a
/// distance reason cannot accidentally be built without a distance.
@immutable
sealed class OpportunityReason {
  const OpportunityReason();
}

/// How far below the reference the price sits, per litre.
@immutable
final class BelowReferenceReason extends OpportunityReason {
  const BelowReferenceReason({
    required this.perLitreDelta,
    required this.reference,
  });

  /// Positive: how much cheaper, per litre.
  final double perLitreDelta;

  /// What it is cheaper THAN — rendered from the enum, never described
  /// in a string the detector built.
  final OpportunityReference reference;
}

/// What acting on it is worth in money, at this user's usual fill.
@immutable
final class NetSavingReason extends OpportunityReason {
  const NetSavingReason(this.netSaving);
  final double netSaving;
}

/// How far away it is.
@immutable
final class DistanceReason extends OpportunityReason {
  const DistanceReason(this.distanceKm);
  final double distanceKm;
}

/// How old the price is — only when the provider actually stamps prices
/// (#4156). Absent, not zero, when it does not.
@immutable
final class PriceAgeReason extends OpportunityReason {
  const PriceAgeReason(this.age);
  final Duration age;
}

/// The provider publishes no price timestamps at all, so the freshness
/// of this number is our download time and not theirs.
///
/// Its own reason rather than a missing one: trust rule 1 says a missing
/// input is STATED, never defaulted, and "we cannot date this price"
/// belongs in the same list as the facts that made the alert.
@immutable
final class PriceAgeUnknownReason extends OpportunityReason {
  const PriceAgeUnknownReason();
}

/// How far the country's data source may be trusted, when that is worth
/// saying — i.e. when it is not the best case.
@immutable
final class ProviderConfidenceReason extends OpportunityReason {
  const ProviderConfidenceReason(this.confidence);
  final DataConfidence confidence;
}

/// Builds the reason list for an opportunity.
///
/// Pure, ordered, and total: the same opportunity always produces the
/// same lines in the same order, and every line traces to a field.
abstract final class OpportunityReasons {
  /// Reasons for [o], most load-bearing first.
  ///
  /// Ordering is the argument the user reads: what it saves, how it
  /// compares, what it costs to get there, and only then the caveats.
  /// Putting freshness first would make every alert open with a hedge.
  static List<OpportunityReason> of(Opportunity o) {
    final reasons = <OpportunityReason>[];

    final net = o.netSaving;
    if (net != null) reasons.add(NetSavingReason(net));

    final ref = o.referencePrice;
    if (ref != null && ref > o.currentPrice) {
      reasons.add(BelowReferenceReason(
        perLitreDelta: ref - o.currentPrice,
        reference: o.reference,
      ));
    }

    // Zero distance is the area-wide movement case, which is not "at
    // your location" — it is "nowhere in particular", and a 0 km line
    // would read as the former.
    if (o.distanceKm > 0) reasons.add(DistanceReason(o.distanceKm));

    switch (o.priceAge) {
      case Measured<Duration>(:final value):
        reasons.add(PriceAgeReason(value));
      case Unknown<Duration>(:final reason)
          when reason == DataUnknownReason.notPublishedByProvider:
        reasons.add(const PriceAgeUnknownReason());
      case _:
        // The provider stamps prices and left this row blank. Saying
        // nothing is right: there is no fact here, and inventing "age
        // unknown" would blame the provider for a gap in one row.
        break;
    }

    // Only when it is worth saying. A high-confidence source speaks for
    // itself, and a line asserting that everything is fine is noise that
    // trains the reader to skip the list.
    if (o.confidence != DataConfidence.high) {
      reasons.add(ProviderConfidenceReason(o.confidence));
    }

    return reasons;
  }
}
