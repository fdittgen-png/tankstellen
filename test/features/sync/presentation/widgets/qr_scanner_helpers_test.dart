import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/qr_scanner_helpers.dart';

/// Wraps a widget in MaterialApp + Material so that Theme + Material
/// ancestors (FilledButton uses InkWell which needs a Material parent)
/// resolve without bringing in the full pumpApp / Riverpod / l10n stack.
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('QrPermissionDenied', () {
    testWidgets('renders the supplied message text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrPermissionDenied(
            message: 'Camera access is required',
            buttonLabel: 'Open settings',
            onPressed: () async {},
          ),
        ),
      );

      expect(find.text('Camera access is required'), findsOneWidget);
    });

    testWidgets('renders the supplied button label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrPermissionDenied(
            message: 'msg',
            buttonLabel: 'Open settings',
            onPressed: () async {},
          ),
        ),
      );

      expect(find.text('Open settings'), findsOneWidget);
    });

    testWidgets('button has key qrScannerDeniedAction', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrPermissionDenied(
            message: 'msg',
            buttonLabel: 'btn',
            onPressed: () async {},
          ),
        ),
      );

      expect(find.byKey(const Key('qrScannerDeniedAction')), findsOneWidget);
    });

    testWidgets('renders the no-photography icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrPermissionDenied(
            message: 'msg',
            buttonLabel: 'btn',
            onPressed: () async {},
          ),
        ),
      );

      expect(find.byIcon(Icons.no_photography_outlined), findsOneWidget);
    });

    testWidgets('tapping the button awaits the supplied async callback',
        (tester) async {
      var calls = 0;
      Future<void> handler() async {
        calls += 1;
      }

      await tester.pumpWidget(
        _wrap(
          QrPermissionDenied(
            message: 'msg',
            buttonLabel: 'btn',
            onPressed: handler,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('qrScannerDeniedAction')));
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('QrScanTimeoutPrompt', () {
    testWidgets('renders the supplied message text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrScanTimeoutPrompt(
            message: 'No code detected',
            buttonLabel: 'Retry',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('No code detected'), findsOneWidget);
    });

    testWidgets('renders the supplied button label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrScanTimeoutPrompt(
            message: 'msg',
            buttonLabel: 'Retry scan',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Retry scan'), findsOneWidget);
    });

    testWidgets('button has key qrScannerTimeoutRetry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrScanTimeoutPrompt(
            message: 'msg',
            buttonLabel: 'btn',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('qrScannerTimeoutRetry')), findsOneWidget);
    });

    testWidgets('renders the timer-off icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QrScanTimeoutPrompt(
            message: 'msg',
            buttonLabel: 'btn',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.timer_off_outlined), findsOneWidget);
    });

    testWidgets('tapping the button calls the VoidCallback exactly once',
        (tester) async {
      var calls = 0;
      void handler() {
        calls += 1;
      }

      await tester.pumpWidget(
        _wrap(
          QrScanTimeoutPrompt(
            message: 'msg',
            buttonLabel: 'btn',
            onPressed: handler,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('qrScannerTimeoutRetry')));
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('QrScanFrameOverlay', () {
    testWidgets('pumps without throwing inside a sized parent',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            height: 300,
            child: QrScanFrameOverlay(),
          ),
        ),
      );

      expect(find.byType(QrScanFrameOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps its CustomPaint in an IgnorePointer', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            height: 300,
            child: QrScanFrameOverlay(),
          ),
        ),
      );

      // Find the CustomPaint that QrScanFrameOverlay creates (descendant of
      // the overlay) and verify it has an IgnorePointer ancestor inside the
      // overlay subtree — taps must fall through to the camera below.
      final ignorePointerFinder = find.descendant(
        of: find.byType(QrScanFrameOverlay),
        matching: find.byType(IgnorePointer),
      );
      expect(ignorePointerFinder, findsOneWidget);

      final customPaintInOverlay = find.descendant(
        of: ignorePointerFinder,
        matching: find.byType(CustomPaint),
      );
      expect(customPaintInOverlay, findsWidgets);
    });
  });

  group('QrFramePainter', () {
    test('shouldRepaint returns true when old.color differs from new.color',
        () {
      final oldPainter = QrFramePainter(color: const Color(0xFF112233));
      final newPainter = QrFramePainter(color: const Color(0xFF445566));

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns false when old.color equals new.color', () {
      const sameColor = Color(0xFF112233);
      final oldPainter = QrFramePainter(color: sameColor);
      final newPainter = QrFramePainter(color: sameColor);

      expect(newPainter.shouldRepaint(oldPainter), isFalse);
    });

    testWidgets('paints without throwing inside a sized parent',
        (tester) async {
      final key = UniqueKey();
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              key: key,
              painter: QrFramePainter(color: Colors.red),
              size: const Size(300, 300),
            ),
          ),
        ),
      );

      // Scaffold internally inserts its own CustomPaint, so target ours by
      // key rather than by type.
      expect(find.byKey(key), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
