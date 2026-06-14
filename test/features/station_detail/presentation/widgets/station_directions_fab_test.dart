// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_directions_fab.dart';

import '../../../../helpers/pump_app.dart';

/// #3337 — directions must be a prominent, labelled affordance (it was a tiny
/// AppBar icon users struggled to find).
void main() {
  Station station() => const Station(
        id: 's1',
        name: 'Test',
        brand: 'Total',
        street: '1 Rue Test',
        postCode: '75001',
        place: 'Paris',
        lat: 48.86,
        lng: 2.35,
        isOpen: true,
      );

  testWidgets('renders an extended FAB with the directions icon + Navigate '
      'label', (tester) async {
    await pumpApp(tester, StationDirectionsFab(station: station()));

    expect(find.byKey(const Key('station_directions_fab')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.directions), findsOneWidget);
    // The label makes it discoverable (vs the old unlabelled icon).
    expect(find.text('Navigate'), findsOneWidget);
  });
}
