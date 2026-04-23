import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_charging_log_screen.dart';
import 'package:tankstellen/features/consumption/providers/charging_logs_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/ev/presentation/screens/ev_station_detail_screen.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../fixtures/ev_stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #582 phase 3 — the EV station detail screen grows a primary
/// "Log charging" button that navigates to [AddChargingLogScreen]
/// with the station id + display name pre-filled.

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

  testWidgets('shows "Log charging" button on the EV detail screen',
      (tester) async {
    final test = standardTestOverrides(favoriteIds: const []);
    when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

    await pumpApp(
      tester,
      const EvStationDetailScreen(station: testEvStation),
      overrides: test.overrides,
    );

    expect(find.byKey(const Key('ev_log_charging_button')), findsOneWidget);
    expect(find.text('Log charging'), findsOneWidget);
  });

  testWidgets(
    'tapping "Log charging" navigates to AddChargingLogScreen pre-filled',
    (tester) async {
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
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
