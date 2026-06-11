// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_charging_log_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/search/presentation/screens/ev_station_detail_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../fixtures/ev_stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #582 phase 3 — the EV station detail screen grows a primary
/// "Log charging" button that navigates to [AddChargingLogScreen]
/// with the station id + display name pre-filled.
///
/// #3174 — originally written against the legacy in-feature copy
/// (`features/ev/.../ev_station_detail_screen.dart`, deleted); migrated
/// to the routed rich [EVStationDetailScreen] it duplicated.

class _EvVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'ev-1',
          name: 'Model EV',
          type: VehicleType.ev,
        ),
      ];
}

class _PreloadedChargingLogs extends ChargingLogs {
  @override
  Future<List<ChargingLog>> build() async => const [];
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  /// Pin a compact (portrait-phone) surface: at the 800px default test
  /// width the rich screen's #2532 responsive layout switches to the
  /// two-pane wide body, whose narrow left pane overflows with this
  /// fixture's long name/address strings. 590x900 is the same compact
  /// surface `ev_station_detail_screen_test.dart` uses — wide enough for
  /// the connectors-card header in the boxy test font, still single-pane.
  void useCompactSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(590, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows "Log charging" button on the EV detail screen',
      (tester) async {
    useCompactSurface(tester);
    final test = standardTestOverrides(favoriteIds: const []);
    when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

    await pumpApp(
      tester,
      const EVStationDetailScreen(station: testEvStation),
      overrides: test.overrides,
    );

    expect(find.byKey(const Key('ev_log_charging_button')), findsOneWidget);
    expect(find.text('Log charging'), findsOneWidget);
  });

  testWidgets(
    'tapping "Log charging" navigates to AddChargingLogScreen pre-filled',
    (tester) async {
      useCompactSurface(tester);
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

      await pumpApp(
        tester,
        const EVStationDetailScreen(station: testEvStation),
        overrides: [
          ...test.overrides,
          vehicleProfileListProvider.overrideWith(() => _EvVehicleList()),
          chargingLogsProvider.overrideWith(() => _PreloadedChargingLogs()),
        ],
      );

      final btn = find.byKey(const Key('ev_log_charging_button'));
      expect(btn, findsOneWidget);
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // The AddChargingLogScreen is now on top of the stack.
      expect(find.byType(AddChargingLogScreen), findsOneWidget);
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('charging_station_field')),
      );
      expect(field.controller?.text, testEvStation.name);
    },
  );
}
