// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/pick_station_candidates.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/pick_station_sections.dart';

import '../../../../helpers/pump_app.dart';

/// #3906 — picker rows and headers: structure, localized subtitle, and
/// text-expansion survival (en_XA at 320 dp, 1.3x scale).
const _station = Station(
  id: 'super-u-1',
  name: 'Super U Pomerols',
  brand: 'SUPER U',
  street: 'Chemin du Portrou',
  postCode: '34810',
  place: 'POMEROLS',
  lat: 43.37,
  lng: 3.49,
  e10: 1.999,
);

PickStationEntry _entry({double? distanceKm, DateTime? lastFillUpDate}) =>
    PickStationEntry(
      id: _station.id,
      title: 'SUPER U',
      station: _station,
      address: 'Chemin du Portrou • POMEROLS',
      distanceKm: distanceKm,
      lastFillUpDate: lastFillUpDate,
    );

Widget _column(List<Widget> children) => Scaffold(
      body: ListView(children: children),
    );

void main() {
  testWidgets('tile renders title, address, distance and the last fill-up '
      'date; tap fires', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      _column([
        PickStationEntryTile(
          entry: _entry(distanceKm: 2.3, lastFillUpDate: DateTime(2026, 8, 21)),
          onTap: () => taps++,
        ),
      ]),
    );
    expect(find.text('SUPER U'), findsOneWidget);
    expect(find.textContaining('Chemin du Portrou • POMEROLS'), findsOneWidget);
    expect(find.textContaining('Last fill-up: Aug 21, 2026'), findsOneWidget);
    expect(find.byKey(const Key('pick_station_distance_super-u-1')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('pick_station_tile_super-u-1')));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('fr: the last fill-up date is the French medium date',
      (tester) async {
    await pumpApp(
      tester,
      _column([
        PickStationEntryTile(
          entry: _entry(lastFillUpDate: DateTime(2026, 8, 21)),
          onTap: () {},
        ),
      ]),
      locale: const Locale('fr'),
    );
    expect(find.textContaining('21 août 2026'), findsOneWidget);
  });

  testWidgets('headers, hint and tiles survive en_XA at 320 dp (#1699)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(
      tester,
      _column([
        const PickStationSectionHeader(text: 'Last station'),
        PickStationEntryTile(
          entry: _entry(distanceKm: 12.3, lastFillUpDate: DateTime(2026, 8, 21)),
          icon: Icons.history,
          onTap: () {},
        ),
        const PickStationSectionHeader(text: 'Nearby'),
        const PickStationSectionHint(
          text: 'No recent search — search for stations on the Search tab '
              'and the nearest ones will appear here.',
        ),
      ]),
      locale: const Locale('en', 'XA'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tiles survive a 1.3x text scale at 320 dp (#3662)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      _column([
        PickStationEntryTile(
          entry: _entry(distanceKm: 123.4, lastFillUpDate: DateTime(2026, 8, 21)),
          onTap: () {},
        ),
      ]),
    );
    expect(tester.takeException(), isNull);
  });
}
