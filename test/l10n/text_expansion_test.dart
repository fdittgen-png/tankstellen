// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_insights_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/setup/presentation/widgets/language_selector.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Pseudo-localization pass for text-expansion overflow (#1699).
///
/// `en_XA` is a synthetic pseudo-locale (`tool/gen_pseudo_arb.dart` →
/// `lib/l10n/app_en_XA.arb`) whose every string is accented and padded
/// ~45% longer than English — the band German / Finnish / Slavic
/// translations occupy. It never ships in the language picker; it
/// exists so this test can pump fixed-size chrome under deliberately
/// long strings.
///
/// Each test pumps a chrome widget under `Locale('en', 'XA')` at a
/// narrow 320 dp viewport (the smallest phone width still in the
/// support matrix) and asserts no `RenderFlex` overflow. A layout that
/// survives `en_XA` at 320 dp survives every real translation; a
/// failure here is real chrome that truncates for non-English users.
/// #3904 — a reliable two-month comparison with the widest figures the
/// month card renders (four-digit km, hours + minutes, a two-decimal
/// consumption with its unit) so every value column is at its widest.
const _monthSummary = MonthlyInsightsSummary(
  currentMonthTripCount: 3,
  previousMonthTripCount: 97,
  currentMonthDriveTime: Duration(hours: 1, minutes: 19),
  previousMonthDriveTime: Duration(hours: 22, minutes: 25),
  currentMonthDistanceKm: 48.0,
  previousMonthDistanceKm: 1039.0,
  currentMonthAvgConsumptionLPer100km: 10.1,
  previousMonthAvgConsumptionLPer100km: 10.6,
  isComparisonReliable: true,
);

void main() {
  const pseudoLocale = Locale('en', 'XA');

  /// Pumps [child] under the pseudo-locale at a 320 dp viewport, then
  /// fails if layout raised an overflow (or any other) exception.
  Future<void> pumpPseudo(
    WidgetTester tester,
    Widget child, {
    List<Object>? overrides,
    String? widgetName,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, child, locale: pseudoLocale, overrides: overrides);

    expect(
      tester.takeException(),
      isNull,
      reason: '${widgetName ?? child.runtimeType} overflows at 320 dp '
          'under the en_XA pseudo-locale — its fixed-size chrome is too '
          'tight for expanded (German / Slavic / Finnish) translations. '
          'Give the offending Row/Column a Flexible/Expanded child, allow '
          'wrapping, or shorten the layout.',
    );
  }

  /// #3662 (llmwiki page 26) — text SCALING is the same bug class in
  /// another axis: a user's 1.3x font setting expands every string at
  /// once. Pumps [child] in plain English at a 1.3x text scale on the
  /// same 320 dp viewport and fails on any overflow. Layouts that
  /// survive the en_XA expansion usually survive large fonts — but
  /// "usually" is not a test.
  Future<void> pumpScaled(
    WidgetTester tester,
    Widget child, {
    List<Object>? overrides,
    String? widgetName,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, child, overrides: overrides);

    expect(
      tester.takeException(),
      isNull,
      reason: '${widgetName ?? child.runtimeType} overflows at 320 dp '
          'under a 1.3x text scale — a user-raised font setting breaks '
          'its fixed-size chrome. Give the offending Row/Column a '
          'Flexible/Expanded child, allow wrapping, or shorten the '
          'layout.',
    );
  }

  group('Text-expansion overflow (pseudo-locale en_XA)', () {
    testWidgets('StationCard — open station', (tester) async {
      await pumpPseudo(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
        widgetName: 'StationCard',
      );
    });

    testWidgets('StationCard — favorite station', (tester) async {
      await pumpPseudo(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
        widgetName: 'StationCard (favorite)',
      );
    });

    testWidgets('ServiceStatusBanner — stale / offline banner',
        (tester) async {
      final result = ServiceResult<List<String>>(
        data: const ['cached'],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isStale: true,
        errors: const [],
      );
      await pumpPseudo(
        tester,
        ServiceStatusBanner(result: result),
        widgetName: 'ServiceStatusBanner',
      );
    });

    testWidgets('LanguageSelector — choice-chip wrap', (tester) async {
      await pumpPseudo(
        tester,
        LanguageSelector(
          selected: AppLanguages.all.first,
          onSelect: (_) {},
        ),
        widgetName: 'LanguageSelector',
      );
    });

    testWidgets('FuelTypeSelector — Germany fuel set', (tester) async {
      await pumpPseudo(
        tester,
        const FuelTypeSelector(),
        overrides: [
          fakeHiveStorageOverride().override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
        widgetName: 'FuelTypeSelector',
      );
    });

    testWidgets('MonthlyInsightsCard — reliable comparison (#3904)',
        (tester) async {
      await pumpPseudo(
        tester,
        const MonthlyInsightsCard(summary: _monthSummary),
        widgetName: 'MonthlyInsightsCard',
      );
    });
  });

  group('Text-scale overflow (1.3x font setting, #3662)', () {
    testWidgets('StationCard — open station', (tester) async {
      await pumpScaled(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
        ),
        widgetName: 'StationCard',
      );
    });

    testWidgets('StationCard — favorite station', (tester) async {
      await pumpScaled(
        tester,
        const StationCard(
          station: testStation,
          selectedFuelType: FuelType.e10,
          isFavorite: true,
        ),
        widgetName: 'StationCard (favorite)',
      );
    });

    testWidgets('ServiceStatusBanner — stale / offline banner',
        (tester) async {
      // #3660 — the wall-clock ratchet: a pinned mid-month instant, not
      // a raw wall-clock read; the banner takes staleness explicitly.
      final result = ServiceResult<List<String>>(
        data: const ['cached'],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 3, 11, 14, 15),
        isStale: true,
        errors: const [],
      );
      await pumpScaled(
        tester,
        ServiceStatusBanner(result: result),
        widgetName: 'ServiceStatusBanner',
      );
    });

    testWidgets('LanguageSelector — choice-chip wrap', (tester) async {
      // The selector's chip Wrap grows VERTICALLY at a raised text
      // scale by design; on the real setup screen it sits inside a
      // SingleChildScrollView (setup_screen.dart), so the scaled pass
      // pumps it in the same container — a bottom overflow here would
      // be a harness artifact, not a defect. Horizontal overflow (the
      // real bug class) still fails.
      await pumpScaled(
        tester,
        SingleChildScrollView(
          child: LanguageSelector(
            selected: AppLanguages.all.first,
            onSelect: (_) {},
          ),
        ),
        widgetName: 'LanguageSelector',
      );
    });

    testWidgets('FuelTypeSelector — Germany fuel set', (tester) async {
      await pumpScaled(
        tester,
        const FuelTypeSelector(),
        overrides: [
          fakeHiveStorageOverride().override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
        widgetName: 'FuelTypeSelector',
      );
    });

    testWidgets('MonthlyInsightsCard — reliable comparison (#3904)',
        (tester) async {
      await pumpScaled(
        tester,
        const MonthlyInsightsCard(summary: _monthSummary),
        widgetName: 'MonthlyInsightsCard',
      );
    });
  });
}
