// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/features/consumption/domain/trip_verdict.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_verdict_prompt_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #3501 (epic #3498) — the 3-tap post-trip verdict prompt + persistence.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('verdict_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'trips_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  TripHistoryEntry entry({String? verdict}) => TripHistoryEntry(
        id: 't1',
        vehicleId: null,
        summary: TripSummary(
          distanceKm: 10,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          avgLPer100Km: 6.0,
          fuelLitersConsumed: 0.6,
          startedAt: DateTime(2026, 7, 5, 8),
          endedAt: DateTime(2026, 7, 5, 8, 30),
        ),
        verdict: verdict,
      );

  test('verdict round-trips through the entry JSON; legacy entries read null',
      () {
    final withV = entry(verdict: 'smooth');
    final decoded = TripHistoryEntry.fromJson(withV.toJson());
    expect(decoded.verdict, 'smooth');
    final legacyJson = entry().toJson();
    expect(legacyJson.containsKey('verdict'), isFalse,
        reason: 'unanswered trips add zero bytes');
    expect(TripHistoryEntry.fromJson(legacyJson).verdict, isNull);
  });

  test('saveVerdict persists onto an existing row; missing row is a no-op',
      () async {
    final repo = TripHistoryRepository(box: box);
    await repo.save(entry());
    expect(await repo.saveVerdict('t1', TripVerdict.aggressive), isTrue);
    expect(repo.loadAll().single.verdict, 'aggressive');
    expect(await repo.saveVerdict('ghost', TripVerdict.smooth), isFalse);
  });

  // Widget tests avoid real Hive IO inside the test zone entirely (it never
  // completes there): the notifier is faked and call-recorded, persistence
  // itself is proven by the plain test()s above.
  late _FakeTripHistoryList fakeList;
  Widget host(Widget child) {
    fakeList = _FakeTripHistoryList();
    return ProviderScope(
      overrides: [
        tripHistoryListProvider.overrideWith(() => fakeList),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders nothing once a verdict (incl. skipped) is persisted',
      (tester) async {
    await tester.pumpWidget(host(
      const TripVerdictPromptCard(entryId: 't1', verdict: 'skipped'),
    ));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('tapping a chip records the verdict and thanks the driver',
      (tester) async {
    await tester.pumpWidget(host(
      const TripVerdictPromptCard(entryId: 't1', verdict: null),
    ));
    expect(find.byKey(const Key('tripVerdictSmooth')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tripVerdictSmooth')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tripVerdictThanks')), findsOneWidget);
    expect(fakeList.calls, [('t1', TripVerdict.smooth)],
        reason: 'the tap must reach the notifier exactly once');
  });

  testWidgets('dismissing records skipped so the prompt never nags twice',
      (tester) async {
    await tester.pumpWidget(host(
      const TripVerdictPromptCard(entryId: 't1', verdict: null),
    ));
    await tester.tap(find.byKey(const Key('tripVerdictDismiss')));
    await tester.pumpAndSettle();

    expect(fakeList.calls, [('t1', TripVerdict.skipped)]);
    expect(find.byKey(const Key('tripVerdictThanks')), findsNothing,
        reason: 'a dismissal is not thanked, just hidden');
  });
}

/// Call-recording fake — the widget contract is "one notifier call per tap";
/// Hive persistence is proven by the plain test()s above.
class _FakeTripHistoryList extends TripHistoryList {
  final List<(String, TripVerdict)> calls = [];

  @override
  List<TripHistoryEntry> build() => const [];

  @override
  Future<void> setVerdict(String id, TripVerdict verdict) async {
    calls.add((id, verdict));
  }
}
