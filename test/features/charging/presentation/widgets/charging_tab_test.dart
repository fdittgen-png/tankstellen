// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/charging/presentation/widgets/charging_tab.dart';
import 'package:tankstellen/features/charging/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/confirm_delete.dart';
import '../../../../helpers/mock_providers.dart';

/// #3989 — the charging tab gets the fuel tab's treatment: a localized
/// error state with a retry, and the #3664 capture-and-restore undo on
/// swipe-delete. Both paths were untested before (and the error path
/// showed a raw `$e` in English).
ChargingLog _log(String id) => ChargingLog(
      id: id,
      vehicleId: 'v1',
      date: DateTime.utc(2026, 9, 1),
      kWh: 30,
      costEur: 12.5,
      chargeTimeMin: 40,
      odometerKm: 12000,
    );

/// In-memory notifier: the tab talks to [ChargingLogs] only through
/// `remove` / `add`, so no store is needed to prove the undo round-trip.
class _FakeChargingLogs extends ChargingLogs {
  _FakeChargingLogs(this.logs);
  List<ChargingLog> logs;
  @override
  Future<List<ChargingLog>> build() async => logs;
  @override
  Future<void> remove(String id) async {
    logs = logs.where((l) => l.id != id).toList();
    state = AsyncValue.data(logs);
  }
  @override
  Future<void> add(ChargingLog log) async {
    logs = [...logs.where((l) => l.id != log.id), log];
    state = AsyncValue.data(logs);
  }
}

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  required AsyncValue<List<ChargingLog>> async,
  _FakeChargingLogs? notifier,
}) async {
  late AppLocalizations l;
  final test = standardTestOverrides();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...test.overrides.cast(),
      if (notifier != null)
        chargingLogsProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        l = AppLocalizations.of(context);
        return Scaffold(body: ChargingTab(async: async, l: l));
      }),
    ),
  ));
  await tester.pump();
  return l;
}

void main() {
  testWidgets('a load failure shows a localized error with a retry, not a '
      'raw exception', (tester) async {
    final l = await _pump(tester,
        async: AsyncValue.error(Exception('boom'), StackTrace.empty));
    expect(find.byKey(const Key('charging_error_state')), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing,
        reason: 'the raw exception never reaches the user');
    expect(find.text(l.retry), findsOneWidget);
    expect(find.byKey(const Key('charging_retry')), findsOneWidget);
  });

  testWidgets('swipe-delete offers Undo for the deleted session, and Undo '
      'restores it', (tester) async {
    final notifier = _FakeChargingLogs([_log('a')]);
    final l = await _pump(tester,
        async: AsyncValue.data([_log('a')]), notifier: notifier);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await confirmPendingDelete(tester); // #3682
    await tester.pumpAndSettle();
    expect(notifier.logs, isEmpty, reason: 'the swipe deleted it');
    expect(find.text(l.chargingLogDeletedUndoSnackbar), findsOneWidget);

    await tester.tap(find.text(l.undo));
    await tester.pumpAndSettle();
    expect(notifier.logs.map((x) => x.id), ['a'],
        reason: 'Undo re-adds the captured log under the same id');
  });
}
