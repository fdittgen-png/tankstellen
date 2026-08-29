// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/widgets/ugc_public_notice_dialog.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3871 — the one-time "Shared with other users" notice: shows once,
/// Cancel refuses without persisting, Continue accepts and persists,
/// an unreadable settings box still shows the dialog.
void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return hostContext;
  }

  testWidgets('first call shows the dialog with title, body, Cancel, Continue',
      (tester) async {
    final settings = _MemorySettings();
    final context = await pumpHost(tester);

    final result = ensureUgcPublicNoticeAccepted(context, settings: settings);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsOneWidget);
    expect(find.text('Shared with other users'), findsOneWidget);
    expect(find.textContaining('pseudonymous user ID'), findsOneWidget);
    expect(find.textContaining('Data Transparency'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ugc_public_notice_continue')));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(settings.values[StorageKeys.ugcPublicNoticeShown], isTrue);
  });

  testWidgets('Cancel returns false and does NOT persist the flag',
      (tester) async {
    final settings = _MemorySettings();
    final context = await pumpHost(tester);

    final result = ensureUgcPublicNoticeAccepted(context, settings: settings);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ugc_public_notice_cancel')));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(settings.values.containsKey(StorageKeys.ugcPublicNoticeShown),
        isFalse);
    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsNothing);
  });

  testWidgets('already accepted → returns true without any dialog',
      (tester) async {
    final settings = _MemorySettings()
      ..values[StorageKeys.ugcPublicNoticeShown] = true;
    final context = await pumpHost(tester);

    final result = await ensureUgcPublicNoticeAccepted(
      context,
      settings: settings,
    );
    await tester.pump();

    expect(result, isTrue);
    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsNothing);
  });

  testWidgets('a throwing settings box still shows the dialog and honours '
      'Continue for the session', (tester) async {
    // The read/persist failures route through logFailure → errorLogger,
    // whose Hive spool is not initialised in widget tests — point it at
    // a no-op recorder so the degrade is genuinely silent here.
    errorLogger.spoolEnqueueOverride =
        ({
          required String isolateTaskName,
          required Object error,
          StackTrace? stack,
          Map<String, dynamic>? contextMap,
          DateTime? timestamp,
        }) async {};
    addTearDown(errorLogger.resetForTest);
    final context = await pumpHost(tester);

    final result = ensureUgcPublicNoticeAccepted(
      context,
      settings: _ThrowingSettings(),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ugc_public_notice_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ugc_public_notice_continue')));
    await tester.pumpAndSettle();
    // Fault path of the never-throws contract: the persist throws too,
    // yet the call completes normally and honours Continue.
    await expectLater(result, completes);
    expect(await result, isTrue);
  });
}

class _MemorySettings implements SettingsStorage {
  final Map<String, dynamic> values = {};

  @override
  dynamic getSetting(String key) => values[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    values[key] = value;
  }

  @override
  bool get isSetupComplete => true;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}

class _ThrowingSettings implements SettingsStorage {
  @override
  dynamic getSetting(String key) =>
      throw StateError('Box not found. Did you forget to call Hive.openBox()?');

  @override
  Future<void> putSetting(String key, dynamic value) async =>
      throw StateError('Box not found. Did you forget to call Hive.openBox()?');

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
