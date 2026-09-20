// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/budget_state_store.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';

import '../../../helpers/hive_temp_dir.dart';

/// #4183 — the two stores that make the budget a budget and the feed a
/// feed.
///
/// These RUN against a real Hive box rather than a fake, for #4116's
/// reason: the closed-box branch is the one that fires in a background
/// isolate, and a fake that always has a box proves nothing about it.
void main() {
  late Directory tmpDir;
  final now = DateTime.utc(2026, 9, 15, 12);

  Opportunity opportunity({
    String stationId = 'de-a',
    double? net,
    DateTime? detectedAt,
  }) =>
      Opportunity(
        kind: OpportunityKind.bestStopNow,
        stationId: stationId,
        stationName: 'ARAL',
        fuelType: 'e10',
        currentPrice: 1.649,
        reference: OpportunityReference.localMedian,
        referencePrice: 1.729,
        grossSaving: net == null ? null : net + 0.4,
        detourCost: net == null ? null : 0.4,
        netSaving: net,
        distanceKm: 3.2,
        priceAge: const DataValue.measured(Duration(minutes: 12)),
        confidence: DataConfidence.high,
        detectedAt: detectedAt ?? now,
        expiresAt: (detectedAt ?? now).add(const Duration(hours: 6)),
      );

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('opportunity_stores_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(tmpDir);
  });

  group('OpportunityFeedStore', () {
    const store = OpportunityFeedStore();

    test('an empty feed reads as empty, not as an error', () {
      expect(store.read(), isEmpty);
    });

    test('records the notified one AND every refusal', () async {
      await store.recordScan(
        BudgetOutcome(
          notify: opportunity(stationId: 'de-winner', net: 3.8),
          demoted: [
            DemotedOpportunity(opportunity(stationId: 'de-second', net: 2.1),
                BudgetRefusal.outrankedInWindow),
            DemotedOpportunity(opportunity(stationId: 'de-weak'),
                BudgetRefusal.confidenceTooLow),
          ],
        ),
        now,
      );

      final feed = store.read();
      expect(feed, hasLength(3),
          reason: '#4151 promised suppressed means "not a push", never '
              '"discarded" — this store is where that stops being a '
              'promise made inside one function call');
      expect(feed.first.wasNotified, isTrue);
      expect(feed.first.refusal, isNull);
      expect(feed[1].refusal, BudgetRefusal.outrankedInWindow);
      expect(feed[2].refusal, BudgetRefusal.confidenceTooLow);
    });

    test('a quiet scan with demotions still records them', () async {
      await store.recordScan(
        BudgetOutcome(demoted: [
          DemotedOpportunity(
              opportunity(net: 0.2), BudgetRefusal.savingBelowFloor),
        ]),
        now,
      );
      final feed = store.read();
      expect(feed, hasLength(1));
      expect(feed.single.wasNotified, isFalse);
      expect(feed.single.refusal, BudgetRefusal.savingBelowFloor);
    });

    test('a scan that found nothing writes nothing', () async {
      await store.recordScan(const BudgetOutcome(), now);
      expect(store.read(), isEmpty);
    });

    test('newest first — a later scan reads above an earlier one', () async {
      await store.recordScan(
          BudgetOutcome(notify: opportunity(stationId: 'de-old', net: 2)), now);
      await store.recordScan(
          BudgetOutcome(notify: opportunity(stationId: 'de-new', net: 2)),
          now.add(const Duration(hours: 3)));

      expect(store.read().map((e) => e.opportunity.stationId),
          ['de-new', 'de-old']);
    });

    test('bounded by count', () async {
      for (var i = 0; i < OpportunityFeedStore.maxEntries + 10; i++) {
        await store.recordScan(
            BudgetOutcome(notify: opportunity(stationId: 'de-$i', net: 2)),
            now);
      }
      expect(store.read(), hasLength(OpportunityFeedStore.maxEntries));
    });

    test('bounded by age — an entry past retention is dropped', () async {
      final old = now.subtract(OpportunityFeedStore.retention * 2);
      await store.recordScan(
          BudgetOutcome(
              notify: opportunity(stationId: 'de-ancient', detectedAt: old)),
          old);
      await store.recordScan(
          BudgetOutcome(notify: opportunity(stationId: 'de-fresh')), now);

      expect(store.read().map((e) => e.opportunity.stationId), ['de-fresh']);
    });

    test('a closed box drops the write instead of throwing', () async {
      // The background-isolate case. A scan must not die because the
      // feed could not be written.
      await Hive.box<dynamic>(HiveBoxes.alerts).close();
      await expectLater(
          store.recordScan(BudgetOutcome(notify: opportunity()), now),
          completes);
      expect(store.read(), isEmpty);
    });

    test('a malformed row does not take the whole feed with it', () async {
      await Hive.box<dynamic>(HiveBoxes.alerts)
          .put(OpportunityFeedStore.storageKey, 'not json at all');
      expect(store.read(), isEmpty);
    });
  });

  group('BudgetStateStore', () {
    const store = BudgetStateStore();

    test('an empty state permits a notification', () {
      // The deliberate failure direction: a budget that cannot read its
      // state and therefore stays silent would turn a storage hiccup
      // into an app that never alerts again, with nothing saying why.
      final state = store.read();
      expect(state.recentNotifications, isEmpty);
      expect(state.lastToldByStationFuel, isEmpty);
    });

    test('round-trips what was sent and to whom', () async {
      final sentAt = now.subtract(const Duration(hours: 1));
      await store.write(
        const BudgetState().recording(opportunity(), sentAt),
        now,
      );

      final back = store.read();
      expect(back.recentNotifications, [sentAt]);
      expect(back.lastToldByStationFuel['de-a:e10'], sentAt);
      expect(back.lastNotification, sentAt);
    });

    test('prunes on write, so a year of scanning does not accumulate',
        () async {
      final ancient = now.subtract(const Duration(days: 30));
      await store.write(
        const BudgetState().recording(opportunity(), ancient),
        now,
      );
      expect(store.read().recentNotifications, isEmpty);
    });

    test('survives the isolate boundary — that is the whole point',
        () async {
      // A budget that forgets what it sent an hour ago is a per-scan
      // filter with a cap of one; the SLA is about a DAY, and a day
      // spans many isolate lifetimes.
      final sentAt = now.subtract(const Duration(minutes: 30));
      await store.write(
          const BudgetState().recording(opportunity(), sentAt), now);

      // Reopen the box the way a fresh isolate would.
      await Hive.box<dynamic>(HiveBoxes.alerts).close();
      await Hive.openBox<dynamic>(HiveBoxes.alerts);

      expect(store.read().lastNotification, sentAt);
    });

    test('a closed box reads empty rather than throwing', () async {
      await Hive.box<dynamic>(HiveBoxes.alerts).close();
      expect(store.read().recentNotifications, isEmpty);
      await expectLater(store.write(const BudgetState(), now), completes);
    });

    test('malformed state reads as empty', () async {
      await Hive.box<dynamic>(HiveBoxes.alerts)
          .put(BudgetStateStore.storageKey, '{{{');
      expect(store.read().recentNotifications, isEmpty);
    });
  });
}
