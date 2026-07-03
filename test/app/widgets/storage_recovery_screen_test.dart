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
      await tester.pumpWidget(const StorageRecoveryHost());
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

  group('AppInitializer wires HiveCorruptionException to recovery (#2294)', () {
    late String initSource;

    setUpAll(() {
      initSource = File('lib/app/app_initializer.dart').readAsStringSync();
    });

    test('run() catches HiveCorruptionException around _initStorage', () {
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);

      final tryIdx = runBody!.indexOf('try {');
      final initIdx = runBody.indexOf('await _initStorage()');
      final catchIdx = runBody.indexOf('on HiveCorruptionException');
      expect(tryIdx, isNonNegative, reason: 'run() must guard _initStorage');
      expect(initIdx, isNonNegative);
      expect(catchIdx, isNonNegative,
          reason: 'the catch must target HiveCorruptionException specifically');
      expect(tryIdx, lessThan(initIdx),
          reason: 'the try must wrap the _initStorage await');
      expect(initIdx, lessThan(catchIdx),
          reason: 'the catch follows the guarded await');
    });

    test('the catch routes the exception through errorLogger', () {
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);
      final catchIdx = runBody!.indexOf('on HiveCorruptionException');
      // Slice the catch block region up to the next StartupTimer mark.
      final after = runBody.substring(catchIdx);
      expect(after, contains('errorLogger.log(ErrorLayer.storage'),
          reason: 'the corruption exception must reach the errorLogger / '
              'TraceRecorder pipeline (#2294 acceptance)');
      // #3272 — wrapped in a bare ProviderScope (missing_provider_scope).
      expect(after,
          contains('runApp(const ProviderScope(child: StorageRecoveryHost()))'),
          reason: 'a recovery screen must be shown instead of a frozen splash');
    });

    test('StorageRecoveryHost is imported', () {
      expect(initSource, contains("import 'widgets/storage_recovery_screen.dart';"),
          reason: 'the recovery host must be imported so the wiring compiles');
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
