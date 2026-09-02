// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_adapter_topic_screen.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/topics/vehicle_auto_record_topic_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Integration tests for #1400 in the #3900 topic tree: the auto-record
/// card's passive "Pair an adapter" link must lead to the ONE pair entry
/// point — the OBD2 adapter card's "Pair adapter" button. Pre-#1400 the
/// auto-record card carried a duplicate orange-tinted CTA that opened
/// the picker itself; pre-#3900 the link scrolled a shared long page.
/// Now the auto-record card lives on its own topic screen and the link
/// opens the OBD2 adapter topic screen.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp
        .createTemp('edit_vehicle_consolidate_pair_cta_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('EditVehicleScreen — consolidate pair CTA (#1400 / #3900)', () {
    testWidgets(
      'auto-record topic renders the passive link, NOT the deprecated '
      'CTA, and the adapter topic owns the canonical pair button',
      (tester) async {
        tester.view.physicalSize = const Size(900, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(const VehicleProfile(
          id: 'v1',
          name: 'Car',
          autoRecord: true,
        ));

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

        // The top level shows NO adapter card and NO auto-record card
        // inline any more — only the topic tiles.
        expect(find.byKey(const Key('vehicleAdapterPair')), findsNothing);
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsNothing,
        );

        await _openTopic(tester, 'vehicleTopic_autoRecord');
        expect(find.byType(VehicleAutoRecordTopicScreen), findsOneWidget);
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
          findsNothing,
          reason:
              '#1400 — the duplicate orange-tinted CTA on the auto-record '
              'card must be gone',
        );
        // The pair button is NOT on the auto-record topic.
        expect(find.byKey(const Key('vehicleAdapterPair')), findsNothing);
      },
    );

    testWidgets(
      'tapping the auto-record link opens the OBD2 adapter topic with '
      'the canonical pair button (#1400 / #3900)',
      (tester) async {
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(const VehicleProfile(
          id: 'v1',
          name: 'Car',
          autoRecord: true,
        ));

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');
        await _openTopic(tester, 'vehicleTopic_autoRecord');

        final link = find.byKey(const Key('autoRecordPairAdapterLink'));
        await tester.dragUntilVisible(
          link,
          find.byType(ListView).last,
          const Offset(0, -200),
        );
        await tester.ensureVisible(link);
        await tester.pumpAndSettle();
        await tester.tap(link);
        await tester.pumpAndSettle();

        expect(find.byType(VehicleAdapterTopicScreen), findsOneWidget);
        expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);
        // The editor is still underneath — the link pushes, never pops.
        expect(
          find.byType(EditVehicleScreen, skipOffstage: false),
          findsOneWidget,
        );
      },
    );
  });
}

/// Scroll the editor's top level to the [tileKey] topic tile, open it.
Future<void> _openTopic(WidgetTester tester, String tileKey) async {
  final tile = find.byKey(Key(tileKey));
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
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  required String vehicleId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
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
