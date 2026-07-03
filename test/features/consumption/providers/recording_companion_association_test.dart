// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/providers/recording_companion_association.dart';
import 'package:tankstellen/features/obd2/data/companion_auto_record_coordinator.dart';
import 'package:tankstellen/features/obd2/data/companion_device_association.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3437 (Epic #3417) — the fire-and-forget CDM association trigger on the
/// manual OBD2 trip-start path. Pins that it resolves the ACTIVE vehicle's
/// pinned MAC, that it is a no-op without one, and that it NEVER throws or
/// blocks — including against a throwing / hanging coordinator (fault
/// injection, #2349) and the FGS-off / unsupported-platform gates.
void main() {
  silenceErrorLoggerSpool();

  const pinnedMac = 'AA:BB:CC:DD:EE:FF';

  ProviderContainer build({
    CompanionAutoRecordCoordinator? coordinator,
    VehicleProfile? vehicle,
    bool vehicleGraphThrows = false,
  }) {
    final container = ProviderContainer(overrides: [
      if (coordinator != null)
        companionAutoRecordCoordinatorProvider.overrideWithValue(coordinator),
      activeVehicleProfileProvider.overrideWith(
        () => vehicleGraphThrows
            ? _ThrowingActiveVehicle()
            : _StubActiveVehicle(vehicle),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('fires ensureAssociated with the active vehicle\'s pinned MAC',
      () async {
    final coordinator = _RecordingCoordinator();
    final container = build(
      coordinator: coordinator,
      vehicle: const VehicleProfile(
          id: 'v1', name: 'Clio', obd2AdapterMac: pinnedMac),
    );

    container.read(_runTrigger)();
    await _pump();

    expect(coordinator.ensuredMacs, [pinnedMac]);
  });

  test('no pinned adapter on the active vehicle → no association attempt',
      () async {
    final coordinator = _RecordingCoordinator();
    final container = build(
      coordinator: coordinator,
      vehicle: const VehicleProfile(id: 'v1', name: 'Clio'),
    );

    container.read(_runTrigger)();
    await _pump();

    expect(coordinator.ensuredMacs, isEmpty);
  });

  test('no active vehicle → no association attempt', () async {
    final coordinator = _RecordingCoordinator();
    final container = build(coordinator: coordinator, vehicle: null);

    container.read(_runTrigger)();
    await _pump();

    expect(coordinator.ensuredMacs, isEmpty);
  });

  test('an unwired vehicle provider graph is swallowed — returns normally, '
      'no attempt', () async {
    final coordinator = _RecordingCoordinator();
    final container =
        build(coordinator: coordinator, vehicleGraphThrows: true);

    expect(container.read(_runTrigger), returnsNormally);
    await _pump();

    expect(coordinator.ensuredMacs, isEmpty);
  });

  test('a throwing coordinator never throws into the trip-start path '
      '(fault injection, #2349)', () async {
    final container = build(
      coordinator: _ThrowingCoordinator(),
      vehicle: const VehicleProfile(
          id: 'v1', name: 'Clio', obd2AdapterMac: pinnedMac),
    );

    expect(container.read(_runTrigger), returnsNormally);
    // Drain the microtask queue: an unhandled async error from the
    // fire-and-forget future would fail the test zone here.
    await _pump();
    await _pump();
  });

  test('a hanging coordinator never blocks — the trigger is fire-and-forget',
      () async {
    final container = build(
      coordinator: _HangingCoordinator(),
      vehicle: const VehicleProfile(
          id: 'v1', name: 'Clio', obd2AdapterMac: pinnedMac),
    );

    // The ensureAssociated future never completes; the trigger must
    // still return synchronously.
    expect(container.read(_runTrigger), returnsNormally);
  });

  test('the coordinator\'s own gates stay safe through the trigger: '
      'FGS-off and unsupported platform are silent no-ops', () async {
    // FGS-off default build (no dart-define) — the dialog machinery is
    // never touched.
    final gateOff = _GateAssociation();
    final offContainer = build(
      coordinator: CompanionAutoRecordCoordinator(
          association: gateOff, fgsEnabled: false),
      vehicle: const VehicleProfile(
          id: 'v1', name: 'Clio', obd2AdapterMac: pinnedMac),
    );
    expect(offContainer.read(_runTrigger), returnsNormally);
    await _pump();
    expect(gateOff.associateCalls, 0);
    expect(gateOff.supportedCalls, 0,
        reason: 'FGS-off must short-circuit before any platform call');

    // FGS-approved build on an unsupported platform (iOS / pre-34).
    final unsupported = _GateAssociation()..supported = false;
    final unsupportedContainer = build(
      coordinator: CompanionAutoRecordCoordinator(
          association: unsupported, fgsEnabled: true),
      vehicle: const VehicleProfile(
          id: 'v1', name: 'Clio', obd2AdapterMac: pinnedMac),
    );
    expect(unsupportedContainer.read(_runTrigger), returnsNormally);
    await _pump();
    expect(unsupported.associateCalls, 0);
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// Hands the trigger a real [Ref], mirroring the production notifier's
/// read path (the `_pipelineProvider` idiom of the GPS-only pipeline test).
final _runTrigger = Provider<void Function()>(
    (ref) => () => triggerCompanionAssociationForPinnedAdapter(ref));

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._v);
  final VehicleProfile? _v;
  @override
  VehicleProfile? build() => _v;
}

class _ThrowingActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() =>
      throw StateError('vehicle provider graph not wired');
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

/// Counts the coordinator gate traffic so the gated no-op tests can assert
/// the dialog machinery is never reached.
class _GateAssociation implements CompanionDeviceAssociation {
  bool supported = true;
  int supportedCalls = 0;
  int associateCalls = 0;
  @override
  Future<bool> isSupported() async {
    supportedCalls++;
    return supported;
  }

  @override
  Future<bool> isAssociated() async => false;
  @override
  Future<bool> associate(String mac) async {
    associateCalls++;
    return true;
  }

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

/// Fault injection: a coordinator override whose future fails — the
/// production coordinator never throws, but the trigger must hold its own
/// never-throws contract even against a misbehaving seam.
class _ThrowingCoordinator extends CompanionAutoRecordCoordinator {
  _ThrowingCoordinator()
      : super(association: _NoopAssociation(), fgsEnabled: true);
  @override
  Future<bool> ensureAssociated(String mac) =>
      Future<bool>.error(StateError('coordinator blew up'));
}

/// A coordinator whose future never completes — the trigger must not await it.
class _HangingCoordinator extends CompanionAutoRecordCoordinator {
  _HangingCoordinator()
      : super(association: _NoopAssociation(), fgsEnabled: true);
  @override
  Future<bool> ensureAssociated(String mac) => Completer<bool>().future;
}
