// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/recovery_message.dart';
import 'package:tankstellen/core/error/widgets/recovery_message_view.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4141 — the recovery contract.
///
/// The interesting assertions are about what the type makes IMPOSSIBLE.
/// The compiler holds the two that matter (`whatStillWorks` and
/// `primaryAction` are required, so a message missing either does not
/// build); these cover the rest.
void main() {
  RecoveryMessage message({
    RecoveryAction? secondary,
    List<String> diagnostic = const [],
  }) =>
      RecoveryMessage(
        whatHappened: 'Car connection lost',
        whyItMatters: 'Fuel use is estimated from GPS until it is back',
        impact: RecoveryImpact.degraded,
        whatStillWorks: 'Recording continues',
        primaryAction: RecoveryAction(label: 'Try again', onInvoke: () {}),
        secondaryAction: secondary,
        diagnostic: diagnostic,
      );

  group('RecoveryAction', () {
    test('an ordinary action is not destructive', () {
      final action = RecoveryAction(label: 'Try again', onInvoke: () {});
      expect(action.isDestructive, isFalse);
      expect(action.destructiveBecause, isNull);
    });

    test('a destructive action CANNOT be built without its justification', () {
      // The #4118 lesson as a type: the copy told users their data was
      // damaged and to clear storage, for a fault that was neither, and
      // clearing storage was the one action that made it unrecoverable.
      // Whoever offers that button now writes down why.
      final action = RecoveryAction.destructive(
        label: 'Clear storage',
        onInvoke: () {},
        becauseDataIsUnrecoverable:
            'the box file failed Hive crash recovery; there is nothing '
            'left to read',
      );
      expect(action.isDestructive, isTrue);
      expect(action.destructiveBecause, isNotEmpty);
    });
  });

  group('actions', () {
    test('a message with one action lists exactly it', () {
      expect(message().actions.map((a) => a.label), ['Try again']);
    });

    test('the secondary follows the primary, never leads', () {
      final m = message(
          secondary: RecoveryAction(label: 'Report', onInvoke: () {}));
      expect(m.actions.map((a) => a.label), ['Try again', 'Report']);
    });
  });

  group('RecoveryMessageView', () {
    Widget wrap(RecoveryMessage m) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RecoveryMessageView(message: m)),
        );

    testWidgets('renders all four parts', (tester) async {
      await tester.pumpWidget(wrap(message()));
      expect(find.text('Car connection lost'), findsOneWidget);
      expect(find.text('Fuel use is estimated from GPS until it is back'),
          findsOneWidget);
      expect(find.text('Recording continues'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('the diagnostic is collapsed, not shown', (tester) async {
      await tester.pumpWidget(
          wrap(message(diagnostic: const ['DioException [timeout]'])));

      expect(find.textContaining('DioException'), findsNothing,
          reason: 'never on the first screen');
      expect(find.byType(ExpansionTile), findsOneWidget);

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.textContaining('DioException'), findsOneWidget,
          reason: 'one tap deeper it is still there — this changes what '
              'is SHOWN, never what is RECORDED');
    });

    testWidgets('no diagnostic means no details tile at all', (tester) async {
      await tester.pumpWidget(wrap(message()));
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('an unaffected failure does not paint in the error colour',
        (tester) async {
      await tester.pumpWidget(wrap(RecoveryMessage(
        whatHappened: 'No results',
        whyItMatters: 'The search came back empty',
        impact: RecoveryImpact.unaffected,
        whatStillWorks: 'Nothing is wrong',
        primaryAction: RecoveryAction(label: 'Try again', onInvoke: () {}),
      )));

      final icon = tester.widget<Icon>(find.byType(Icon).first);
      final context = tester.element(find.byType(RecoveryMessageView));
      expect(icon.color, isNot(Theme.of(context).colorScheme.error),
          reason: 'an empty result is not a failure and must not be '
              'dressed as one');
    });
  });
}
