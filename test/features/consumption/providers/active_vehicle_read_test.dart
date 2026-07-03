// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/providers/active_vehicle_read.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3437/#3438 — the shared guarded active-vehicle read the trip-recording
/// notifier, the GPS-only pipeline and the CDM trigger all delegate to.
/// Pins the never-throws contract with a fault-injected provider graph.
void main() {
  silenceErrorLoggerSpool();

  test('returns the active vehicle when the graph is wired', () {
    const vehicle = VehicleProfile(id: 'v1', name: 'Clio');
    final container = ProviderContainer(overrides: [
      activeVehicleProfileProvider.overrideWith(() => _Stub(vehicle)),
    ]);
    addTearDown(container.dispose);

    expect(container.read(_read)(), vehicle);
  });

  test('returns null when no vehicle is active', () {
    final container = ProviderContainer(overrides: [
      activeVehicleProfileProvider.overrideWith(() => _Stub(null)),
    ]);
    addTearDown(container.dispose);

    expect(container.read(_read)(), isNull);
  });

  test('a throwing provider graph is swallowed — null, never throws '
      '(fault injection, #2349)', () {
    final container = ProviderContainer(overrides: [
      activeVehicleProfileProvider.overrideWith(_Throwing.new),
    ]);
    addTearDown(container.dispose);

    expect(container.read(_read), returnsNormally);
    expect(container.read(_read)(), isNull);
  });
}

/// Hands the helper a real [Ref] (the `_pipelineProvider` idiom).
final _read = Provider<VehicleProfile? Function()>((ref) =>
    () => tryReadActiveVehicleProfile(ref, where: 'active_vehicle_read test'));

class _Stub extends ActiveVehicleProfile {
  _Stub(this._v);
  final VehicleProfile? _v;
  @override
  VehicleProfile? build() => _v;
}

class _Throwing extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() =>
      throw StateError('vehicle provider graph not wired');
}
