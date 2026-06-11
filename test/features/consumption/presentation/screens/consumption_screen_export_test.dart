// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../../helpers/silence_error_logger.dart';

import '../../../../helpers/pump_app.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

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
    required List<dynamic> trips,
    required List<dynamic> chargingLogs,
  }) async {
    callCount++;
    lastFillUps = fillUps;
    lastVehicles = vehicles;
    return const FullBackupExportResult(
      filePath: '/tmp/test_backup.zip',
      byteSize: 1234,
      fileName: 'test_backup.zip',
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
    required List<dynamic> trips,
    required List<dynamic> chargingLogs,
  }) async {
    throw StateError('share-sheet refused');
  }
}

/// Exporter that reports a successful Downloads write (savedPath set), so the
/// success snackbar takes the #2815 "Saved to Downloads as {fileName}" branch.
class _SavedExporter extends FullBackupExporter {
  _SavedExporter()
    : super(xmlWriter: BackupXmlWriter(), zipper: const BackupZipper());

  @override
  Future<FullBackupExportResult> export({
    required List<VehicleProfile> vehicles,
    required List<FillUp> fillUps,
    required List<dynamic> trips,
    required List<dynamic> chargingLogs,
  }) async {
    return const FullBackupExportResult(
      filePath: '/tmp/tankstellen_backup_2026.zip',
      byteSize: 4096,
      fileName: 'tankstellen_backup_2026.zip',
      savedPath: 'content://downloads/tankstellen_backup_2026.zip',
    );
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
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
    overrides: [
      fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
      activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
      vehicleProfileListProvider.overrideWith(() => _EmptyVehicleList()),
      gamificationEnabledProvider.overrideWithValue(true),
    ],
  );
}

void main() {
  silenceErrorLoggerSpool();
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

  // #2756 — export moved from a visible trailing IconButton into the
  // overflow kebab; every flow now opens the kebab first, then taps the
  // `export_backup` PopupMenuItem.
  Future<void> openExport(WidgetTester tester) async {
    expect(find.byKey(const Key('export_backup')), findsNothing);
    await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('export_backup')));
    await tester.pumpAndSettle();
  }

  group('ConsumptionScreen full-backup export (#1317)', () {
    testWidgets('export lives in the overflow kebab (#2756)', (tester) async {
      // The full-backup export covers vehicles + trips + charging logs
      // too, so an empty fill-up list is no longer a reason to disable
      // the action. (CSV export was fill-up-only and gated on emptiness;
      // the new flow is not.) It is no longer a visible trailing button —
      // only the kebab is — and surfaces once the menu opens.
      await _pumpScreen(tester, fillUps: const []);

      expect(find.byKey(const Key('export_backup')), findsNothing);
      await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export_backup')), findsOneWidget);
    });

    testWidgets('tapping the kebab item invokes the FullBackupExporter', (
      tester,
    ) async {
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

      await openExport(tester);

      expect(exporter.callCount, 1);
      // The action must hand the active fill-up snapshot through.
      expect(exporter.lastFillUps, isNotNull);
      expect(exporter.lastFillUps!.single.id, '1');
    });

    testWidgets('shows confirmation snackbar after a successful export', (
      tester,
    ) async {
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

      await openExport(tester);

      expect(find.textContaining('Backup ready'), findsOneWidget);
    });

    testWidgets('names the saved file in the success snackbar (#2815)', (
      tester,
    ) async {
      ConsumptionScreen.debugExporterOverride = _SavedExporter();

      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );
      await _pumpScreen(tester, fillUps: [fillUp]);

      await openExport(tester);

      // The user is told the exact filename to look for (in Downloads / the
      // restore picker), not a generic "saved to folder".
      expect(
        find.textContaining('tankstellen_backup_2026.zip'),
        findsOneWidget,
      );
    });

    testWidgets('surfaces an error snackbar when the exporter throws', (
      tester,
    ) async {
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

      await openExport(tester);

      expect(find.textContaining('Backup export failed'), findsOneWidget);
    });
  });

  // ─── #2433 — precision rating left the Fuel app-bar ─────────────────
  //
  // #2383 had mounted the accuracy indicator + raw η_v chip in the
  // Carburant app-bar. #2433 moves that rating into the
  // Verbrauchsstatistik card, so the app-bar restores its plain "Fuel"
  // title and carries NO precision chip — only the OBD2 chip, the
  // download/export action, the gated Carbon entry and Settings.
  group('ConsumptionScreen Fuel app-bar after #2433', () {
    testWidgets(
      'shows the plain Fuel title (no precision chip in the app-bar)',
      (tester) async {
        final fillUp = FillUp(
          id: '1',
          date: DateTime.utc(2026, 4, 15),
          liters: 40,
          totalCost: 60,
          odometerKm: 10000,
          fuelType: FuelType.e10,
        );
        await _pumpScreen(tester, fillUps: [fillUp]);

        // The restored app-bar title (reuses consumptionTabFuel — #2433).
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text('Fuel')),
          findsOneWidget,
        );
        // No precision chip surfaces anywhere in the app-bar.
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.textContaining('Accuracy:'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.textContaining('η_v'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('keeps the export action reachable via the overflow kebab', (
      tester,
    ) async {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );
      await _pumpScreen(tester, fillUps: [fillUp]);

      // #2756 — export moved into the kebab; the kebab itself is the
      // app-bar action and export appears once it is opened.
      expect(
        find.byKey(const Key('consumption_overflow_menu')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('export_backup')), findsNothing);
      await tester.tap(find.byKey(const Key('consumption_overflow_menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export_backup')), findsOneWidget);
    });
  });
}
