// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_export_actions.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_export_delete_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../../fakes/fake_storage_repository.dart';
import '../../../../../../helpers/hive_temp_dir.dart';
import 'privacy_test_support.dart';

void main() {
  for (final withUnsupportedType in [false, true]) {
    testWidgets('confirmed erasure reports actual typed-box outcome '
        '(unsupported=$withUnsupportedType)', (tester) async {
      final dir = Directory.systemTemp.createTempSync('privacy_typed_');
      Hive.init(dir.path);
      addTearDown(() async {
        await tester.runAsync(() => closeHiveAndDeleteTemp(dir));
      });
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      errorLogger.spoolEnqueueOverride =
          ({
            required String isolateTaskName,
            required Object error,
            StackTrace? stack,
            Map<String, dynamic>? contextMap,
            DateTime? timestamp,
          }) async {};
      addTearDown(errorLogger.resetForTest);
      late Box<String> reminders;
      late Box<int> schema;
      Box<double>? unsupported;
      await tester.runAsync(() async {
        reminders = await Hive.openBox<String>(HiveBoxes.serviceReminders);
        schema = await Hive.openBox<int>(HiveBoxes.boxSchema);
        await reminders.put('private', 'appointment');
        await schema.put('private', 42);
        if (withUnsupportedType) {
          unsupported = await Hive.openBox<double>(
            HiveBoxes.trafficSignalsCache,
          );
          await unsupported!.put('private', 1.5);
        }
      });
      // Exercise the real screen, confirmation and core eraser. Feature-owned
      // widget/WAL adapters have their own tests and must not touch host files.
      final erased = Completer<void>();
      debugPrivacyErasureExtraWipesOverride = [() async => erased.complete()];
      addTearDown(() => debugPrivacyErasureExtraWipesOverride = null);
      final router = GoRouter(
        initialLocation: '/privacy',
        routes: [
          GoRoute(
            path: '/privacy',
            builder: (_, _) => const PrivacyExportDeleteScreen(),
          ),
          GoRoute(
            path: RoutePaths.setup,
            builder: (_, _) => const Scaffold(body: Text('setup-probe')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageRepositoryProvider.overrideWithValue(
              FakeStorageRepository(),
            ),
            syncStateProvider.overrideWith(DisabledSyncState.new),
            traceStorageProvider.overrideWithValue(StubTraceStorage()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(PrivacyExportDeleteScreen)),
      );
      // The handler spans the dialog AND real Hive IO. Start that handler
      // outside the widget fake clock so its continuation can finish on disk.
      await tester.runAsync(() async {
        await tester.tap(
          find.byKey(const ValueKey('privacy-delete-all-button')),
        );
      });
      await tester.pumpAndSettle();
      // Before confirmation, the actual records still exist.
      expect(reminders.length, 1);
      expect(schema.length, 1);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('privacyDeleteConfirmButton')));
      });
      // Dialog completion needs widget frames while Hive needs real IO.
      // Awaiting only the IO barrier starves the dialog's fake-clock future.
      final wait = Stopwatch()..start();
      while (!erased.isCompleted &&
          wait.elapsed < const Duration(seconds: 10)) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(erased.isCompleted, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('setup-probe'), findsOneWidget);
      expect(reminders.isEmpty, isTrue);
      expect(schema.isEmpty, isTrue);
      expect(reminders.isOpen, isTrue);
      if (withUnsupportedType) {
        expect(unsupported!.get('private'), 1.5);
        expect(
          find.text(
            l.localErasurePartial('box:${HiveBoxes.trafficSignalsCache}'),
          ),
          findsOneWidget,
        );
      } else {
        expect(find.textContaining('box:'), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
