import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
