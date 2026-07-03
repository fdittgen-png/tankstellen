// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/obd2/data/companion_auto_record_coordinator.dart';
import 'package:tankstellen/features/obd2/data/companion_device_association.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3437 (Epic #3417) — the CDM `ensureAssociated` production trigger fires
/// on the MANUAL OBD2 trip start with a pinned dongle (the same foreground
/// moment as the #3313 battery-exemption prompt), and NEVER blocks or fails
/// the start — pinned here at the real [TripRecording.start] chokepoint.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  const pinnedMac = 'AA:BB:CC:DD:EE:FF';
  const pinnedVehicle =
      VehicleProfile(id: 'veh-1', name: 'Clio', obd2AdapterMac: pinnedMac);

  ProviderContainer build({
    required CompanionAutoRecordCoordinator coordinator,
    VehicleProfile? vehicle,
  }) {
    final container = ProviderContainer(overrides: [
      companionAutoRecordCoordinatorProvider.overrideWithValue(coordinator),
      activeVehicleProfileProvider.overrideWith(() => _StubVehicle(vehicle)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<Obd2Service> connectedService() async {
    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    return service;
  }

  test('manual start with a pinned dongle fires ensureAssociated(pinnedMac)',
      () async {
    final coordinator = _RecordingCoordinator();
    final container = build(coordinator: coordinator, vehicle: pinnedVehicle);
    final notifier = container.read(tripRecordingProvider.notifier);

    await notifier.start(await connectedService());
    addTearDown(() async {
      await notifier.stop();
    });
    await _pump();

    expect(coordinator.ensuredMacs, [pinnedMac],
        reason: 'the manual foreground start is the documented consent '
            'moment for the CDM association (#3320 doc, #3437 wiring)');
  });

  test('automatic (hands-free) start does NOT fire the trigger', () async {
    final coordinator = _RecordingCoordinator();
    final container = build(coordinator: coordinator, vehicle: pinnedVehicle);
    final notifier = container.read(tripRecordingProvider.notifier);

    await notifier.start(await connectedService(), automatic: true);
    addTearDown(() async {
      await notifier.stop();
    });
    await _pump();

    expect(coordinator.ensuredMacs, isEmpty,
        reason: 'an auto start may run backgrounded — the system dialog '
            'cannot show, so the trigger is manual-start-only (like #3313)');
  });

  test('no pinned adapter on the active vehicle → no association attempt',
      () async {
    final coordinator = _RecordingCoordinator();
    final container = build(
        coordinator: coordinator,
        vehicle: const VehicleProfile(id: 'veh-2', name: 'NoDongle'));
    final notifier = container.read(tripRecordingProvider.notifier);

    await notifier.start(await connectedService());
    addTearDown(() async {
      await notifier.stop();
    });
    await _pump();

    expect(coordinator.ensuredMacs, isEmpty);
  });

  test('a throwing coordinator neither blocks nor fails the manual start '
      '(fault injection, #2349)', () async {
    final container =
        build(coordinator: _ThrowingCoordinator(), vehicle: pinnedVehicle);
    final notifier = container.read(tripRecordingProvider.notifier);

    await expectLater(
        notifier.start(await connectedService()), completes);
    addTearDown(() async {
      await notifier.stop();
    });
    // Drain the microtask queue — an unhandled async error from the
    // fire-and-forget association would fail the test zone here.
    await _pump();
    await _pump();

    expect(notifier.state.isActive, isTrue,
        reason: 'the association is a best-effort side effect — a blown-up '
            'coordinator must never cost the user their recording');
  });

  test('a hanging coordinator never delays the start (fire-and-forget)',
      () async {
    final container =
        build(coordinator: _HangingCoordinator(), vehicle: pinnedVehicle);
    final notifier = container.read(tripRecordingProvider.notifier);

    // ensureAssociated never completes; start must still complete.
    await expectLater(
        notifier.start(await connectedService()), completes);
    addTearDown(() async {
      await notifier.stop();
    });

    expect(notifier.state.isActive, isTrue);
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

class _StubVehicle extends ActiveVehicleProfile {
  _StubVehicle(this._v);
  final VehicleProfile? _v;
  @override
  VehicleProfile? build() => _v;
}

class _NoopAssociation implements CompanionDeviceAssociation {
  @override
  Future<bool> isSupported() async => false;
  @override
  Future<bool> isAssociated() async => false;
  @override
  Future<bool> associate(String mac) async => false;
  @override
  Future<bool> disassociate() async => false;
}

class _RecordingCoordinator extends CompanionAutoRecordCoordinator {
  _RecordingCoordinator()
      : super(association: _NoopAssociation(), fgsEnabled: true);
  final List<String> ensuredMacs = [];
  @override
  Future<bool> ensureAssociated(String mac) async {
    ensuredMacs.add(mac);
    return true;
  }
}

class _ThrowingCoordinator extends CompanionAutoRecordCoordinator {
  _ThrowingCoordinator()
      : super(association: _NoopAssociation(), fgsEnabled: true);
  @override
  Future<bool> ensureAssociated(String mac) =>
      Future<bool>.error(StateError('coordinator blew up'));
}

class _HangingCoordinator extends CompanionAutoRecordCoordinator {
  _HangingCoordinator()
      : super(association: _NoopAssociation(), fgsEnabled: true);
  @override
  Future<bool> ensureAssociated(String mac) => Completer<bool>().future;
}

/// Minimal ELM327 fake transport responses so a fresh [Obd2Service.connect]
/// succeeds without simulating the full adapter handshake (mirrors
/// trip_recording_provider_active_snapshot_test.dart).
Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
