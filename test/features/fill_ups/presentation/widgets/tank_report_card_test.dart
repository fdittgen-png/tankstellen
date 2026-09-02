// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3616 — the tank-report card renders the pump headline, the trend vs
// the previous tank, coverage, the behavior hints WITH the partial-
// coverage caveat, and the calibration residual; and it renders nothing
// before a first window closes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_unit.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/providers/consumption_display_provider.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/tank_report_card.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_report_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

FillUp _fill(int day, double odo) => FillUp(
      id: 'f$day',
      date: DateTime(2026, 7, day),
      liters: 40,
      totalCost: 70,
      odometerKm: odo,
      fuelType: FuelType.e10,
    );

TankPeriod _period({double liters = 50, double km = 500}) => TankPeriod(
      opening: _fill(1, 1000),
      closing: _fill(7, 1000 + km),
      distanceKm: km,
      liters: liters,
      pumpedCost: 88,
    );

const _behavior = TankBehavior(
  tripCount: 3,
  recordedKm: 200,
  coverageShare: 0.4,
  recordedLPer100Km: 8.0,
  highRpmShare: 0.3,
  idleShare: 0.05,
  harshPer100Km: 2,
  coldStartCount: 1,
);

Widget _host(TankReport report) => ProviderScope(
      overrides: [tankReportProvider.overrideWith((_) => report)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TankReportCard()),
      ),
    );

void main() {
  testWidgets('renders nothing before the first closed window',
      (tester) async {
    await tester.pumpWidget(_host(TankReport.empty));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('full report: headline, upward trend, coverage, hint with '
      'caveat, calibration residual', (tester) async {
    final report = TankReport(
      latest: _period(liters: 60), // 12.0 L/100km
      latestBehavior: _behavior,
      evolution: TankEvolution(
        current: _period(liters: 60),
        currentBehavior: _behavior,
        previous: _period(liters: 50), // 10.0 → delta +2.0
        previousBehavior: const TankBehavior(
          tripCount: 2,
          recordedKm: 180,
          coverageShare: 0.36,
          recordedLPer100Km: 7.0,
          highRpmShare: 0.1,
          idleShare: 0.04,
          harshPer100Km: 1,
          coldStartCount: 1,
        ),
        explanations: const [
          TankExplanation(
              factor: TankFactor.highRpm,
              current: 0.3,
              previous: 0.1,
              salience: 4),
        ],
      ),
      calibration: const PumpCalibration(factor: 1.25, samples: 2),
    );
    await tester.pumpWidget(_host(report));

    expect(find.text('Tank report'), findsOneWidget);
    expect(find.text('12,0 L/100 km'), findsOneWidget);
    expect(find.text('2,0 L/100 km more than the previous tank'),
        findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    // #3904 — plain-language recorded-trips lines.
    expect(find.text('Recorded trips cover 40 % of this tank'), findsOneWidget);
    expect(find.text('Recorded trips: 8,0 L/100 km'), findsOneWidget);
    expect(find.text('High-RPM share 30 % (was 10 %)'), findsOneWidget);
    expect(
        find.textContaining('spontaneous and cover only part'), findsOneWidget,
        reason: '40%/36% coverage must carry the honesty caveat');
    // factor 1.25 = the pump burned 25 % MORE than the recordings claimed.
    expect(find.text('Your recorded trips underestimate consumption by 25 %'),
        findsOneWidget);
  });

  testWidgets('recordings above pump truth read as "overestimate" (#3904)',
      (tester) async {
    final report = TankReport(
      latest: _period(liters: 60),
      latestBehavior: _behavior,
      evolution: null,
      // pump ÷ recorded = 0.8 → the recordings claimed 20 % MORE.
      calibration: const PumpCalibration(factor: 0.8, samples: 2),
    );
    await tester.pumpWidget(_host(report));
    expect(find.text('Your recorded trips overestimate consumption by 20 %'),
        findsOneWidget);
    expect(find.textContaining('underestimate'), findsNothing);
  });

  testWidgets('headline + recorded-trips figures follow the consumption '
      'unit setting (#3889/#3904)', (tester) async {
    final report = TankReport(
      latest: _period(liters: 60), // 12.0 L/100 km ≈ 24 mpg (UK)
      latestBehavior: _behavior, // 8.0 L/100 km ≈ 35 mpg (UK)
      evolution: null,
      calibration: null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tankReportProvider.overrideWith((_) => report),
          consumptionDisplaySettingProvider.overrideWith(
            () => _FixedDisplay(ConsumptionUnit.mpgUk),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TankReportCard()),
        ),
      ),
    );
    expect(find.text('24 mpg (UK)'), findsOneWidget);
    expect(find.text('Recorded trips: 35 mpg (UK)'), findsOneWidget);
    expect(find.textContaining('L/100 km'), findsNothing,
        reason: 'the headline and the recorded-trips line render in the '
            'chosen unit, never a literal L/100 km');
  });

  testWidgets('first closed window: no-previous line, no hints',
      (tester) async {
    final report = TankReport(
      latest: _period(),
      latestBehavior: _behavior,
      evolution: null,
      calibration: null,
    );
    await tester.pumpWidget(_host(report));
    expect(find.text('Evolution appears after your next full tank.'),
        findsOneWidget);
    expect(find.text('What the recordings suggest'), findsNothing);
  });
}

/// A consumption-unit setting pinned to [unit], no SharedPreferences.
class _FixedDisplay extends ConsumptionDisplaySetting {
  _FixedDisplay(this.unit);
  final ConsumptionUnit unit;

  @override
  ConsumptionDisplay build() => ConsumptionDisplay(unitOverride: unit);
}
