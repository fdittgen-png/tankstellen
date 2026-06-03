// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/recording_app_bar_actions.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2764 — the trip-recording AppBar dropped from 5 inline IconButtons
/// (which truncated the title to "Enr…") to 2 primary actions
/// (Pause + Stop) plus a single overflow kebab holding Pin / Help / PiP.
///
/// These tests pin the new shape: Pause + Stop visible, the
/// `recording_overflow_menu` kebab present, and opening it surfaces
/// Pin / Help / (PiP when supported) — each still firing its callback.
void main() {
  /// A captured-callback record so each item can prove it fires.
  late List<String> fired;

  Widget harness({
    bool pinned = false,
    bool pipSupported = true,
    bool isActive = true,
    bool isPaused = false,
    bool stopping = false,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        // A real AppBar with a long title so we can prove the title is
        // NOT truncated once the actions collapse to 3 trailing items.
        appBar: AppBar(
          title: const Text(
            'Enregistrement du trajet en cours',
            key: Key('recordingTitle'),
          ),
          actions: [
            RecordingAppBarActions(
              pinned: pinned,
              pipSupported: pipSupported,
              isActive: isActive,
              isPaused: isPaused,
              stopping: stopping,
              onTogglePin: () => fired.add('pin'),
              onShowPinHelp: () => fired.add('help'),
              onEnterPip: () => fired.add('pip'),
              onTogglePause: () => fired.add('pause'),
              onStop: () => fired.add('stop'),
            ),
          ],
        ),
      ),
    );
  }

  setUp(() => fired = <String>[]);

  Future<void> openKebab(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('recording_overflow_menu')));
    await tester.pumpAndSettle();
  }

  group('RecordingAppBarActions (#2764)', () {
    testWidgets('Pause + Stop are primary; kebab present; title not truncated',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tripPauseButton')), findsOneWidget);
      expect(find.byKey(const Key('tripStopButton')), findsOneWidget);
      expect(find.byKey(const Key('recording_overflow_menu')), findsOneWidget);

      // The full title renders (no clipping to "Enr…"). Reading the
      // RenderParagraph proves the text wasn't replaced by an ellipsis
      // run.
      final para = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(const Key('recordingTitle')),
          matching: find.byType(RichText),
        ),
      );
      expect(para.text.toPlainText(),
          'Enregistrement du trajet en cours');
      expect(tester.takeException(), isNull,
          reason: 'no overflow with only 3 trailing actions');
    });

    testWidgets('Pin / Help / PiP live inside the kebab and each fires',
        (tester) async {
      await tester.pumpWidget(harness(pipSupported: true));
      await tester.pumpAndSettle();

      // Folded away until the kebab opens.
      expect(find.byKey(const Key('tripPinButton')), findsNothing);
      expect(find.byKey(const Key('tripPinHelpButton')), findsNothing);
      expect(find.byKey(const Key('tripMinimiseButton')), findsNothing);

      await openKebab(tester);
      expect(find.byKey(const Key('tripPinButton')), findsOneWidget);
      expect(find.byKey(const Key('tripPinHelpButton')), findsOneWidget);
      expect(find.byKey(const Key('tripMinimiseButton')), findsOneWidget);

      // Pin fires.
      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();
      expect(fired, ['pin']);

      // Help fires.
      await openKebab(tester);
      await tester.tap(find.byKey(const Key('tripPinHelpButton')));
      await tester.pumpAndSettle();
      expect(fired, ['pin', 'help']);

      // PiP fires.
      await openKebab(tester);
      await tester.tap(find.byKey(const Key('tripMinimiseButton')));
      await tester.pumpAndSettle();
      expect(fired, ['pin', 'help', 'pip']);
    });

    testWidgets('PiP item is absent when PiP is unsupported', (tester) async {
      await tester.pumpWidget(harness(pipSupported: false));
      await tester.pumpAndSettle();
      await openKebab(tester);

      expect(find.byKey(const Key('tripPinButton')), findsOneWidget);
      expect(find.byKey(const Key('tripPinHelpButton')), findsOneWidget);
      expect(find.byKey(const Key('tripMinimiseButton')), findsNothing,
          reason: 'PiP only renders where the platform can host it');
    });

    testWidgets('Pause + Stop fire their callbacks', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tripPauseButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tripStopButton')));
      await tester.pumpAndSettle();
      expect(fired, ['pause', 'stop']);
    });

    testWidgets('Pause + Stop are disabled when the trip is not active',
        (tester) async {
      await tester.pumpWidget(harness(isActive: false));
      await tester.pumpAndSettle();

      final pause =
          tester.widget<IconButton>(find.byKey(const Key('tripPauseButton')));
      final stop =
          tester.widget<IconButton>(find.byKey(const Key('tripStopButton')));
      expect(pause.onPressed, isNull);
      expect(stop.onPressed, isNull);
    });

    testWidgets('pin item reflects the pinned state (filled icon + Unpin '
        'semantics)', (tester) async {
      await tester.pumpWidget(harness(pinned: true));
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      await openKebab(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('tripPinButton')),
          matching: find.byIcon(Icons.push_pin),
        ),
        findsOneWidget,
        reason: 'pinned → filled push-pin icon',
      );
      expect(find.bySemanticsLabel('Unpin recording form'), findsOneWidget);
      handle.dispose();
    });
  });
}
