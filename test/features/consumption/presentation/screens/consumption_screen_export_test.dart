import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

class _FixedFillUpList extends FillUpList {
  final List<FillUp> _value;
  _FixedFillUpList(this._value);

  @override
  List<FillUp> build() => _value;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<FillUp> fillUps,
}) async {
  final router = GoRouter(
    initialLocation: '/consumption',
    routes: [
      GoRoute(
        path: '/consumption',
        builder: (_, _) => const ConsumptionScreen(),
      ),
      // Minimal stubs so pushes in the screen don't crash.
      GoRoute(path: '/consumption/add', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Capture clipboard writes in-memory so we can assert on them.
    _InMemoryClipboard.install();
  });

  tearDown(() {
    _InMemoryClipboard.uninstall();
  });

  group('ConsumptionScreen CSV export (#583)', () {
    testWidgets('export button is disabled when the list is empty',
        (tester) async {
      await _pumpScreen(tester, fillUps: const []);

      final button = tester.widget<IconButton>(
        find.byKey(const Key('export_csv')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('export button writes CSV to the clipboard', (tester) async {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15, 10, 0),
        liters: 40,
        totalCost: 60,
        odometerKm: 12345,
        fuelType: FuelType.diesel,
        stationName: 'Total',
      );

      await _pumpScreen(tester, fillUps: [fillUp]);

      await tester.tap(find.byKey(const Key('export_csv')));
      await tester.pump();

      final copied = _InMemoryClipboard.lastWrite;
      expect(copied, isNotNull);
      expect(copied!, contains('Date,Station,Fuel Type'),
          reason: 'Clipboard must contain the CSV header row.');
      expect(copied, contains('Total'));
      expect(copied, contains('diesel'));
    });

    testWidgets('shows confirmation snackbar after copy', (tester) async {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );

      await _pumpScreen(tester, fillUps: [fillUp]);
      await tester.tap(find.byKey(const Key('export_csv')));
      await tester.pump();

      expect(
        find.textContaining('CSV copied to clipboard'),
        findsOneWidget,
      );
    });
  });
}

/// Intercepts `Clipboard.setData` calls via the platform channel so tests
/// can assert the copied text without hitting a real clipboard.
class _InMemoryClipboard {
  static String? lastWrite;

  static void install() {
    lastWrite = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<dynamic, dynamic>;
        lastWrite = args['text'] as String?;
      }
      return null;
    });
  }

  static void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }
}
