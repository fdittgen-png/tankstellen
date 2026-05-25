// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/reference_vehicle_catalog_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/reference_vehicle_picker.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [ReferenceVehiclePicker] — rebuilt for the
/// make → model → generation drill-down (#1643) and exercised against
/// a 250-entry fixture for the catalog-at-scale acceptance (#1647).
void main() {
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

  /// Builds a large synthetic catalog: [makes] × [modelsPerMake] ×
  /// [gensPerModel] entries — used for the catalog-at-scale tests.
  List<ReferenceVehicle> bigCatalog({
    int makes = 25,
    int modelsPerMake = 5,
    int gensPerModel = 2,
  }) {
    final out = <ReferenceVehicle>[];
    for (var m = 0; m < makes; m++) {
      for (var md = 0; md < modelsPerMake; md++) {
        for (var g = 0; g < gensPerModel; g++) {
          out.add(ReferenceVehicle(
            make: 'Make${m.toString().padLeft(2, '0')}',
            model: 'Model$md',
            generation: 'Gen$g',
            yearStart: 2000 + g * 6,
            displacementCc: 1000 + md * 100,
            fuelType: 'petrol',
            transmission: 'manual',
          ));
        }
      }
    }
    return out;
  }

  Future<ReferenceVehicle?> pumpPickerSheet(
    WidgetTester tester, {
    AsyncValue<List<ReferenceVehicle>>? catalogValue,
    List<ReferenceVehicle>? catalog,
  }) async {
    ReferenceVehicle? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referenceVehicleCatalogProvider.overrideWith((ref) {
            final value = catalogValue ??
                AsyncValue<List<ReferenceVehicle>>.data(
                    catalog ?? const [e1, e2, e3]);
            return value.when(
              data: (v) => Future<List<ReferenceVehicle>>.value(v),
              loading: () => Completer<List<ReferenceVehicle>>().future,
              error: (e, _) => Future<List<ReferenceVehicle>>.error(e),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return result;
  }

  group('ReferenceVehiclePicker — drill-down (#1643)', () {
    testWidgets('root level lists the makes, not individual entries',
        (tester) async {
      await pumpPickerSheet(tester);

      expect(find.text('Pick from catalog'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      // Two makes for the 3-entry fixture (Peugeot ×2, Renault ×1).
      expect(find.text('Peugeot'), findsOneWidget);
      expect(find.text('Renault'), findsOneWidget);
      // The make tile carries its entry count.
      expect(find.text('2'), findsOneWidget); // Peugeot
    });

    testWidgets('tapping a make drills into its models', (tester) async {
      await pumpPickerSheet(tester);

      await tester.tap(find.text('Peugeot'));
      await tester.pump();

      // Breadcrumb is the make; models are listed.
      expect(find.text('208'), findsOneWidget);
      expect(find.text('3008'), findsOneWidget);
      expect(find.text('Renault'), findsNothing);
    });

    testWidgets('drilling make → model → generation pops the entry',
        (tester) async {
      ReferenceVehicle? captured;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referenceVehicleCatalogProvider.overrideWith((ref) =>
                Future<List<ReferenceVehicle>>.value([e1, e2, e3])),
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

      await tester.tap(find.text('Peugeot'));
      await tester.pump();
      await tester.tap(find.text('3008'));
      await tester.pump();
      await tester.tap(find.text('II'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.make, 'Peugeot');
      expect(captured!.model, '3008');
      expect(captured!.yearStart, 2016);
      expect(find.byType(ReferenceVehiclePicker), findsNothing);
    });

    testWidgets('the back button steps one level up the drill-down',
        (tester) async {
      await pumpPickerSheet(tester);

      await tester.tap(find.text('Peugeot'));
      await tester.pump();
      expect(find.text('208'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();

      // Back at the make list.
      expect(find.text('Peugeot'), findsOneWidget);
      expect(find.text('Renault'), findsOneWidget);
    });
  });

  group('ReferenceVehiclePicker — debounced search (#1643)', () {
    testWidgets('search overrides the drill-down with flat results once '
        'the debounce elapses', (tester) async {
      await pumpPickerSheet(tester);

      await tester.enterText(find.byType(TextField), 'peugeot');
      // Before the debounce window: still the make list.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Renault'), findsOneWidget);

      // After the 250 ms debounce: flat filtered results.
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Peugeot 208'), findsOneWidget);
      expect(find.textContaining('Peugeot 3008'), findsOneWidget);
      expect(find.textContaining('Renault Clio'), findsNothing);
    });

    testWidgets('shows the "No matches" empty state', (tester) async {
      await pumpPickerSheet(tester);

      await tester.enterText(find.byType(TextField), 'xyzzy-no-brand');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('Cancel pops the sheet with null', (tester) async {
      ReferenceVehicle? captured = e1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referenceVehicleCatalogProvider.overrideWith((ref) =>
                Future<List<ReferenceVehicle>>.value([e1, e2, e3])),
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

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });

    testWidgets('loading state shows a spinner + label', (tester) async {
      await pumpPickerSheet(
        tester,
        catalogValue: const AsyncValue<List<ReferenceVehicle>>.loading(),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading catalog…'), findsOneWidget);
    });
  });

  group('ReferenceVehiclePicker — catalog at scale (#1647)', () {
    testWidgets('a 250-entry catalog renders the make list without overflow',
        (tester) async {
      final big = bigCatalog(); // 25 × 5 × 2 = 250 entries
      expect(big.length, 250);
      await pumpPickerSheet(tester, catalog: big);

      // The 25 makes are grouped — only make tiles render at the root,
      // never 250 rows. The first make is reachable.
      expect(find.text('Make00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('any entry is reachable in three taps regardless of size',
        (tester) async {
      ReferenceVehicle? captured;
      final big = bigCatalog();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            referenceVehicleCatalogProvider.overrideWith(
                (ref) => Future<List<ReferenceVehicle>>.value(big)),
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

      // Tap 1: make. Tap 2: model. Tap 3: generation → selected.
      await tester.tap(find.text('Make00'));
      await tester.pump();
      await tester.tap(find.text('Model0'));
      await tester.pump();
      await tester.tap(find.text('Gen0'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.make, 'Make00');
      expect(captured!.model, 'Model0');
      expect(captured!.generation, 'Gen0');
    });

    testWidgets('debounced search stays responsive against 250 entries',
        (tester) async {
      await pumpPickerSheet(tester, catalog: bigCatalog());

      await tester.enterText(find.byType(TextField), 'Make07 Model3');
      await tester.pump(const Duration(milliseconds: 300));

      // Exactly the two generations of Make07/Model3 match (the tile
      // titles read "Make07 Model3 · GenN" — the bare search-field
      // text is excluded by matching the "· Gen" tile suffix).
      expect(find.textContaining('Make07 Model3 · Gen'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
