import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/link_device_this_device_card.dart';

void main() {
  group('LinkDeviceThisDeviceCard', () {
    Future<void> pumpCard(WidgetTester tester, {String? myId}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkDeviceThisDeviceCard(myId: myId),
          ),
        ),
      );
    }

    testWidgets('renders the device id when one is provided', (tester) async {
      await pumpCard(tester, myId: 'abc-123-def');
      expect(find.text('abc-123-def'), findsOneWidget);
      expect(find.text('Not connected'), findsNothing);
    });

    testWidgets('renders "Not connected" when myId is null', (tester) async {
      await pumpCard(tester, myId: null);
      expect(find.text('Not connected'), findsOneWidget);
    });

    testWidgets('shows the copy button when myId is non-null',
        (tester) async {
      await pumpCard(tester, myId: 'abc-123');
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('hides the copy button when myId is null', (tester) async {
      await pumpCard(tester, myId: null);
      expect(find.byIcon(Icons.copy), findsNothing);
    });

    testWidgets('tapping the copy button writes the id to the clipboard',
        (tester) async {
      // Mock the clipboard channel because flutter_test doesn't ship a
      // platform implementation.
      String? captured;
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map;
          captured = args['text'] as String?;
        }
        return null;
      });

      await pumpCard(tester, myId: 'copy-me-please');
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      expect(captured, 'copy-me-please');

      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });
}
