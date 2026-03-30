import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/storage_bar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final testTheme = ThemeData.light();

  group('StorageBar', () {
    testWidgets('renders colored segments', (tester) async {
      await pumpApp(
        tester,
        StorageBar(
          segments: [
            StorageSegment('Settings', 500, Colors.blue),
            StorageSegment('Cache', 1500, Colors.red),
          ],
          totalBytes: 2000,
          theme: testTheme,
        ),
      );

      expect(find.byType(StorageBar), findsOneWidget);
      expect(find.text('No storage used'), findsNothing);
    });

    testWidgets('shows empty message when totalBytes is 0', (tester) async {
      await pumpApp(
        tester,
        StorageBar(
          segments: [
            StorageSegment('Settings', 0, Colors.blue),
          ],
          totalBytes: 0,
          theme: testTheme,
        ),
      );

      expect(find.text('No storage used'), findsOneWidget);
    });
  });

  group('StorageDetailRow', () {
    testWidgets('renders label, detail, and formatted bytes', (tester) async {
      await pumpApp(
        tester,
        StorageDetailRow(
          label: 'Cache',
          detail: '12 entries',
          bytes: 2048,
          color: Colors.orange,
        ),
      );

      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('12 entries'), findsOneWidget);
      // 2048 bytes = 2.0 KB
      expect(find.text('2.0 KB'), findsOneWidget);
    });
  });
}
