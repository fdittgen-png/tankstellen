import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_create_sheet.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('RadiusAlertCreateSheet (#578 phase 2)', () {
    testWidgets('save button builds a RadiusAlert and calls add()',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final fake = _CapturingRadiusAlerts();

      // Seed a cached GPS position so the "Use my location" branch
      // produces a usable center without reaching the geolocator.
      await pumpApp(
        tester,
        RadiusAlertCreateSheet(idGenerator: () => 'fixed-id-123'),
        overrides: [
          ...test.overrides,
          radiusAlertsProvider.overrideWith(() => fake),
          userPositionOverride(lat: 48.85, lng: 2.35, source: 'GPS'),
        ],
      );

      // Fill the label field.
      await tester.enterText(
        find.widgetWithText(TextField, 'Label (e.g. Home diesel)'),
        'Home diesel',
      );
      await tester.pump();

      // Threshold field — overwrite the seed value.
      await tester.enterText(
        find.widgetWithText(TextField, 'Threshold (€/L)'),
        '1.499',
      );
      await tester.pump();

      // Bind the center to the cached GPS position.
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();

      // Save.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(fake.addedAlerts, hasLength(1));
      final a = fake.addedAlerts.single;
      expect(a.id, 'fixed-id-123');
      expect(a.label, 'Home diesel');
      expect(a.threshold, closeTo(1.499, 1e-9));
      expect(a.centerLat, closeTo(48.85, 1e-9));
      expect(a.centerLng, closeTo(2.35, 1e-9));
      // Default fuel type (diesel) and default radius (10 km).
      expect(a.fuelType, 'diesel');
      expect(a.radiusKm, 10);
    });

    testWidgets('save is disabled until label + center are set',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final fake = _CapturingRadiusAlerts();

      await pumpApp(
        tester,
        const RadiusAlertCreateSheet(),
        overrides: [
          ...test.overrides,
          radiusAlertsProvider.overrideWith(() => fake),
          userPositionNullOverride(),
        ],
      );

      // No label, no center → save must be disabled.
      final saveButton =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('Pick-on-map returns a LatLng and enables Save (#578 phase 3)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final fake = _CapturingRadiusAlerts();

      // Stub the map-picker so we do not need to build the
      // FlutterMap widget tree inside the create-sheet test. The
      // stub synchronously returns a deterministic LatLng, which is
      // exactly what a user-confirmed picker would hand back.
      const picked = LatLng(52.5200, 13.4050);

      await pumpApp(
        tester,
        RadiusAlertCreateSheet(
          idGenerator: () => 'map-id-1',
          mapPickerOpener: (_) async => picked,
        ),
        overrides: [
          ...test.overrides,
          radiusAlertsProvider.overrideWith(() => fake),
          userPositionNullOverride(),
        ],
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Label (e.g. Home diesel)'),
        'Berlin diesel',
      );
      await tester.pump();

      // Before picking on the map, Save must still be disabled —
      // label alone is not enough because no center has been set.
      FilledButton save = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(save.onPressed, isNull,
          reason: 'label only → save still disabled before a center exists');

      // Tap the map-picker button; the stub pops the fake LatLng
      // straight back into the sheet.
      await tester.tap(find.text('Pick on map'));
      await tester.pumpAndSettle();

      // Save is now enabled because the picker populated the center.
      save = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(save.onPressed, isNotNull,
          reason: 'picked LatLng should unlock Save');

      // The "Map location" caption is what tells the user which
      // source is currently bound to the alert.
      expect(find.text('Map location'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(fake.addedAlerts, hasLength(1));
      final a = fake.addedAlerts.single;
      expect(a.centerLat, closeTo(52.52, 1e-6));
      expect(a.centerLng, closeTo(13.405, 1e-6));
    });

    testWidgets('Pick-on-map cancel keeps the sheet empty (#578 phase 3)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final fake = _CapturingRadiusAlerts();

      await pumpApp(
        tester,
        RadiusAlertCreateSheet(
          mapPickerOpener: (_) async => null, // user cancelled
        ),
        overrides: [
          ...test.overrides,
          radiusAlertsProvider.overrideWith(() => fake),
          userPositionNullOverride(),
        ],
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Label (e.g. Home diesel)'),
        'Nowhere',
      );
      await tester.pump();

      await tester.tap(find.text('Pick on map'));
      await tester.pumpAndSettle();

      // Save must still be disabled — a cancelled picker must not
      // leave a stale (0,0) center behind.
      final save = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(save.onPressed, isNull);
      expect(find.text('Map location'), findsNothing);
    });

    testWidgets('cancel button dismisses without calling add()',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      final fake = _CapturingRadiusAlerts();

      // Wrap in a Builder so we can push the sheet via showModalBottomSheet
      // and verify the route pops.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            radiusAlertsProvider.overrideWith(() => fake),
            userPositionOverride(lat: 48.85, lng: 2.35),
          ].cast(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => RadiusAlertCreateSheet.show(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(RadiusAlertCreateSheet), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(RadiusAlertCreateSheet), findsNothing);
      expect(fake.addedAlerts, isEmpty);
    });
  });
}

class _CapturingRadiusAlerts extends RadiusAlerts {
  final List<RadiusAlert> addedAlerts = [];

  @override
  Future<List<RadiusAlert>> build() async => const [];

  @override
  Future<void> add(RadiusAlert alert) async {
    addedAlerts.add(alert);
    state = AsyncValue.data([alert]);
  }
}
