import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/sync/presentation/widgets/data_transparency_cards.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('InfoRow', () {
    testWidgets('renders label and value', (tester) async {
      await pumpApp(
        tester,
        const InfoRow(label: 'Items', value: '42'),
      );

      expect(find.text('Items'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });

  group('AccountInfoCard', () {
    testWidgets('renders user ID and server', (tester) async {
      final config = SyncConfig(
        enabled: true,
        userId: 'test-uuid-123',
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
        mode: SyncMode.private,
      );

      await pumpApp(
        tester,
        AccountInfoCard(syncConfig: config),
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('test-uuid-123'), findsOneWidget);
      expect(find.text('https://test.supabase.co'), findsOneWidget);
    });
  });

  group('SyncedDataCard', () {
    testWidgets('renders data counts', (tester) async {
      await pumpApp(
        tester,
        const SyncedDataCard(data: {
          'favorites': [1, 2, 3],
          'alerts': [1],
          'push_tokens': [],
          'reports': [1, 2],
        }),
      );

      expect(find.text('Synced data'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // favorites
      expect(find.text('1'), findsOneWidget); // alerts
      expect(find.text('0'), findsOneWidget); // push_tokens
      expect(find.text('2'), findsOneWidget); // reports
    });
  });
}
