// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/consumption_stats_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/tank_report_card.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_report_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';
import '../../fixtures/physical_tank_fixtures.dart';

void main() {
  setUp(() => PriceFormatter.setCountry('GB'));
  for (final locale in [
    const Locale('en'),
    const Locale('de'),
    const Locale('fr'),
  ]) {
    testWidgets(
      'first partial gives actionable unknown consumption in $locale',
      (tester) async {
        final stats = ConsumptionStats.fromFillUps([
          physicalFill('a', 1, 15, 10000, full: false),
          physicalFill('b', 8, 27.2, 10597),
        ]);
        await pumpApp(
          tester,
          SingleChildScrollView(child: ConsumptionStatsCard(stats: stats)),
          locale: locale,
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(ConsumptionStatsCard)),
        );
        expect(find.text(l.consumptionStatsNeedsFullWindow), findsOneWidget);
        expect(stats.avgConsumptionL100km, isNull);
        expect(find.text('0.00'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('real physical report displays 7.07, 597 km and 42.2 L', (
    tester,
  ) async {
    final fills = [
      physicalFill('a', 1, 40, 10000),
      physicalFill('p', 3, 15, 10250, full: false),
      physicalFill('synthetic', 4, 6, 10300, correction: true),
      physicalFill('b', 8, 27.2, 10597),
    ];
    final report = buildTankReport(fillUps: fills, tripSummariesById: const {});
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: Column(
          children: [
            ConsumptionStatsCard(stats: ConsumptionStats.fromFillUps(fills)),
            const TankReportCard(),
          ],
        ),
      ),
      overrides: [tankReportProvider.overrideWith((_) => report)],
    );
    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(labels, contains('7.07'));
    expect(labels, contains('597'));
    expect(labels, contains('42.2'));
    expect(
      report.calibration,
      isNull,
      reason: 'no recordings do not invalidate physical aggregate',
    );
    expect(tester.takeException(), isNull);
  });
}
