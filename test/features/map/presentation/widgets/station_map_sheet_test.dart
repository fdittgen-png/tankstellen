// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/core/widgets/amenity_summary.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_sheet.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #4093 (epic #4087) — the map answers "what about that one" OVER the
/// map.
///
/// The promise is the split: the sheet carries the shallow answer a
/// marker tap actually asked for, and the detail screen keeps the deep
/// one. What must not happen is the map being replaced — the user
/// navigates back and has to find their place again.
void main() {
  silenceErrorLoggerSpool();

  final now = DateTime(2026, 9, 16, 14, 30);

  Station station({String? updatedAt, Set<StationAmenity>? amenities}) =>
      Station(
        id: 'st-1',
        name: 'Total Pézenas',
        brand: 'TotalEnergies',
        street: 'Avenue de la Mer',
        postCode: '34120',
        place: 'Pézenas',
        lat: 43.46,
        lng: 3.42,
        dist: 2.5,
        e10: 1.729,
        isOpen: true,
        updatedAt: updatedAt ??
            now.subtract(const Duration(hours: 1)).toIso8601String(),
        amenities: amenities ?? const {},
      );

  Future<AppLocalizations> pumpSheet(WidgetTester tester, Station s) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appClockProvider.overrideWithValue(FixedClock(now))],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StationMapSheet(station: s, fuelType: FuelType.e10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(StationMapSheet)));
  }

  testWidgets('it answers the marker tap: price, where, how far, how old',
      (tester) async {
    final l10n = await pumpSheet(tester, station());

    expect(find.textContaining('1,729'), findsOneWidget,
        reason: 'the number the marker was tapped for');
    expect(find.textContaining('Pézenas'), findsOneWidget);
    expect(find.textContaining('2,5 km'), findsOneWidget);
    // #4092 — price age in words, not a bare stamp. An hour old is
    // inside the six-hour fresh band.
    expect(find.text(l10n.priceFreshnessFresh), findsOneWidget);
  });

  testWidgets('it offers the one action a driver wants from a map, and the '
      'way on to everything else', (tester) async {
    final l10n = await pumpSheet(tester, station());
    expect(find.widgetWithText(FilledButton, l10n.navigate), findsOneWidget);
    expect(find.text(l10n.mapSheetViewDetails), findsOneWidget,
        reason: 'the deep answer stays one tap away rather than being the '
            'only answer');
  });

  testWidgets('facilities appear only when there are any, and compactly',
      (tester) async {
    await pumpSheet(tester, station());
    expect(find.byType(AmenitySummary), findsNothing,
        reason: 'an empty facilities line is a line spent on nothing');

    await pumpSheet(
      tester,
      station(amenities: {
        StationAmenity.shop,
        StationAmenity.carWash,
        StationAmenity.airPump,
        StationAmenity.toilet,
      }),
    );
    expect(find.byType(AmenitySummary), findsOneWidget);
    // Three named on the sheet — it has more room than a result row — and
    // the rest counted.
    expect(find.textContaining('+1'), findsOneWidget);
  });

  testWidgets('a stale price is flagged on the sheet too — the map must not '
      'be the one surface that hides it', (tester) async {
    final l10n = await pumpSheet(
      tester,
      station(updatedAt: now.subtract(const Duration(days: 9)).toIso8601String()),
    );
    expect(find.text(l10n.priceFreshnessStale), findsOneWidget);
  });

  testWidgets('an unreadable stamp says so, rather than implying freshness',
      (tester) async {
    final l10n = await pumpSheet(tester, station(updatedAt: 'gestern'));
    expect(find.text(l10n.priceFreshnessUnknown), findsOneWidget);
    expect(find.text(l10n.priceFreshnessFresh), findsNothing);
  });
}
