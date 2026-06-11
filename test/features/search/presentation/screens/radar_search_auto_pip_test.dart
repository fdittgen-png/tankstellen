// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/data/pip_controller.dart';
import 'package:tankstellen/features/consumption/providers/pip_mode_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2678 — while the on-search Fuel Station Radar owns the search results, the
/// native auto-PiP opt-in is ARMED so the app shrinks into the tile when the
/// user leaves to Maps mid-scan; dismissing the radar disarms it. Android-only
/// — the controller is a no-op elsewhere, so force the Android code path.

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

Station _station() => const Station(
      id: 'NEAR',
      name: 'Station NEAR',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '00000',
      place: 'Test',
      lat: 48.0,
      lng: 2.0,
      dist: 1.0,
      e10: 1.5,
      isOpen: true,
    );

/// Toggleable radar so the test can flip active → inactive at runtime.
class _ToggleRadar extends RadarSearch {
  @override
  RadarSearchState build() => RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>([_station()]),
      );

  void deactivate() => state = RadarSearchState.idle;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tankstellen/pip');

  testWidgets(
      'radar active arms auto-PiP once; dismiss disarms it', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final autoEnterCalls = <bool>[];
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setAutoEnter') {
        autoEnterCalls.add(call.arguments == true);
      }
      return null;
    });

    final pip = PipController();
    addTearDown(pip.dispose);
    final radar = _ToggleRadar();

    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey()).thenReturn(false);
    when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
    when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});

    await pumpApp(
      tester,
      const SearchScreen(),
      overrides: [
        ...test.overrides,
        userPositionNullOverride(),
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
        pipControllerProvider.overrideWithValue(pip),
        pipModeProvider.overrideWith(() => _NeverPip()),
        radarSearchProvider.overrideWith(() => radar),
      ],
    );
    await tester.pump();

    expect(autoEnterCalls.contains(true), isTrue,
        reason: 'auto-PiP must be armed while the radar owns the results');

    // Dismiss the radar → the opt-in disarms.
    autoEnterCalls.clear();
    radar.deactivate();
    await tester.pumpAndSettle();

    expect(autoEnterCalls.contains(false), isTrue,
        reason: 'dismissing the radar must disarm auto-PiP');

    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _NeverPip extends PipMode {
  @override
  bool build() => false;
}
