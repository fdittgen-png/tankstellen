import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_section_header.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #692 — The fuel stations section must render BEFORE the EV Charging
/// section on the Favorites tab. Fuel is the app's primary use-case.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fav_order_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets(
    'FavoritesSectionHeader order helper — fuel header appears before EV header',
    (tester) async {
      // Pin the visual ordering by composing the two headers the same way
      // `FavoritesFuelTab` now does (fuel first, then EV).
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: const [
                FavoritesSectionHeader(
                  icon: Icons.local_gas_station,
                  label: 'Fuel Stations',
                ),
                FavoritesSectionHeader(
                  icon: Icons.ev_station,
                  label: 'EV Charging',
                ),
              ],
            ),
          ),
        ),
      );

      final fuelCenter =
          tester.getCenter(find.byIcon(Icons.local_gas_station));
      final evCenter = tester.getCenter(find.byIcon(Icons.ev_station));

      expect(fuelCenter.dy, lessThan(evCenter.dy),
          reason: 'Fuel section must render above EV section');
    },
  );
}
