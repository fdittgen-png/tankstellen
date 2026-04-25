import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_diff_table.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Future<void> pumpTable(
    WidgetTester tester, {
    required List<BadScanDiffRow> rows,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BadScanDiffTable(rows: rows),
        ),
      ),
    );
  }

  group('BadScanDiffRow', () {
    test('captures label, scanned, and real values verbatim', () {
      const row = BadScanDiffRow('Liters', '32.5', '32,50');
      expect(row.label, 'Liters');
      expect(row.scanned, '32.5');
      expect(row.real, '32,50');
    });
  });

  group('BadScanDiffTable', () {
    testWidgets('renders only the header row when rows is empty',
        (tester) async {
      await pumpTable(tester, rows: const []);
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
      // Header strings (English fallback / app_en.arb).
      expect(find.text('Field'), findsOneWidget);
      expect(find.text('Scanned'), findsOneWidget);
      expect(find.text('You typed'), findsOneWidget);

      // No data rows: only the header TableRow exists.
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children, hasLength(1));
    });

    testWidgets('renders header + a single data row with all three values',
        (tester) async {
      await pumpTable(
        tester,
        rows: const [
          BadScanDiffRow('Liters', '32.5', '32,50'),
        ],
      );
      await tester.pumpAndSettle();

      // Header still present.
      expect(find.text('Field'), findsOneWidget);
      expect(find.text('Scanned'), findsOneWidget);
      expect(find.text('You typed'), findsOneWidget);

      // Data row values are rendered verbatim.
      expect(find.text('Liters'), findsOneWidget);
      expect(find.text('32.5'), findsOneWidget);
      expect(find.text('32,50'), findsOneWidget);

      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children, hasLength(2));
    });

    testWidgets('renders multiple rows in the order they were supplied',
        (tester) async {
      await pumpTable(
        tester,
        rows: const [
          BadScanDiffRow('Liters', '32.5', '32,50'),
          BadScanDiffRow('Total', '55.12', '55,20'),
          BadScanDiffRow('Price/L', '1.695', '1,70'),
        ],
      );
      await tester.pumpAndSettle();

      // All labels render once.
      expect(find.text('Liters'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Price/L'), findsOneWidget);
      expect(find.text('32.5'), findsOneWidget);
      expect(find.text('55.12'), findsOneWidget);
      expect(find.text('1.695'), findsOneWidget);
      expect(find.text('32,50'), findsOneWidget);
      expect(find.text('55,20'), findsOneWidget);
      expect(find.text('1,70'), findsOneWidget);

      // Header + 3 data rows.
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children, hasLength(4));
    });

    testWidgets('header cells use bold font weight', (tester) async {
      await pumpTable(tester, rows: const []);
      await tester.pumpAndSettle();

      final header = tester.widget<Text>(find.text('Field'));
      expect(header.style?.fontWeight, FontWeight.bold);

      final scanned = tester.widget<Text>(find.text('Scanned'));
      expect(scanned.style?.fontWeight, FontWeight.bold);

      final youTyped = tester.widget<Text>(find.text('You typed'));
      expect(youTyped.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('data cells do not apply bold weight', (tester) async {
      await pumpTable(
        tester,
        rows: const [
          BadScanDiffRow('Liters', '32.5', '32,50'),
        ],
      );
      await tester.pumpAndSettle();

      final labelCell = tester.widget<Text>(find.text('Liters'));
      expect(labelCell.style?.fontWeight, isNot(FontWeight.bold));

      final scannedCell = tester.widget<Text>(find.text('32.5'));
      expect(scannedCell.style?.fontWeight, isNot(FontWeight.bold));

      final realCell = tester.widget<Text>(find.text('32,50'));
      expect(realCell.style?.fontWeight, isNot(FontWeight.bold));
    });

    testWidgets('header row uses the surfaceContainerHighest decoration',
        (tester) async {
      await pumpTable(tester, rows: const []);
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(Table));
      final expectedColor = Theme.of(context).colorScheme.surfaceContainerHighest;

      final table = tester.widget<Table>(find.byType(Table));
      final headerRow = table.children.first;
      final decoration = headerRow.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.color, expectedColor);
    });

    testWidgets('data rows have no decoration', (tester) async {
      await pumpTable(
        tester,
        rows: const [
          BadScanDiffRow('Liters', '32.5', '32,50'),
        ],
      );
      await tester.pumpAndSettle();

      final table = tester.widget<Table>(find.byType(Table));
      final dataRow = table.children[1];
      expect(dataRow.decoration, isNull);
    });

    testWidgets('uses German localized headers when locale is de',
        (tester) async {
      await pumpTable(
        tester,
        rows: const [],
        locale: const Locale('de'),
      );
      await tester.pumpAndSettle();

      // app_de.arb: badScanReportHeaderField=Feld, Scanned=Gescannt,
      // YouTyped=Eingegeben.
      expect(find.text('Feld'), findsOneWidget);
      expect(find.text('Gescannt'), findsOneWidget);
      expect(find.text('Eingegeben'), findsOneWidget);
      // English literals must NOT be present when German is loaded.
      expect(find.text('Field'), findsNothing);
      expect(find.text('Scanned'), findsNothing);
      expect(find.text('You typed'), findsNothing);
    });
  });
}
