// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/time/app_clock.dart';
import '../data/opportunity_feed_store.dart';

part 'opportunity_feed_provider.g.dart';

/// What the background engine found, newest first (#4154).
///
/// A plain synchronous read: [OpportunityFeedStore] reads one Hive row
/// that is already open in this isolate, so there is no future to await
/// and no loading state to render. The background scan writes it; this
/// only ever reads.
///
/// **Expired entries are filtered out, not hidden.** An opportunity
/// carries an `expiresAt` because a price is not an opportunity forever,
/// and a feed that kept showing yesterday's bargain would teach the user
/// that the list is stale — the same failure a late notification causes
/// (#4149). They stay in the store until retention drops them; they just
/// stop being presented as current.
///
/// The clock comes through [appClockProvider] (#3660) rather than raw,
/// so a test can pin "now" and assert the expiry boundary instead of
/// agreeing with the calendar of the machine that runs it.
@riverpod
List<FeedEntry> opportunityFeed(Ref ref) {
  final at = ref.watch(appClockProvider).now();
  return [
    for (final entry in const OpportunityFeedStore().read())
      if (!entry.opportunity.isExpiredAt(at)) entry,
  ];
}
