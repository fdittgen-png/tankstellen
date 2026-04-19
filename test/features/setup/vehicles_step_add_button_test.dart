import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/setup/presentation/widgets/vehicles_step.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

/// #695 — The wizard's \"Add vehicle\" button must navigate to the
/// vehicle-edit screen. A previous regression used an unregistered
/// route (/vehicles/new) which silently no-op'd and looked like the
/// wizard had skipped to the next step.
void main() {
  late Directory tempDir;
  late GoRouter router;

  const landingKey = ValueKey('wizard-home');
  const editKey = ValueKey('vehicle-edit');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vehicles_step_tap_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();

    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            key: landingKey,
            body: VehiclesStep(),
          ),
        ),
        GoRoute(
          path: '/vehicles/edit',
          builder: (_, _) => Scaffold(
            key: editKey,
            appBar: AppBar(title: const Text('Add vehicle')),
            body: const Center(child: Text('EDIT VEHICLE STUB')),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets(
    'tapping "Add vehicle" navigates to /vehicles/edit',
    (tester) async {
      await pumpApp(
        tester,
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(landingKey), findsOneWidget,
          reason: 'Starts on the vehicles step');
      expect(find.byKey(editKey), findsNothing,
          reason: 'Edit screen not visible yet');

      await tester.tap(find.widgetWithText(FilledButton, 'Add vehicle'));
      await tester.pumpAndSettle();

      expect(find.byKey(editKey), findsOneWidget,
          reason:
              'Tapping Add vehicle must push the edit screen onto the '
              'navigator — not advance the wizard to the next step');
      expect(find.text('EDIT VEHICLE STUB'), findsOneWidget);
    },
  );
}
