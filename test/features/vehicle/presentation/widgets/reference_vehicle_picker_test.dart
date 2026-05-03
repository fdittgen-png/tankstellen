import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/reference_vehicle_catalog_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/reference_vehicle_picker.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [ReferenceVehiclePicker] (#1372 phase 3).
///
/// We override the catalog provider with a hand-built fixture so each
/// case drives the sheet through a known catalog rather than the
/// 50-entry shipping JSON. Loading and empty-results branches are
/// covered explicitly.
void main() {
  // Test fixture — three known entries spanning two makes so the
  // case-insensitive substring filter has something to chew on.
  const e1 = ReferenceVehicle(
    make: 'Peugeot',
    model: '208',
    generation: 'II',
    yearStart: 2019,
    displacementCc: 1200,
    fuelType: 'petrol',
    transmission: 'manual',
  );
  const e2 = ReferenceVehicle(
    make: 'Peugeot',
    model: '3008',
    generation: 'II',
    yearStart: 2016,
    yearEnd: 2023,
    displacementCc: 1600,
    fuelType: 'diesel',
    transmission: 'automatic',
  );
  const e3 = ReferenceVehicle(
    make: 'Renault',
    model: 'Clio',
    generation: 'V',
    yearStart: 2019,
    displacementCc: 999,
    fuelType: 'petrol',
    transmission: 'manual',
  );

  /// Pump the picker sheet behind a launcher button so the modal
  /// router lifecycle is exercised faithfully (mirrors how callers use
  /// the static `show()` helper from the edit-vehicle screen).
  Future<ReferenceVehicle?> pumpPickerSheet(
    WidgetTester tester, {
    AsyncValue<List<ReferenceVehicle>>? catalogValue,
  }) async {
    ReferenceVehicle? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referenceVehicleCatalogProvider.overrideWith((ref) {
            // overrideWith on a Future provider takes a function
            // returning a Future; collapse the AsyncValue into a
            // matching resolution. The loading branch returns a
            // never-completing future so the spinner stays visible
            // for the test pump.
            final value = catalogValue ??
                const AsyncValue<List<ReferenceVehicle>>.data(
                    [e1, e2, e3]);
            return value.when(
              data: (v) => Future<List<ReferenceVehicle>>.value(v),
              loading: () => Completer<List<ReferenceVehicle>>().future,
              error: (e, _) =>
                  Future<List<ReferenceVehicle>>.error(e),
            );
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await ReferenceVehiclePicker.show(context);
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
    // Two pumps — one for the modal route push, one to settle the
    // bottom sheet animation just enough to make widgets findable
    // without fully draining timers (we may have a never-completing
    // loading future on the loading-state test).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return result;
  }

  group('ReferenceVehiclePicker', () {
    testWidgets('renders header + search field + list', (tester) async {
      await pumpPickerSheet(tester);

      expect(find.byType(ReferenceVehiclePicker), findsOneWidget);
      // Title row.
      expect(find.text('Pick from catalog'), findsOneWidget);
      // Search input.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search make or model'), findsOneWidget);
      // List of tiles.
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('empty search shows the full catalog', (tester) async {
      await pumpPickerSheet(tester);

      // All three fixture entries are visible.
      expect(find.text('Peugeot 208'), findsOneWidget);
      expect(find.text('Peugeot 3008'), findsOneWidget);
      expect(find.text('Renault Clio'), findsOneWidget);
    });

    testWidgets(
        'search is case-insensitive on make + model + generation '
        '(substring match)', (tester) async {
      await pumpPickerSheet(tester);

      // Lowercase brand — both Peugeot rows match, Renault filters out.
      await tester.enterText(find.byType(TextField), 'peugeot');
      await tester.pump();

      expect(find.text('Peugeot 208'), findsOneWidget);
      expect(find.text('Peugeot 3008'), findsOneWidget);
      expect(find.text('Renault Clio'), findsNothing);

      // Substring on a model name narrows further.
      await tester.enterText(find.byType(TextField), '3008');
      await tester.pump();

      expect(find.text('Peugeot 208'), findsNothing);
      expect(find.text('Peugeot 3008'), findsOneWidget);
      expect(find.text('Renault Clio'), findsNothing);

      // Generation token also matches (substring on the haystack).
      await tester.enterText(find.byType(TextField), 'V');
      await tester.pump();

      // 'V' substring matches 'V' (Clio gen) AND 'Peugeot' (the v),
      // so we just verify Clio is present and it's at least one row.
      expect(find.text('Renault Clio'), findsOneWidget);
    });

    testWidgets('tap on a tile pops the sheet with the tapped entry',
        (tester) async {
      ReferenceVehicle? captured;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referenceVehicleCatalogProvider.overrideWith((ref) {
              return Future<List<ReferenceVehicle>>.value([e1, e2, e3]);
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      captured = await ReferenceVehiclePicker.show(context);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the second row — Peugeot 3008 — and let the navigator pop.
      await tester.tap(find.text('Peugeot 3008'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.make, 'Peugeot');
      expect(captured!.model, '3008');
      expect(captured!.yearStart, 2016);
      // Sheet is gone after pop.
      expect(find.byType(ReferenceVehiclePicker), findsNothing);
    });

    testWidgets('tap on Cancel pops the sheet with null', (tester) async {
      ReferenceVehicle? captured = e1; // sentinel — must be cleared
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referenceVehicleCatalogProvider.overrideWith((ref) {
              return Future<List<ReferenceVehicle>>.value([e1, e2, e3]);
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      captured = await ReferenceVehiclePicker.show(context);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom-row Cancel TextButton (the suffixIcon on the search
      // field renders an IconButton, not a Cancel-labelled TextButton).
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(captured, isNull);
      expect(find.byType(ReferenceVehiclePicker), findsNothing);
    });

    testWidgets('shows "No matches" empty state when search filters all out',
        (tester) async {
      await pumpPickerSheet(tester);

      await tester.enterText(find.byType(TextField), 'xyzzy-no-such-brand');
      await tester.pump();

      expect(find.text('No matches'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('loading state shows a CircularProgressIndicator + label',
        (tester) async {
      await pumpPickerSheet(
        tester,
        catalogValue: const AsyncValue<List<ReferenceVehicle>>.loading(),
      );

      // Spinner + label visible. We deliberately use pump (not
      // pumpAndSettle) above because the loading future never
      // completes — pumpAndSettle would wait forever.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading catalog…'), findsOneWidget);
      // No tiles while loading.
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
