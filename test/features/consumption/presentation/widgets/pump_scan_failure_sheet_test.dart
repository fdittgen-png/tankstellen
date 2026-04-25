import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_scan_failure_sheet.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Tests for the failure-flow bottom sheet shown after a pump-display
/// scan returns no usable data (#953). The sheet itself owns no state
/// — it only renders three buttons and pops a typed
/// [PumpScanFailureAction] when one is tapped. The host screen wires
/// the action to "open BadScanReportSheet", "delete photo", or
/// "leave the form alone".
void main() {
  Future<PumpScanFailureAction?> openSheetAndTap(
    WidgetTester tester, {
    required Locale locale,
    required String buttonText,
  }) async {
    PumpScanFailureAction? captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  captured = await showModalBottomSheet<PumpScanFailureAction>(
                    context: context,
                    builder: (_) => const PumpScanFailureSheet(),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(buttonText));
    await tester.pumpAndSettle();
    return captured;
  }

  group('PumpScanFailureSheet', () {
    testWidgets('renders all three actions on en locale', (tester) async {
      await tester.pumpWidget(
        const _LocalizedSheet(locale: Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Display unreadable'), findsOneWidget);
      expect(find.text('Correct manually'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Remove photo'), findsOneWidget);
    });

    testWidgets('renders all three actions on fr locale', (tester) async {
      await tester.pumpWidget(
        const _LocalizedSheet(locale: Locale('fr')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Display illisible'), findsOneWidget);
      expect(find.text('Corriger manuellement'), findsOneWidget);
      expect(find.text('Signaler'), findsOneWidget);
      expect(find.text('Retirer la photo'), findsOneWidget);
    });

    testWidgets('Correct manually pops correctManually', (tester) async {
      final result = await openSheetAndTap(
        tester,
        locale: const Locale('en'),
        buttonText: 'Correct manually',
      );
      expect(result, PumpScanFailureAction.correctManually);
    });

    testWidgets('Report pops report', (tester) async {
      final result = await openSheetAndTap(
        tester,
        locale: const Locale('en'),
        buttonText: 'Report',
      );
      expect(result, PumpScanFailureAction.report);
    });

    testWidgets('Remove photo pops removePhoto', (tester) async {
      final result = await openSheetAndTap(
        tester,
        locale: const Locale('en'),
        buttonText: 'Remove photo',
      );
      expect(result, PumpScanFailureAction.removePhoto);
    });
  });
}

/// Const-friendly wrapper so the rendering tests can pass `const`
/// constructors to `pumpWidget` (satisfies `prefer_const_constructors`).
class _LocalizedSheet extends StatelessWidget {
  final Locale locale;
  const _LocalizedSheet({required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: PumpScanFailureSheet()),
    );
  }
}
