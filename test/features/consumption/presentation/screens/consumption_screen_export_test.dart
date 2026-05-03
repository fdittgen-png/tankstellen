import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/full_backup_exporter.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/screens/consumption_screen.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

class _FixedFillUpList extends FillUpList {
  final List<FillUp> _value;
  _FixedFillUpList(this._value);

  @override
  List<FillUp> build() => _value;
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

class _EmptyVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

/// Test double for [FullBackupExporter] that captures the call without
/// touching `path_provider` or `share_plus`. We keep the constructor
/// shape compatible with the production class so the screen's wiring
/// code is exercised verbatim.
class _RecordingExporter extends FullBackupExporter {
  int callCount = 0;
  List<FillUp>? lastFillUps;
  List<VehicleProfile>? lastVehicles;

  _RecordingExporter()
      : super(xmlWriter: BackupXmlWriter(), zipper: const BackupZipper());

  @override
  Future<FullBackupExportResult> export({
    required List<VehicleProfile> vehicles,
    required List<FillUp> fillUps,
    required List trips,
    required List chargingLogs,
  }) async {
    callCount++;
    lastFillUps = fillUps;
    lastVehicles = vehicles;
    return const FullBackupExportResult(
      filePath: '/tmp/test_backup.zip',
      byteSize: 1234,
    );
  }
}

class _ThrowingExporter extends FullBackupExporter {
  _ThrowingExporter()
      : super(xmlWriter: BackupXmlWriter(), zipper: const BackupZipper());

  @override
  Future<FullBackupExportResult> export({
    required List<VehicleProfile> vehicles,
    required List<FillUp> fillUps,
    required List trips,
    required List chargingLogs,
  }) async {
    throw StateError('share-sheet refused');
  }
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
      GoRoute(path: '/consumption/add', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/carbon', builder: (_, _) => const SizedBox()),
    ],
  );

  await pumpApp(
    tester,
    MaterialApp.router(routerConfig: router),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
      activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
      vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
      gamificationEnabledProvider.overrideWithValue(true),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Belt-and-braces: even if the screen instantiated a real exporter
    // somehow, swap the share-sheet sink for a no-op so the test
    // doesn't open the OS dialog.
    debugBackupShareSinkOverride = (_) async {};
  });

  tearDown(() {
    ConsumptionScreen.debugExporterOverride = null;
    debugBackupShareSinkOverride = null;
    debugBackupTempDirectoryOverride = null;
    debugBackupClockOverride = null;
    debugBackupAppVersionOverride = null;
  });

  group('ConsumptionScreen full-backup export (#1317)', () {
    testWidgets('export button is enabled even with no fill-ups', (tester) async {
      // The full-backup export covers vehicles + trips + charging logs
      // too, so an empty fill-up list is no longer a reason to disable
      // the button. (CSV export was fill-up-only and gated on emptiness;
      // the new flow is not.)
      await _pumpScreen(tester, fillUps: const []);

      final button = tester.widget<IconButton>(
        find.byKey(const Key('export_backup')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping the button invokes the FullBackupExporter',
        (tester) async {
      final exporter = _RecordingExporter();
      ConsumptionScreen.debugExporterOverride = exporter;

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

      await tester.tap(find.byKey(const Key('export_backup')));
      await tester.pumpAndSettle();

      expect(exporter.callCount, 1);
      // The screen must hand the active fill-up snapshot through.
      expect(exporter.lastFillUps, isNotNull);
      expect(exporter.lastFillUps!.single.id, '1');
    });

    testWidgets('shows confirmation snackbar after a successful export',
        (tester) async {
      ConsumptionScreen.debugExporterOverride = _RecordingExporter();

      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );
      await _pumpScreen(tester, fillUps: [fillUp]);

      await tester.tap(find.byKey(const Key('export_backup')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Backup ready'),
        findsOneWidget,
      );
    });

    testWidgets('surfaces an error snackbar when the exporter throws',
        (tester) async {
      ConsumptionScreen.debugExporterOverride = _ThrowingExporter();

      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );
      await _pumpScreen(tester, fillUps: [fillUp]);

      await tester.tap(find.byKey(const Key('export_backup')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Backup export failed'),
        findsOneWidget,
      );
    });
  });
}
