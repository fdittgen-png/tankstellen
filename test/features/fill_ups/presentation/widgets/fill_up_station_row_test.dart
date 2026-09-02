// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_up_station_row.dart';

import '../../../../helpers/pump_app.dart';

/// #3899 — the read-only station row of the "Where you were" section.
void main() {
  group('FillUpStationRow', () {
    testWidgets('renders name, address and the Change action',
        (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: FillUpStationRow(
            stationName: 'SUPER U',
            address: 'Chemin du Portrou • POMEROLS',
            onChange: () => taps++,
          ),
        ),
      );

      expect(find.text('SUPER U'), findsOneWidget);
      expect(find.text('Chemin du Portrou • POMEROLS'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Station'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fill_up_station_row')));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('without a station reads "Pick a station" and opens the '
        'picker on tap', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: FillUpStationRow(
            stationName: null,
            address: null,
            onChange: () => taps++,
          ),
        ),
      );

      expect(find.text('Pick a station'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
      await tester.tap(find.byKey(const Key('fill_up_station_row')));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('survives the en_XA pseudo-locale at 320 dp (#1699)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        Scaffold(
          body: FillUpStationRow(
            stationName: 'Intermarché Contact Marseillan-Plage',
            address: 'Avenue des Campings • MARSEILLAN',
            onChange: () {},
          ),
        ),
        locale: const Locale('en', 'XA'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a 1.3x text scale at 320 dp (#3662)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpApp(
        tester,
        Scaffold(
          body: FillUpStationRow(
            stationName: 'Intermarché Contact Marseillan-Plage',
            address: 'Avenue des Campings • MARSEILLAN',
            onChange: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
