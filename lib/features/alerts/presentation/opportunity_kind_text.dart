// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Labels for [OpportunityKind] and [BudgetRefusal] (#4154).
///
/// The same move `opportunity_reason_text.dart` made for reasons: the
/// domain names WHICH case applies and this is the only place that turns
/// one into words. A detector runs in a background isolate with no
/// `BuildContext`, so a label it composed itself could not be translated
/// (HARD RULE #1) — and keeping the mapping exhaustive here means adding
/// a kind or a refusal breaks the build rather than rendering a blank.
///
/// A refusal's text is a statement about the BUDGET, never about the
/// opportunity: the row is in the feed because it was worth finding.
/// "Not enough to be worth interrupting you" says what the policy
/// decided, not that the finding was wrong.
library;

import '../../../l10n/app_localizations.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_budget.dart';

/// What kind of opportunity this is, in the user's language.
String opportunityKindText(AppLocalizations l, OpportunityKind kind) =>
    switch (kind) {
      OpportunityKind.bestStopNow => l.opportunityKindBestStopNow,
      OpportunityKind.bestStopOnRoute => l.opportunityKindBestStopOnRoute,
      OpportunityKind.refuelSoon => l.opportunityKindRefuelSoon,
      OpportunityKind.exceptionalLocalPrice =>
        l.opportunityKindExceptionalLocalPrice,
      OpportunityKind.personalBaseline => l.opportunityKindPersonalBaseline,
      OpportunityKind.localMovement => l.opportunityKindLocalMovement,
      OpportunityKind.favouriteStation => l.opportunityKindFavouriteStation,
    };

/// Why the budget did not push this one.
String opportunityRefusalText(AppLocalizations l, BudgetRefusal refusal) =>
    switch (refusal) {
      BudgetRefusal.dailyCapReached => l.opportunityRefusalDailyCap,
      BudgetRefusal.tooSoonAfterLast => l.opportunityRefusalTooSoon,
      BudgetRefusal.savingBelowFloor => l.opportunityRefusalBelowFloor,
      BudgetRefusal.alreadyToldRecently => l.opportunityRefusalAlreadyTold,
      BudgetRefusal.outrankedInWindow => l.opportunityRefusalOutranked,
      BudgetRefusal.confidenceTooLow => l.opportunityRefusalConfidenceTooLow,
      BudgetRefusal.notWatched => l.opportunityRefusalNotWatched,
      BudgetRefusal.ineligible => l.opportunityRefusalIneligible,
    };
