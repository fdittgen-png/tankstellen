// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/widgets/settings_menu_tile.dart';
import 'package:tankstellen/features/trips/domain/situation_classifier.dart';
import 'package:tankstellen/features/trips/providers/vehicle_baseline_summary_provider.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_adapter_topic_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_auto_record_topic_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_calibration_topic_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_service_reminders_topic_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_topic_tiles.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3900 (Epic #3897) — the Edit-vehicle editor is a topic tree: identity
/// & engine stay inline, everything a saved vehicle grows sits behind one
/// tappable tile per topic, each with a one-line status, each opening its
/// own sub-screen. The pinned Save stays on the top level.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('edit_vehicle_topics_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('EditVehicleScreen — topic tree (#3900)', () {
    testWidgets('a NEW vehicle shows no topic tiles (every topic needs a '
        'saved id)', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await _pumpEditScreen(tester, repo: repo, vehicleId: null);
      expect(find.byType(VehicleTopicTiles), findsNothing);
    });

    testWidgets('a saved vehicle lists the four topic tiles with their '
        'status lines', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(
        id: 'v1',
        name: 'Polo',
        obd2AdapterMac: 'AA:BB',
        obd2AdapterName: 'vLinker FS',
        calibrationMode: VehicleCalibrationMode.fuzzy,
        autoRecord: true,
      ));
      await _pumpEditScreen(
        tester,
        repo: repo,
        vehicleId: 'v1',
        overrides: [
          // 4 buckets full of 9 → coverage 120 / 270 = 44 %.
          vehicleBaselineSummaryProvider('v1').overrideWithValue(const {
            DrivingSituation.idle: 30,
            DrivingSituation.urbanCruise: 224000,
            DrivingSituation.highwayCruise: 30,
            DrivingSituation.deceleration: 30,
          }),
        ],
      );

      for (final key in const [
        'vehicleTopic_adapter',
        'vehicleTopic_calibration',
        'vehicleTopic_reminders',
        'vehicleTopic_autoRecord',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
        expect(tester.widget(find.byKey(Key(key))), isA<SettingsMenuTile>());
      }
      // Status lines.
      expect(find.text('vLinker FS'), findsOneWidget);
      expect(find.text('Baseline 44 % · Fuzzy'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('No reminders'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      // None of the topic content is inline on the top level.
      expect(find.byKey(const Key('vehicleAdapterForget')), findsNothing);
      expect(find.byKey(const Key('calibrationModeSegmentedButton')),
          findsNothing);
      expect(find.byKey(const Key('resetBaselinesButton')), findsNothing);
      // The pinned Save is still the top level's.
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('unpaired + rule + auto-record off status lines',
        (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Polo'));
      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Baseline 0 % · Rule-based'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('each tile opens its own sub-screen and the editor stays '
        'underneath', (tester) async {
      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Polo'));
      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      final expected = <String, Type>{
        'vehicleTopic_adapter': VehicleAdapterTopicScreen,
        'vehicleTopic_calibration': VehicleCalibrationTopicScreen,
        'vehicleTopic_reminders': VehicleServiceRemindersTopicScreen,
        'vehicleTopic_autoRecord': VehicleAutoRecordTopicScreen,
      };
      for (final entry in expected.entries) {
        final tile = find.byKey(Key(entry.key));
        await tester.dragUntilVisible(
          tile,
          find.byType(ListView).first,
          const Offset(0, -200),
        );
        // Fully into the viewport — a half-scrolled tile's centre can sit
        // under the pinned Save bar.
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
        expect(
          find.byType(EditVehicleScreen, skipOffstage: false),
          findsOneWidget,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(entry.value), findsNothing);
      }
    });

    testWidgets('the adapter topic shows the adapter card + the calibration '
        'topic shows baseline, mode, advanced card and resets',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(id: 'v1', name: 'Polo'));
      await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

      await tester.tap(find.byKey(const Key('vehicleTopic_adapter')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vehicleTopic_calibration')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('vehicleBaselineAggregateBar')),
          findsOneWidget);
      expect(find.byKey(const Key('calibrationModeSegmentedButton')),
          findsOneWidget);
      expect(find.text('Advanced calibration'), findsOneWidget);
      expect(find.text('Reset from vehicle database'), findsOneWidget);
    });
  });
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  required String? vehicleId,
  List<Object> overrides = const [],
}) async {
  // Tall canvas so the tiles below the fold are built (ListView is lazy).
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditVehicleScreen(vehicleId: vehicleId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
