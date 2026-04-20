import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/payment/presentation/widgets/unknown_qr_dialog.dart';

void main() {
  group('UnknownQrDialog (#725)', () {
    testWidgets('renders the raw text verbatim', (tester) async {
      await _pump(tester, raw: 'weird://gibberish/xyz?a=1&b=2');
      expect(find.text('weird://gibberish/xyz?a=1&b=2'), findsOneWidget);
    });

    testWidgets('Copy button writes raw to clipboard and pops dialog',
        (tester) async {
      final writes = <String>[];
      await _pump(
        tester,
        raw: 'weird-raw',
        clipboardWriter: (text) async => writes.add(text),
      );
      await tester.tap(find.byKey(const Key('unknownQrCopy')));
      await tester.pumpAndSettle();
      expect(writes.single, 'weird-raw');
      expect(find.byType(UnknownQrDialog), findsNothing);
    });

    testWidgets('Report button calls onShare with a report body including the raw text',
        (tester) async {
      String? capturedText;
      String? capturedSubject;
      await _pump(
        tester,
        raw: 'mystery://pay/abc',
        onShare: (text, subject) async {
          capturedText = text;
          capturedSubject = subject;
        },
      );
      await tester.tap(find.byKey(const Key('unknownQrReport')));
      await tester.pumpAndSettle();
      expect(capturedText, contains('mystery://pay/abc'));
      expect(capturedText, contains('App version:'));
      expect(capturedSubject, contains('unrecognised payment QR'));
      expect(find.byType(UnknownQrDialog), findsNothing);
    });

    testWidgets('Cancel button pops without any side effects',
        (tester) async {
      final writes = <String>[];
      var shareCalled = false;
      await _pump(
        tester,
        raw: 'x',
        clipboardWriter: (t) async => writes.add(t),
        onShare: (_, _) async => shareCalled = true,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(shareCalled, isFalse);
      expect(find.byType(UnknownQrDialog), findsNothing);
    });
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required String raw,
  Future<void> Function(String text)? clipboardWriter,
  Future<void> Function(String text, String subject)? onShare,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: ctx,
                builder: (_) => UnknownQrDialog(
                  raw: raw,
                  clipboardWriter: clipboardWriter,
                  onShare: onShare,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
