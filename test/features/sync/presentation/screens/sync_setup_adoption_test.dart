// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/sync/presentation/screens/sync_setup_screen.dart';
import 'package:tankstellen/features/sync/providers/sync_setup_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Records the auth call the screen makes so the adoption flow (#3080) can be
/// asserted without a live Supabase session.
class _RecordingSyncState extends SyncState {
  String? connectedUrl;
  String? signInEmail;
  bool? signInIsSignUp;

  @override
  SyncConfig build() => const SyncConfig();

  @override
  Future<void> connect(String url, String anonKey,
      {SyncMode mode = SyncMode.private}) async {
    connectedUrl = url;
  }

  @override
  Future<EmailAuthResult> signInWithEmail(
    String email,
    String password, {
    bool isSignUp = true,
    bool? isAnonymous,
    EmailAuthFn? upgrade,
    EmailAuthFn? signUp,
    EmailAuthFn? signIn,
  }) async {
    signInEmail = email;
    signInIsSignUp = isSignUp;
    return EmailAuthResult.completed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'an email-bearing QR routes to the adoption step and adopts the '
      'identity via sign-in (isSignUp:false) #3080', (tester) async {
    final fakeSync = _RecordingSyncState();

    await pumpApp(
      tester,
      const SyncSetupScreen(),
      overrides: [
        syncStateProvider.overrideWith(() => fakeSync),
      ],
    );

    // Simulate the QR scan having decoded an email-bearing payload: the
    // url+key were placed in the screen's controllers and the controller
    // was switched into the adoption step (#3080).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SyncSetupScreen)),
    );
    container
        .read(syncSetupControllerProvider.notifier)
        .startAdoption('owner@example.com');
    await tester.pumpAndSettle();

    // The adoption step renders the owner's email in the title.
    expect(find.textContaining('owner@example.com'), findsWidgets);
    expect(
        container.read(syncSetupControllerProvider).step, SyncSetupStep.adopt);

    // Enter the account password and join.
    await tester.enterText(find.byType(TextField).first, 'hunter2pw!');
    await tester.tap(find.text('Join account'));
    await tester.pump();

    // The screen signed in with the existing account — never a sign-up,
    // so the first device's UUID is adopted, not a new one minted.
    expect(fakeSync.signInEmail, 'owner@example.com');
    expect(fakeSync.signInIsSignUp, isFalse);
    expect(fakeSync.connectedUrl, isNotNull);

    // Drain the post-success delay timer the screen schedules before it pops.
    await tester.pump(const Duration(milliseconds: 1600));
  });

  testWidgets(
      '"use a different account" leaves the adoption step for the normal '
      'auth step #3080', (tester) async {
    final fakeSync = _RecordingSyncState();

    await pumpApp(
      tester,
      const SyncSetupScreen(),
      overrides: [
        syncStateProvider.overrideWith(() => fakeSync),
      ],
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SyncSetupScreen)),
    );
    container
        .read(syncSetupControllerProvider.notifier)
        .startAdoption('owner@example.com');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use a different account instead'));
    await tester.pumpAndSettle();

    final s = container.read(syncSetupControllerProvider);
    expect(s.step, SyncSetupStep.auth);
    expect(s.adoptEmail, isNull);
    expect(fakeSync.signInIsSignUp, isNull, reason: 'no auth call was made');
  });
}
