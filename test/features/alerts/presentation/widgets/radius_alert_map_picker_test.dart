import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_map_picker.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// #578 phase 3 — RadiusAlertMapPicker widget tests.
///
/// The picker is pushed from the radius-alert create sheet. These
/// tests verify the three visible contracts the sheet depends on:
///
/// 1. The map renders with an initial center (passed in explicitly
///    or resolved from the user-position provider).
/// 2. The "Confirm" AppBar action pops a [LatLng] matching the
///    current map center (simulated via `mapController.move`).
/// 3. The leading "close" IconButton pops with no value (null), so
///    the create sheet's opener receives the cancel signal.
void main() {
  group('RadiusAlertMapPicker (#578 phase 3)', () {
    testWidgets('renders with the injected initial center', (tester) async {
      const start = LatLng(52.5200, 13.4050); // Berlin

      await _pumpPickerRoute(
        tester,
        initialCenter: start,
        mapController: null,
      );

      // FlutterMap is present.
      expect(find.byType(FlutterMap), findsOneWidget);

      // The hint card is visible so users know what to do.
      expect(find.textContaining('Drag the map'), findsOneWidget);

      // AppBar actions match the l10n contract.
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter.latitude, closeTo(52.52, 1e-6));
      expect(map.options.initialCenter.longitude, closeTo(13.405, 1e-6));
    });

    testWidgets('Confirm returns the current map center as a LatLng',
        (tester) async {
      const start = LatLng(52.5200, 13.4050);
      const panned = LatLng(48.8566, 2.3522); // Paris

      final controller = MapController();
      addTearDown(controller.dispose);

      final navigator = await _pumpPickerRoute(
        tester,
        initialCenter: start,
        mapController: controller,
      );

      // Simulate the user panning the map to Paris. The picker
      // listens to MapEvent and updates its tracked center.
      controller.move(panned, 12);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(navigator.poppedWith, isA<LatLng>());
      final popped = navigator.poppedWith as LatLng;
      expect(popped.latitude, closeTo(48.8566, 1e-4));
      expect(popped.longitude, closeTo(2.3522, 1e-4));
    });

    testWidgets('Cancel returns null', (tester) async {
      const start = LatLng(52.5200, 13.4050);

      final navigator = await _pumpPickerRoute(
        tester,
        initialCenter: start,
        mapController: null,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(navigator.poppedWith, isNull);
      expect(navigator.didPop, isTrue);
    });

    testWidgets('falls back to user position when no initial center given',
        (tester) async {
      // No `initialCenter` argument — the widget must read from
      // the user-position provider. We seed a known pos so the
      // FlutterMap's initialCenter is deterministic.
      final navigator = _NavigatorProbe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPositionOverride(lat: 43.46, lng: 3.43),
          ].cast(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.of(context)
                          .push<LatLng>(
                        MaterialPageRoute(
                          builder: (_) => const RadiusAlertMapPicker(),
                        ),
                      );
                      navigator.poppedWith = result;
                      navigator.didPop = true;
                    },
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

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.initialCenter.latitude, closeTo(43.46, 1e-6));
      expect(map.options.initialCenter.longitude, closeTo(3.43, 1e-6));
    });
  });
}

/// Minimal nav probe capturing whatever the picker pops.
class _NavigatorProbe {
  LatLng? poppedWith;
  bool didPop = false;
}

/// Pumps the picker inside a real navigator so `Navigator.pop` has
/// somewhere to pop to. Taps the "open" button to push the picker
/// route, then returns the probe the test can assert against.
Future<_NavigatorProbe> _pumpPickerRoute(
  WidgetTester tester, {
  required LatLng? initialCenter,
  required MapController? mapController,
}) async {
  final probe = _NavigatorProbe();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userPositionNullOverride(),
      ].cast(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<LatLng>(
                    MaterialPageRoute(
                      builder: (_) => RadiusAlertMapPicker(
                        initialCenter: initialCenter,
                        mapController: mapController,
                      ),
                    ),
                  );
                  probe.poppedWith = result;
                  probe.didPop = true;
                },
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
  return probe;
}
