// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Turning opportunities into an order (#4149, epic #4148).
///
/// Pure functions over [Opportunity]. No storage, no notifications, no
/// clock of its own — the caller passes `now`, so every decision here is
/// reproducible in a test.
///
/// ## Why there is no weighted score
///
/// The obvious design is a number per opportunity: saving × confidence ×
/// freshness × a distance penalty. `docs/specs/refuel-economics.md` §5
/// refuses exactly that, and the reasoning transfers with more force to
/// a notification than to a list — a ranked list the user is reading can
/// be argued with, an interruption cannot. A weight cannot be explained
/// in one sentence to the person it woke up.
///
/// So confidence and freshness are **gates**, and the only thing that
/// orders what survives them is the money. That number the user can
/// check against the two figures printed beside it.
library;

import 'opportunity.dart';
import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';

/// Why an opportunity was refused. Every rejection is nameable, so a
/// silent drop is impossible and "why didn't I get an alert" has an
/// answer in the logs.
enum OpportunityRefusal {
  /// Its reason stopped being true before it could be delivered.
  expired,

  /// The provider behind it publishes no prices at all — there is
  /// nothing to trust (#4156).
  noProviderConfidence,

  /// The price is old enough that the provider has stopped standing
  /// behind it.
  stalePrice,

  /// Its net saving does not equal the difference of the figures it
  /// shows. Trust rule 4: a claim nobody can check is not shipped.
  savingNotReproducible,
}

/// How old a price may be and still justify waking someone.
///
/// Deliberately the same 24 h `kConfidentPickMaxPriceAge` governs in
/// `refuel_decision.dart`: the app should not have two different beliefs
/// about when a price stops being current, one for a list and a stricter
/// or looser one for a notification.
const Duration kOpportunityMaxPriceAge = Duration(hours: 24);

/// Ordering and eligibility for [Opportunity].
abstract final class OpportunityScorer {
  /// Why [o] may not be delivered, or null when it may.
  static OpportunityRefusal? refuse(Opportunity o, DateTime now) {
    if (o.isExpiredAt(now)) return OpportunityRefusal.expired;
    if (o.confidence == DataConfidence.none) {
      return OpportunityRefusal.noProviderConfidence;
    }
    if (!o.savingIsReproducible) {
      return OpportunityRefusal.savingNotReproducible;
    }
    final age = o.priceAge;
    // Only a price we can actually DATE can be too old. An unknown age
    // stands the gate down rather than failing it — the #4156 rule, and
    // without it every opportunity in the nine countries whose provider
    // stamps no prices would be refused forever with nothing saying why.
    //
    // This diverges from `RefuelDecision.confidentPick` in one case, on
    // purpose: there, a provider that DOES stamp prices but left this
    // row blank still blocks, because leading is the app volunteering
    // one answer over two others and a gap is a reason to keep quiet.
    // An alert is the opposite situation — the user configured it and
    // asked to be told — so the gap travels as a caveat instead of
    // becoming silence.
    if (age is Measured<Duration> && age.value > kOpportunityMaxPriceAge) {
      return OpportunityRefusal.stalePrice;
    }
    return null;
  }

  static bool isEligible(Opportunity o, DateTime now) =>
      refuse(o, now) == null;

  /// Orders two opportunities, best first.
  ///
  /// Priceable ones come first and are ordered by net saving, because
  /// that is the only figure that means the same thing across kinds.
  /// An opportunity that could NOT be priced is never compared on money
  /// it does not have: those sort behind, ordered by how little driving
  /// they ask for, which is the only comparable fact they still carry.
  static int compare(Opportunity a, Opportunity b) {
    if (a.isPriceable != b.isPriceable) return a.isPriceable ? -1 : 1;
    if (a.isPriceable) {
      final byMoney = b.netSaving!.compareTo(a.netSaving!);
      if (byMoney != 0) return byMoney;
    } else {
      final byDistance = a.distanceKm.compareTo(b.distanceKm);
      if (byDistance != 0) return byDistance;
    }
    // #4090's rule, for the same reason: a stable tiebreak so the same
    // inputs never produce two different orders.
    return (a.stationId ?? '').compareTo(b.stationId ?? '');
  }

  /// The eligible opportunities in [candidates], best first.
  static List<Opportunity> rank(
    Iterable<Opportunity> candidates,
    DateTime now,
  ) =>
      candidates.where((o) => isEligible(o, now)).toList()..sort(compare);
}
