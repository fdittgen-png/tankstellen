// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/background/opportunity_notification_copy.dart';
import 'package:tankstellen/features/alerts/background/opportunity_dispatcher.dart';
import 'package:tankstellen/features/alerts/data/budget_state_store.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';

/// #4183 — the whole chain, driven end to end.
///
/// A price observation in, a notification decision out, with the clock
/// injected — the shape #4164 established. What this holds that no unit
/// test of the budget could: that the budget's promises survive the
/// plumbing. "Suppressed means not a push, never discarded" is a claim
/// about a STORE, and only a test that writes and reads one can check it.
void main() {
  late Directory tmpDir;
  late _RecordingNotifier notifier;
  final now = DateTime.utc(2026, 9, 15, 12);

  const dispatcher = OpportunityDispatcher();

  Opportunity opportunity({
    String stationId = 'de-a',
    String? stationName = 'ARAL Berlin',
    OpportunityKind kind = OpportunityKind.favouriteStation,
    double currentPrice = 1.649,
    double? referencePrice = 1.729,
    double? net = 3.8,
    DataConfidence confidence = DataConfidence.high,
    DateTime? detectedAt,
    // #4302 — settable so a case can drive a grade whose ARB label and
    // apiValue actually differ. The default is the value this fixture
    // always hardcoded, so every existing caller is unchanged.
    String fuelType = 'e10',
  }) {
    final at = detectedAt ?? now;
    return Opportunity(
      kind: kind,
      stationId: stationId,
      stationName: stationName,
      fuelType: fuelType,
      currentPrice: currentPrice,
      reference: OpportunityReference.thresholdYouSet,
      referencePrice: referencePrice,
      grossSaving: net == null ? null : net + 0.4,
      detourCost: net == null ? null : 0.4,
      netSaving: net,
      distanceKm: 3.2,
      priceAge: const DataValue.measured(Duration(minutes: 12)),
      confidence: confidence,
      detectedAt: at,
      expiresAt: at.add(const Duration(hours: 6)),
    );
  }

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('opportunity_dispatch_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    notifier = _RecordingNotifier();
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

  Future<DispatchOutcome> dispatch(List<Opportunity> candidates,
          {DateTime? at, Map<String, NotificationCopy> copyFor = const {}}) =>
      dispatcher.dispatch(
        candidates: [
          for (final o in candidates)
            OpportunityCandidate(o, copy: copyFor[o.stationId]),
        ],
        now: at ?? now,
        notifier: notifier,
        templates: templates,
      );

  // #4302 — `Opportunity.fuelType` holds an apiValue, and five of the
  // seven kinds set it into a notification title. Untranslated that read
  // `STAR - e10` and `diesel dropped at nearby stations`.
  //
  // `OpportunityNotificationCopy.render` had NO test of any kind before
  // this group: its only production caller is the dispatcher's
  // `prebuilt[winner] ?? render(...)` fallback, which the existing cases
  // never reach because they either supply `copyFor` or assert on the
  // station name alone. So these drive `render` directly.
  group('rendered copy names the grade, not its apiValue (#4302)', () {
    /// The five kinds whose ARB title interpolates `{fuelType}` /
    /// `{fuelLabel}`. `refuelSoon` ("Time to refuel") and
    /// `exceptionalLocalPrice` (labelled by station) name no grade.
    const gradeNaming = [
      OpportunityKind.favouriteStation,
      OpportunityKind.localMovement,
      OpportunityKind.bestStopNow,
      OpportunityKind.bestStopOnRoute,
      OpportunityKind.personalBaseline,
    ];

    NotificationCopy? renderFor(
      OpportunityKind kind, {
      String fuelType = 'e10',
      String language = 'en',
    }) =>
        OpportunityNotificationCopy.render(
          opportunity(kind: kind, fuelType: fuelType),
          BackgroundNotificationTemplates.resolveForLanguage(language),
          priceOf: (v) => v.toStringAsFixed(3),
          distanceOf: (v) => '${v.toStringAsFixed(1)} km',
        );

    for (final kind in gradeNaming) {
      test('${kind.name} renders the ARB label, never the apiValue', () {
        final copy = renderFor(kind);

        expect(copy, isNotNull,
            reason: 'a null render here would make every assertion below '
                'pass by not running');
        expect(copy!.title, contains('Super E10'));
        // The apiValue must not survive into the sentence. Checked as a
        // word boundary because `Super E10` legitimately contains "E10".
        expect(copy.title, isNot(matches(RegExp(r'\be10\b'))),
            reason: 'the raw apiValue in a title is the #4302 defect');
      });
    }

    test('the German label reaches the title (#4302)', () {
      // lpg is the probe: German says `Autogas (LPG)` where the apiValue
      // is `lpg` and FuelType.displayName is `GPL / LPG`. For e10 the ARB
      // string merely CONTAINS the apiValue, so it cannot prove the
      // lookup ran — only a grade where they diverge can.
      final copy = renderFor(OpportunityKind.bestStopNow,
          fuelType: 'lpg', language: 'de');

      expect(copy!.title, contains('Autogas (LPG)'));
      expect(copy.title, isNot(contains('GPL / LPG')),
          reason: 'displayName is a French/English hybrid; this path never '
              'used it, and must not start');
      expect(copy.title, isNot(matches(RegExp(r'\blpg\b'))));
    });

    test('an unknown apiValue degrades to itself rather than a gap', () {
      // A blob predating a grade, or a grade this build does not know.
      final copy = renderFor(OpportunityKind.bestStopNow,
          fuelType: 'some_future_grade');

      expect(copy!.title, contains('some_future_grade'),
          reason: 'a label is better than an empty slot or the literal '
              '"null" in a sentence the user reads');
    });

    test('refuelSoon names no grade, so its empty fuelType is harmless',
        () {
      // `trip_opportunity_detector` builds refuelSoon with
      // `fuelType: ''`. That is correct, not a defect: the ARB title is
      // "Time to refuel" and takes no fuel argument at all. Pinned so a
      // future reader does not "fix" it into a fabricated grade.
      final copy = renderFor(OpportunityKind.refuelSoon, fuelType: '');

      expect(copy, isNotNull);
      expect(copy!.title, isNotEmpty);
    });
  });

  group('the chain', () {
    test('one candidate becomes one notification and one feed entry',
        () async {
      final outcome = await dispatch([opportunity()]);

      expect(outcome.notified, isTrue);
      expect(notifier.sent, hasLength(1));
      expect(notifier.sent.single.title, contains('ARAL Berlin'));

      final feed = const OpportunityFeedStore().read();
      expect(feed, hasLength(1));
      expect(feed.single.wasNotified, isTrue);
    });

    test('three candidates produce ONE notification and three feed entries',
        () async {
      // The change this issue exists to make. Before it, the per-station
      // runner fired once per tripped alert, so three alerts crossing in
      // one scan produced three notifications.
      final outcome = await dispatch([
        opportunity(stationId: 'de-a', net: 1.5),
        opportunity(stationId: 'de-b', net: 4.0),
        opportunity(stationId: 'de-c', net: 2.5),
      ]);

      expect(notifier.sent, hasLength(1));
      expect(outcome.demotions, hasLength(2));
      expect(
          outcome.demotions.map((d) => d.reason),
          everyElement(BudgetRefusal.outrankedInWindow));

      final feed = const OpportunityFeedStore().read();
      expect(feed, hasLength(3),
          reason: 'the other two are demoted, not discarded — that is the '
              'promise #4151 made and this store is where it becomes real');
      expect(feed.where((e) => e.wasNotified), hasLength(1));
    });

    test('#4185 — only the SENT candidate records; a refused one must not',
        () async {
      final recorded = <String>[];
      final outcome = await dispatcher.dispatch(
        candidates: [
          OpportunityCandidate(
            opportunity(stationId: 'de-loser', net: 1.0),
            onNotified: () async => recorded.add('de-loser'),
          ),
          OpportunityCandidate(
            opportunity(stationId: 'de-winner', net: 9.0),
            onNotified: () async => recorded.add('de-winner'),
          ),
        ],
        now: now,
        notifier: notifier,
        templates: templates,
      );

      expect(outcome.notified, isTrue);
      expect(recorded, ['de-winner'],
          reason: 'a dedup row for the refused finding would say "we told '
              'you" about something the user never saw (#4185)');
    });

    test('a refused scan records nothing at all', () async {
      final recorded = <String>[];
      // A dispatch with no renderable copy cannot send: the candidate is
      // recorded in the feed with a reason, and its dedup must stay clean.
      final outcome = await dispatcher.dispatch(
        candidates: [
          OpportunityCandidate(
            opportunity(stationName: null, referencePrice: null, net: null),
            onNotified: () async => recorded.add('unrenderable'),
          ),
        ],
        now: now,
        notifier: notifier,
        templates: templates,
      );

      expect(outcome.notified, isFalse);
      expect(recorded, isEmpty);
    });

    test('the best one wins, not the first one', () async {
      await dispatch([
        opportunity(stationId: 'de-cheap-find', net: 1.0),
        opportunity(stationId: 'de-best', net: 9.0),
      ]);
      expect(notifier.sent.single.id, 'de-best'.hashCode);
    });

    test('a scan that finds nothing writes nothing and sends nothing',
        () async {
      final outcome = await dispatch([]);
      expect(outcome.notified, isFalse);
      expect(outcome.recorded, 0);
      expect(notifier.sent, isEmpty);
      expect(const OpportunityFeedStore().read(), isEmpty);
    });
  });

  group('the budget spans scans — the whole point of persisting it', () {
    test('a second scan minutes later is refused, and says why', () async {
      await dispatch([opportunity(stationId: 'de-a')]);
      expect(notifier.sent, hasLength(1));

      final second = await dispatch(
        [opportunity(stationId: 'de-b', detectedAt: now.add(const Duration(minutes: 30)))],
        at: now.add(const Duration(minutes: 30)),
      );

      expect(notifier.sent, hasLength(1),
          reason: 'minInterval is 2 h across ALL kinds; a budget that '
              'forgot the first scan would be a per-scan filter with a '
              'cap of one');
      expect(second.demotions.single.reason, BudgetRefusal.tooSoonAfterLast);

      final feed = const OpportunityFeedStore().read();
      expect(feed, hasLength(2));
      expect(feed.first.refusal, BudgetRefusal.tooSoonAfterLast,
          reason: '"why didn\'t I get an alert" has an answer the user '
              'can open');
    });

    test('the same station stays quiet for perStationQuiet', () async {
      await dispatch([opportunity(stationId: 'de-a')]);

      final later = now.add(const Duration(hours: 3));
      final second = await dispatch(
        [opportunity(stationId: 'de-a', detectedAt: later)],
        at: later,
      );

      expect(second.demotions.single.reason,
          BudgetRefusal.alreadyToldRecently);
      expect(notifier.sent, hasLength(1));
    });

    test('a different station after the interval DOES get through',
        () async {
      await dispatch([opportunity(stationId: 'de-a')]);

      final later = now.add(const Duration(hours: 3));
      await dispatch(
        [opportunity(stationId: 'de-b', detectedAt: later)],
        at: later,
      );

      expect(notifier.sent, hasLength(2),
          reason: 'the budget throttles attention, it does not switch '
              'alerts off');
    });

    test('the daily cap holds across scans', () async {
      var at = now;
      for (var i = 0; i < 6; i++) {
        await dispatch(
          [opportunity(stationId: 'de-$i', detectedAt: at)],
          at: at,
        );
        at = at.add(const Duration(hours: 3));
      }
      expect(notifier.sent, hasLength(const BudgetPolicy().maxPerDay),
          reason: 'alert_delivery_sla caps the day at 3, and six scans '
              'three hours apart all clear minInterval');
    });
  });

  group('refusals are recorded, not swallowed', () {
    test('a saving below the floor never competes', () async {
      final outcome = await dispatch([opportunity(net: 0.10)]);
      expect(outcome.notified, isFalse);
      expect(
          outcome.demotions.single.reason, BudgetRefusal.savingBelowFloor);
      expect(const OpportunityFeedStore().read().single.refusal,
          BudgetRefusal.savingBelowFloor);
    });

    test('a provider with no confidence cannot arrive uninvited', () async {
      final outcome =
          await dispatch([opportunity(confidence: DataConfidence.none)]);
      expect(outcome.notified, isFalse);
      expect(const OpportunityFeedStore().read(), hasLength(1),
          reason: 'a weak signal is still worth having when the user goes '
              'looking for it');
    });

    test('an unrenderable winner is recorded and does NOT spend the slot',
        () async {
      // A station-shaped kind with no station name: nothing honest to
      // put in the copy. It must not become a notification naming an id,
      // and it must not consume the day's budget either.
      await dispatch([opportunity(stationName: null)]);
      expect(notifier.sent, isEmpty);
      expect(const OpportunityFeedStore().read(), hasLength(1));
      expect(const BudgetStateStore().read().recentNotifications, isEmpty,
          reason: 'nothing was sent, so nothing was spent');
    });

    test('a notification channel that throws does not take the scan down',
        () async {
      notifier.throwOnSend = true;
      final outcome = await dispatch([opportunity()]);

      expect(outcome.notified, isFalse);
      expect(const OpportunityFeedStore().read(), hasLength(1),
          reason: 'the finding is real whether or not the channel took it');
      expect(const BudgetStateStore().read().recentNotifications, isEmpty);
    });
  });

  // #4333 B4 — a process killed between the post and the budget write
  // re-notified on the next wake. The slot is now RESERVED before the
  // post, with a pending marker, and committed or released after it.
  group('reservation before the post (#4333)', () {
    Object? pendingOnDisk() {
      final raw = Hive.box<dynamic>(HiveBoxes.alerts)
          .get(BudgetStateStore.storageKey);
      return raw is String ? (jsonDecode(raw) as Map)['pending'] : null;
    }

    test('when the notification is posted, the budget already records it',
        () async {
      BudgetState? atPost;
      final spy = _RecordingNotifier()
        ..onPost = () => atPost = const BudgetStateStore().read();
      await dispatcher.dispatch(
        candidates: [OpportunityCandidate(opportunity())],
        now: now,
        notifier: spy,
        templates: templates,
      );
      expect(atPost?.recentNotifications, [now],
          reason: 'recorded no later than the show');
      expect(pendingOnDisk(), isNull,
          reason: 'committed once the post returned');
    });

    test('a refused post releases the reservation', () async {
      notifier.throwOnSend = true;
      await dispatch([opportunity()]);
      expect(const BudgetStateStore().read().recentNotifications, isEmpty);
      expect(pendingOnDisk(), isNull);
    });

    test('a reservation a killed run left is resolved, keeping the slot — '
        'at most once', () async {
      // Exactly what a run killed between reserving and committing leaves.
      await Hive.box<dynamic>(HiveBoxes.alerts).put(
          BudgetStateStore.storageKey,
          jsonEncode({
            'sent': [now.toIso8601String()],
            'told': {'de-a:e10': now.toIso8601String()},
            'pending': {'id': 7, 'key': 'de-a:e10', 'at': now.toIso8601String()},
          }));

      final later = now.add(const Duration(minutes: 30));
      final outcome = await dispatch([opportunity(detectedAt: later)],
          at: later);

      expect(outcome.notified, isFalse,
          reason: 'the killed run may have shown it: do not show it twice');
      expect(notifier.sent, isEmpty);
      expect(pendingOnDisk(), isNull);
      expect(const BudgetStateStore().read().recentNotifications, [now],
          reason: 'the slot stays spent');
    });
  });

  group('the notification envelope (#4334)', () {
    test("a detector's envelope — its id and deep-link payload — is posted "
        'as built', () async {
      final spy = _RecordingNotifier();
      await dispatcher.dispatch(
        candidates: [
          OpportunityCandidate(
            opportunity(kind: OpportunityKind.exceptionalLocalPrice),
            envelope: (id: 4242, payload: '{"kind":"radius"}'),
          ),
        ],
        now: now,
        notifier: spy,
        templates: templates,
      );
      expect(spy.sent.single.id, 4242);
      expect(spy.payloads.single, '{"kind":"radius"}');
    });

    test('without one, the per-station id scheme and no payload stay',
        () async {
      final spy = _RecordingNotifier();
      await dispatcher.dispatch(
        candidates: [OpportunityCandidate(opportunity())],
        now: now,
        notifier: spy,
        templates: templates,
      );
      expect(spy.sent.single.id, 'de-a'.hashCode);
      expect(spy.payloads.single, isNull);
    });
  });

  test("a detector's own copy is used verbatim", () async {
    // The radius case: one grouped notification over five stations,
    // which a single per-station Opportunity cannot reproduce. The
    // dispatcher decides WHETHER to interrupt; the detector that already
    // knows how to say it best still says it.
    await dispatch(
      [opportunity(kind: OpportunityKind.exceptionalLocalPrice)],
      copyFor: {
        'de-a': (
          title: 'Berlin: 5 stations at or below 1.699 EUR',
          body: 'ARAL 1.649 EUR\nShell 1.659 EUR',
        ),
      },
    );

    expect(notifier.sent.single.title,
        'Berlin: 5 stations at or below 1.699 EUR');
    expect(notifier.sent.single.body, contains('Shell'),
        reason: 'rendering this from one opportunity would have demoted a '
            'five-station roll-up to a one-station line');
  });

  test('a closed alerts box degrades to a no-op, not a crash', () async {
    await Hive.box<dynamic>(HiveBoxes.alerts).close();
    await expectLater(dispatch([opportunity()]), completes);
    expect(notifier.sent, hasLength(1),
        reason: 'the notification still goes out; only the record is lost');
  });
}

/// Records what was posted instead of touching a platform channel.
class _RecordingNotifier implements NotificationService {
  final List<({int id, String title, String body})> sent = [];
  final List<String?> payloads = [];
  bool throwOnSend = false;
  void Function()? onPost;

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    onPost?.call();
    if (throwOnSend) throw StateError('channel unavailable');
    sent.add((id: id, title: title, body: body));
    payloads.add(payload);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}
