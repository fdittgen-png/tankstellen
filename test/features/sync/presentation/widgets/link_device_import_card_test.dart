import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/link_device_import_card.dart';
import 'package:tankstellen/features/sync/providers/link_device_provider.dart';

class _FakeLinkDeviceController extends LinkDeviceController {
  _FakeLinkDeviceController(this._initial);
  final LinkDeviceState _initial;
  @override
  LinkDeviceState build() => _initial;
}

void main() {
  group('LinkDeviceImportCard', () {
    late TextEditingController codeController;

    setUp(() {
      codeController = TextEditingController();
    });

    tearDown(() {
      codeController.dispose();
    });

    Future<void> pumpCard(
      WidgetTester tester, {
      LinkDeviceState state = const LinkDeviceState(),
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            linkDeviceControllerProvider
                .overrideWith(() => _FakeLinkDeviceController(state)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LinkDeviceImportCard(codeController: codeController),
            ),
          ),
        ),
      );
    }

    testWidgets('renders the title and the description', (tester) async {
      await pumpCard(tester);
      expect(find.text('Import from another device'), findsOneWidget);
      expect(
        find.textContaining('Enter the device code from your other device'),
        findsOneWidget,
      );
    });

    testWidgets('Import button is disabled when the code field is empty',
        (tester) async {
      await pumpCard(tester);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Import button enables once the code field has text',
        (tester) async {
      await pumpCard(tester);
      codeController.text = 'abc-123';
      await tester.pump();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Shows a spinner inside the button while linking',
        (tester) async {
      await pumpCard(
        tester,
        state: const LinkDeviceState(isLinking: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsNothing);
    });

    testWidgets('Disables the button while linking even when text is present',
        (tester) async {
      codeController.text = 'abc-123';
      await pumpCard(
        tester,
        state: const LinkDeviceState(isLinking: true),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Renders a green result message on success', (tester) async {
      await pumpCard(
        tester,
        state: const LinkDeviceState(result: 'Linked successfully'),
      );
      expect(find.text('Linked successfully'), findsOneWidget);
    });

    testWidgets('Renders a red result message on error', (tester) async {
      await pumpCard(
        tester,
        state: const LinkDeviceState(
          result: 'Link failed',
        ),
      );
      expect(find.text('Link failed'), findsOneWidget);
    });
  });
}
