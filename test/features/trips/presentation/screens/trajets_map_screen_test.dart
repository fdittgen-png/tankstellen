// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/presentation/screens/trajets_map_screen.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';

import '../../../../helpers/pump_app.dart';

/// The trips map reads every selected trip through the worker-isolate
/// loader (#3882) — it never full-decodes trips inside its build — and
/// says so while the decode runs.

class _Loader extends TripDetailLoader {
  _Loader(this._value);
  final AsyncValue<TripHistoryEntry?> _value;

  @override
  AsyncValue<TripHistoryEntry?> build(String id) => _value;
}

TripHistoryEntry _noGpsTrip(String id) => TripHistoryEntry(
      id: id,
      vehicleId: null,
      summary: const TripSummary(
        distanceKm: 1,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        avgLPer100Km: null,
        fuelLitersConsumed: null,
        startedAt: null,
        endedAt: null,
      ),
      samples: const [],
    );

void main() {
  testWidgets('shows progress, and no export, while a trip still decodes',
      (tester) async {
    await pumpApp(
      tester,
      const TrajetsMapScreen(tripIds: ['a', 'b']),
      overrides: [
        tripDetailLoaderProvider.overrideWith2(
            (_) => _Loader(const AsyncLoading<TripHistoryEntry?>())),
      ],
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final share = tester.widget<IconButton>(
        find.byKey(const Key('trajets_map_share_gpx')));
    expect(share.onPressed, isNull);
  });

  testWidgets('renders from the loaded entries once every decode landed',
      (tester) async {
    await pumpApp(
      tester,
      const TrajetsMapScreen(tripIds: ['a']),
      overrides: [
        tripDetailLoaderProvider
            .overrideWith2((_) => _Loader(AsyncData(_noGpsTrip('a')))),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // A trip without GPS samples → the screen's own empty state.
    expect(find.text('None of the selected trajets carry GPS samples.'),
        findsOneWidget);
  });
}
