// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3904 — a degraded OBD2 trip row says in plain words WHY its figures
// are estimates: a one-line subtitle under the metrics, in the stripe
// colour, next to the (kept) warning icon + tooltip. Healthy OBD2 and
// GPS-only rows carry no such line.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trajet_row.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trajet_stripe_colors.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';

const _subtitleKey = ValueKey('trajet_obd2_degraded_subtitle');
const _iconKey = ValueKey('trajet_obd2_degraded_icon');

TripHistoryEntry _entry({
  required TripKind kind,
  String? adapterMac,
  double maxRpm = 0,
}) =>
    TripHistoryEntry(
      id: 'trip-$kind-$maxRpm',
      vehicleId: 'v1',
      adapterMac: adapterMac,
      summary: TripSummary(
        distanceKm: 21.8,
        maxRpm: maxRpm,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        kind: kind,
        startedAt: DateTime(2026, 9, 1, 19, 22),
        endedAt: DateTime(2026, 9, 1, 20, 5),
      ),
    );

Widget _host(TripHistoryEntry entry) => Builder(
      builder: (context) => TrajetRow(
        entry: entry,
        vehicle: null,
        l: AppLocalizations.of(context),
        theme: Theme.of(context),
        onTap: () {},
      ),
    );

void main() {
  testWidgets('degraded OBD2 trip: subtitle under the metrics, in the '
      'stripe colour, icon + tooltip kept', (tester) async {
    // Adapter present, not one RPM sample — the drop-at-start signature.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: _host(
            _entry(kind: TripKind.gpsPlusObd2, adapterMac: 'AA:BB'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_subtitleKey), findsOneWidget);
    expect(find.text('No engine data — GPS estimate'), findsOneWidget);
    final subtitle = tester.widget<Text>(find.byKey(_subtitleKey));
    expect(subtitle.style?.color, TrajetStripeColors.degradedLight,
        reason: 'the subtitle wears the stripe colour, so the red stripe, '
            'the icon and the line read as one signal');

    // The #3835 affordances stay: icon + tooltip.
    expect(find.byKey(_iconKey), findsOneWidget);
    expect(find.byType(Tooltip), findsOneWidget);
  });

  testWidgets('healthy OBD2 trip carries no subtitle', (tester) async {
    await pumpApp(
      tester,
      _host(_entry(kind: TripKind.gpsPlusObd2, maxRpm: 3200)),
    );
    expect(find.byKey(_subtitleKey), findsNothing);
    expect(find.byKey(_iconKey), findsNothing);
  });

  testWidgets('GPS-only trip carries no subtitle', (tester) async {
    await pumpApp(tester, _host(_entry(kind: TripKind.gpsOnly)));
    expect(find.byKey(_subtitleKey), findsNothing);
    expect(find.byKey(_iconKey), findsNothing);
  });
}
