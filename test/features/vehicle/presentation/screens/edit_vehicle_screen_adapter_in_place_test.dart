// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/bluetooth_facade.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/data/vin_adapter_pair_auto_populator.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vin_adapter_pair_auto_populator_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2960 — adding or removing the OBD2 adapter on the Edit-vehicle
/// screen must update the adapter section IN PLACE and keep the form
/// open. Before the fix both the "Forget adapter" handler and the
/// pair flow routed through `_save()`, whose trailing
/// `Navigator.pop()` tore down the whole Edit-vehicle route — the
/// user was bounced out of the form and had to reopen it.
///
/// The screen is pushed ON TOP of a placeholder home route so a
/// spurious `pop()` genuinely unmounts [EditVehicleScreen] and the
/// "still mounted" assertion is meaningful (RED before the fix).
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('edit_vehicle_adapter_in_place_');
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

  testWidgets(
    'tapping "Forget adapter" keeps the form mounted and shows the '
    'unpaired state in place (#2960)',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(
        id: 'v1',
        name: 'Polo',
        tankCapacityL: 45,
        preferredFuelType: 'e10',
        obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
        obd2AdapterName: 'vLinker FS',
      ));

      await _pumpPushedEditScreen(tester, repo: repo);

      // Paired state is shown — the MAC + Forget button are present.
      await tester.dragUntilVisible(
        find.byKey(const Key('vehicleAdapterForget')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.byKey(const Key('vehicleAdapterForget')), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicleAdapterForget')));
      // Settle fully — the pre-fix bug routed through `_save`, whose
      // `Navigator.pop()` only fires after two awaits. A bare pump
      // would race that pop; pumpAndSettle drains it so the
      // "still mounted" assertion is a real RED-before guard.
      await tester.pumpAndSettle();

      // The form is STILL on screen — the route was NOT popped.
      expect(
        find.byType(EditVehicleScreen),
        findsOneWidget,
        reason: 'forgetting the adapter must NOT close the Edit-vehicle form',
      );
      // The adapter section flipped to the unpaired state in place.
      await tester.dragUntilVisible(
        find.byKey(const Key('vehicleAdapterPair')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);

      // The change was persisted (adapter cleared) without leaving the
      // form.
      expect(repo.getById('v1')!.obd2AdapterMac, isNull);
      // Other saved form fields survive the forget.
      expect(repo.getById('v1')!.tankCapacityL, 45);
    },
  );

  testWidgets(
    'completing an add/pair keeps the form mounted, shows the new '
    'adapter in place, and preserves unsaved form edits (#2960)',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = VehicleProfileRepository(_FakeSettings());
      await repo.save(const VehicleProfile(
        id: 'v1',
        name: 'Polo',
        tankCapacityL: 45,
        preferredFuelType: 'e10',
      ));

      await _pumpPushedEditScreen(
        tester,
        repo: repo,
        extraOverrides: [
          obd2ConnectionProvider
              .overrideWith((_) => _ScanningConnection('vLinker FS')),
          // The post-pair auto-populate is irrelevant to this bug and
          // would otherwise reach a real BLE stack. A no-op populator
          // that aborts keeps the test deterministic.
          vinAdapterPairAutoPopulatorProvider.overrideWithValue(
            _AbortingAutoPopulator(),
          ),
        ],
      );

      // Make an UNSAVED edit to a form field (the name) before pairing,
      // to prove the in-place persist carries unsaved edits through.
      final nameField = find.widgetWithText(TextFormField, 'Polo');
      await tester.dragUntilVisible(
        nameField,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.enterText(nameField, 'Polo GTI');
      await tester.pump();

      // Open the pair sheet from the (unpaired) adapter card.
      await tester.dragUntilVisible(
        find.byKey(const Key('vehicleAdapterPair')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('vehicleAdapterPair')));
      await tester.pumpAndSettle();

      // The scan emits one candidate → tap its tile to pop the pair
      // sheet with the chosen adapter (pair-only flow — no live connect).
      expect(
        find.byKey(const Key('obdPickerItem_id-vLinker FS')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('obdPickerItem_id-vLinker FS')));
      await tester.pumpAndSettle();

      // The Edit-vehicle form is STILL on screen — pairing did not pop
      // it.
      expect(
        find.byType(EditVehicleScreen),
        findsOneWidget,
        reason: 'pairing an adapter must NOT close the Edit-vehicle form',
      );
      // The pair sheet itself closed.
      expect(find.text('Pick an OBD2 adapter'), findsNothing);
      // The adapter section now shows the paired adapter in place.
      await tester.dragUntilVisible(
        find.byKey(const Key('vehicleAdapterForget')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.byKey(const Key('vehicleAdapterForget')), findsOneWidget);

      // The new adapter was persisted in place, AND the unsaved name
      // edit was carried through (proving form state survives).
      final after = repo.getById('v1')!;
      expect(after.obd2AdapterMac, 'id-vLinker FS');
      expect(after.obd2AdapterName, 'vLinker FS');
      expect(after.name, 'Polo GTI',
          reason: 'unsaved form edits must survive the in-place adapter pair');
      expect(after.tankCapacityL, 45);
    },
  );
}

Future<void> _pumpPushedEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  List<Override> extraOverrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ...extraOverrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditVehicleScreen(vehicleId: 'v1'),
                  ),
                ),
                child: const Text('open-edit'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-edit'));
  await tester.pumpAndSettle();
}

/// Connection fake whose `scan()` emits a single named candidate so the
/// pair-only picker reaches `selecting` with one tappable tile. No
/// `connect()` runs — the vehicle-edit pair flow uses the pair-only
/// variant, which pops the candidate without connecting.
class _ScanningConnection extends Obd2ConnectionService {
  _ScanningConnection(this._name)
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _NoopFacade(),
        );

  final String _name;

  @override
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    yield [
      ResolvedObd2Candidate(
        candidate: Obd2AdapterCandidate(
          deviceId: 'id-$_name',
          deviceName: _name,
          advertisedServiceUuids: const [],
          rssi: -50,
        ),
        profile: const Obd2AdapterProfile(
          id: 'vlinker-ble',
          displayName: 'vLinker FD / MC (BLE)',
        ),
      ),
    ];
  }
}

/// Post-pair auto-populator that always aborts — the auto-populate flow
/// is orthogonal to the form-close bug and must never reach a real BLE
/// stack in a widget test.
class _AbortingAutoPopulator implements VinAdapterPairAutoPopulator {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<VinAdapterPairAutoPopulationOutcome> run({
    required String pairedAdapterMac,
    required VehicleProfile profile,
  }) async =>
      VinAdapterPairAutoPopulationOutcome.aborted();
}

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _NoopFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError();

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError();
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
