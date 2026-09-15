// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What every scan found, including what it refused to push (#4183).
///
/// #4151 promised that a demotion is not a deletion — "suppressed means
/// not a push, never discarded" — and until this store existed that was
/// true only inside one function call. This is where the promise becomes
/// something the user can open: the feed (#4154) reads it, and "why
/// didn't I get an alert" is answered from it rather than from a debug
/// log nobody has.
///
/// ## Where it lives, and why not a new box
///
/// [HiveBoxes.alerts] — already encrypted, already open in BOTH the main
/// and the WorkManager isolate. A new box would have to be opened inside
/// the background isolate, and #4110 is the standing reminder of what a
/// box open costs on the path a user is waiting on.
///
/// ## Bounded by construction
///
/// A device that scans twice a day for a year would otherwise accumulate
/// 730 rows of dead opportunities. [maxEntries] caps the list and
/// [retention] drops anything older, both applied on every write — so
/// the bound holds without a sweeper anybody has to remember to run.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_boxes.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_budget.dart';
import 'opportunity_codec.dart';

/// One opportunity as the feed sees it: what it is, and whether it was
/// pushed or refused.
@immutable
class FeedEntry {
  const FeedEntry({
    required this.opportunity,
    required this.wasNotified,
    this.refusal,
  });

  final Opportunity opportunity;

  /// Whether this one became a notification.
  final bool wasNotified;

  /// Why it did not, when it did not. Null exactly when [wasNotified].
  final BudgetRefusal? refusal;

  Map<String, Object?> toJson() => {
        'o': OpportunityCodec.encode(opportunity),
        'notified': wasNotified,
        if (refusal != null) 'refusal': refusal!.name,
      };

  /// Null when the row cannot be read — see [OpportunityCodec].
  static FeedEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, Object?>();
    final opportunity = OpportunityCodec.decode(map['o']);
    if (opportunity == null) return null;
    final notified = map['notified'] == true;
    final refusalName = map['refusal'];
    BudgetRefusal? refusal;
    if (refusalName is String) {
      for (final r in BudgetRefusal.values) {
        if (r.name == refusalName) refusal = r;
      }
      // An unknown refusal name is a row from a newer build. Keep the
      // opportunity — it is still a real finding — and lose only the
      // reason, which the feed renders as "not pushed" rather than
      // inventing a reason it does not have.
    }
    return FeedEntry(
      opportunity: opportunity,
      wasNotified: notified,
      refusal: notified ? null : refusal,
    );
  }
}

/// Reads and writes the opportunity feed.
class OpportunityFeedStore {
  const OpportunityFeedStore();

  /// Hive key holding the JSON array.
  static const String storageKey = 'opportunity_feed';

  /// The most rows kept, newest first.
  ///
  /// Three a day is the budget's cap and a scan can demote several more,
  /// so 60 is roughly a week of a busy device — long enough that "I did
  /// not get an alert last Tuesday" is answerable, short enough that the
  /// row never becomes a storage decision.
  static const int maxEntries = 60;

  /// How long an entry stays, regardless of count.
  static const Duration retention = Duration(days: 7);

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'OpportunityFeedStore: alerts box unavailable',
      });
      return null;
    }
  }

  /// Every entry, newest first. Empty when the box is closed or the row
  /// is missing — an empty feed is the honest answer in both cases.
  List<FeedEntry> read() {
    final box = _boxOrNull();
    if (box == null) return const [];
    final raw = box.get(storageKey);
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final row in list) ?FeedEntry.fromJson(row)];
    } on FormatException catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'OpportunityFeedStore.read: malformed feed row',
      });
      return const [];
    }
  }

  /// Prepend one scan's [outcome] and re-apply the bounds.
  ///
  /// The notified one first, then the demoted ones in the order the
  /// budget ranked them — so the feed reads top-down as "this is what we
  /// told you, and here is everything else we found".
  Future<void> recordScan(BudgetOutcome outcome, DateTime now) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint('OpportunityFeedStore.recordScan: alerts box closed, '
          'dropping ${outcome.demoted.length + (outcome.isQuiet ? 0 : 1)} '
          'entries');
      return;
    }
    final fresh = <FeedEntry>[
      if (outcome.notify case final notified?)
        FeedEntry(opportunity: notified, wasNotified: true),
      for (final d in outcome.demoted)
        FeedEntry(
          opportunity: d.opportunity,
          wasNotified: false,
          refusal: d.reason,
        ),
    ];
    if (fresh.isEmpty) return;

    final cutoff = now.subtract(retention);
    final kept = [
      ...fresh,
      for (final e in read())
        if (e.opportunity.detectedAt.isAfter(cutoff)) e,
    ].take(maxEntries).toList();

    await box.put(storageKey, jsonEncode([for (final e in kept) e.toJson()]));
  }

  /// Drop the whole feed — the "clear all data" troubleshoot path.
  Future<void> clear() async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete(storageKey);
  }
}
