// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_pip_price_layout.dart';

import '../../../../helpers/pump_app.dart';

/// #3257 pt2 — the huge-price PiP radar layout discloses the lead's price
/// freshness (the upstream `updatedAt`, search-card parity). A corridor-
/// cached lead can be up to 1 h stale in polled countries; the PiP used to
/// give no signal at all.
void main() {
  Station station({String? updatedAt}) => Station(
        id: 'pip-stn',
        name: 'Tankstelle Mitte',
        brand: 'Aral',
        street: 'Hauptstr',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.5,
        lng: 13.4,
        e10: 1.789,
        isOpen: true,
        updatedAt: updatedAt,
      );

  Widget layout(Station s) => TripRecordingPipPriceLayout(
        station: s,
        fuel: FuelType.e10,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        distanceMeters: 250,
        radiusMeters: 3000,
      );

  testWidgets('shows "Updated {time}" when the lead carries updatedAt',
      (tester) async {
    await pumpApp(tester, layout(station(updatedAt: '10:30')));
    expect(find.textContaining('Updated 10:30'), findsOneWidget);
  });

  testWidgets('omits the freshness line when updatedAt is absent',
      (tester) async {
    await pumpApp(tester, layout(station()));
    expect(find.textContaining('Updated'), findsNothing);
  });
}
