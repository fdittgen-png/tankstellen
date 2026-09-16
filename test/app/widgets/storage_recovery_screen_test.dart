// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/widgets/storage_recovery_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2294 — when a Hive box is corrupted beyond recovery the cold-start
/// sequence renders [StorageRecoveryHost] instead of leaving the user
/// frozen on the splash. These tests pin that the recovery screen
/// renders, is fully ARB-backed (English + German), and that the
/// AppInitializer wiring routes the corruption exception through
/// errorLogger before showing the screen.
void main() {
  group('StorageRecoveryHost', () {
    testWidgets('renders the English recovery copy from ARB', (tester) async {
      // #4116/#4118 — the corruptBox cause is now required to get the CORRUPTION
      // copy. The default branch deliberately says something else and
      // never advises clearing storage; see
      // storage_recovery_cause_test.dart.
      await tester.pumpWidget(const StorageRecoveryHost(cause: StorageRecoveryCause.corruptBox));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.storageRecoveryTitle), findsOneWidget);
      expect(find.text(l10n.storageRecoveryMessage), findsOneWidget);
      expect(find.text(l10n.storageRecoveryGuidance), findsOneWidget);
    });

    testWidgets('localizes the recovery copy to German', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('de'));
      expect(l10n.storageRecoveryTitle, 'Speicherproblem');
      // Sanity: German copy differs from English, proving it is ARB-backed
      // per-locale rather than a hard-coded English literal.
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.storageRecoveryMessage, isNot(en.storageRecoveryMessage));
      expect(l10n.storageRecoveryGuidance, isNot(en.storageRecoveryGuidance));
    });

    testWidgets('mounts without a Material/Riverpod ancestor', (tester) async {
      // It must render before Hive / Riverpod are wired — a bare
      // WidgetsApp, no Scaffold/Navigator dependency.
      await tester.pumpWidget(const StorageRecoveryHost());
      await tester.pumpAndSettle();
      expect(find.byType(WidgetsApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the storage phase is routed through the gate (#2294/#4118)', () {
    // What this group used to do: read `app_initializer.dart` as text and
    // assert a `try` wrapped `_initStorage`, that a catch targeted
    // HiveCorruptionException, and that the block called errorLogger and
    // runApp. All three broke when the catches moved into
    // `storage_failure_gate.dart` — while the routing itself was
    // completely intact. A test that pins prose reports a refactor as a
    // regression and would report a real regression as nothing at all.
    //
    // The behaviour now has executing coverage: `startup_brick_recovery_test`
    // drives `runStoragePhaseGuarded` with each fault and asserts which
    // screen is mounted, that the cause is persisted Hive-independently,
    // and that a successful phase mounts nothing.
    //
    // One structural fact survives here, because no test that drives the
    // gate can see it: that `run()` actually sends the storage phase
    // through the gate at all. Without this, the gate could be perfect
    // and unreachable.
    late String initSource;

    setUpAll(() {
      initSource = File('lib/app/app_initializer.dart').readAsStringSync();
    });

    test('run() puts _initStorage behind runStoragePhaseGuarded', () {
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);
      expect(runBody, contains('runStoragePhaseGuarded(_initStorage)'),
          reason: 'an unguarded storage phase freezes the user on the '
              'splash with no message and no telemetry — no Zone handler '
              'exists this early');
    });

    test('run() STOPS when the gate reports failure', () {
      // The gate returning false has to end the launch. Continuing past a
      // failed storage phase is how the app reaches the first screen with
      // no providers behind it.
      // #4319 — the gate runs inside LaunchCriticalPath, which returns no
      // container on failure (EXECUTED in launch_critical_path_test.dart:
      // "a storage failure ... launches nothing"); run() stops on that.
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody,
          contains('storage: () => runStoragePhaseGuarded(_initStorage),'));
      expect(runBody, contains('if (container == null) return;'));
    });
  });
}

String? _extractMethodBody(String source, String signature) {
  final start = source.indexOf(signature);
  if (start < 0) return null;
  var i = source.indexOf('(', start);
  if (i < 0) return null;
  var parenDepth = 0;
  for (; i < source.length; i++) {
    final ch = source[i];
    if (ch == '(') parenDepth++;
    if (ch == ')') {
      parenDepth--;
      if (parenDepth == 0) {
        i++;
        break;
      }
    }
  }
  final braceStart = source.indexOf('{', i);
  if (braceStart < 0) return null;
  var depth = 0;
  for (var j = braceStart; j < source.length; j++) {
    final ch = source[j];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return source.substring(braceStart + 1, j);
    }
  }
  return null;
}
