// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/data/pip_controller.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_banner.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_pip_price_layout.dart';
import 'package:tankstellen/features/consumption/providers/pip_mode_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2677 — the on-search Fuel Station Radar carries the same pin +
/// reduce-to-PiP controls the trip-recording screen has, and the PiP small
/// window reuses the trip price layout. Android-only — the controller is a
/// no-op on every other platform, so the test forces the Android code path.

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

Station _station(String id) => Station(
      id: id,
      name: 'Station $id',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '00000',
      place: 'Test',
      lat: 48.0,
      lng: 2.0,
      dist: 1.2,
      e10: 1.659,
      isOpen: true,
    );

class _ActiveRadar extends RadarSearch {
  _ActiveRadar(this._stations);
  final List<Station> _stations;

  @override
  RadarSearchState build() => RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(_stations),
      );
}

class _IdleTrip extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tankstellen/pip');

  testWidgets(
      'radar active → pin + minimise buttons in the AppBar; minimise taps '
      'enterPip', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <String>[];
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'enterPip') return true;
      return null;
    });

    final pip = PipController();
    addTearDown(pip.dispose);

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
        radarSearchProvider.overrideWith(
          () => _ActiveRadar([_station('NEAR')]),
        ),
      ],
    );

    expect(find.byKey(const Key('radarPinButton')), findsOneWidget);
    expect(find.byKey(const Key('radarMinimiseButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('radarMinimiseButton')));
    await tester.pumpAndSettle();

    expect(calls, contains('enterPip'),
        reason: 'minimise must request a PiP transition over the channel');

    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      '#2974 — tapping the radar pin button fires a selectionClick haptic',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final haptics = <String?>[];
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String?);
      }
      return null;
    });
    addTearDown(() => TestWidgetsFlutterBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

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
        radarSearchProvider.overrideWith(
          () => _ActiveRadar([_station('NEAR')]),
        ),
      ],
    );

    // The radar starts unpinned (auto-pin preference defaults are mocked off
    // in the standard overrides). Tapping the pin button must buzz.
    haptics.clear();
    await tester.tap(find.byKey(const Key('radarPinButton')));
    await tester.pumpAndSettle();

    expect(haptics, contains('HapticFeedbackType.selectionClick'),
        reason: 'the pin TOGGLE fires a selection tick');

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'PiP small window with on-search radar active + a nearest station '
      'renders the trip price layout (no trip needed)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey()).thenReturn(false);

    await pumpApp(
      tester,
      const TripRecordingBanner(child: SizedBox.shrink()),
      overrides: [
        ...test.overrides,
        // OS has shrunk the app into the PiP tile …
        pipModeProvider.overrideWith(() => _AlwaysPip()),
        // … with no trip recording …
        tripRecordingProvider.overrideWith(_IdleTrip.new),
        // … but the on-search radar is active with a nearest station.
        radarSearchProvider.overrideWith(
          () => _ActiveRadar([_station('NEAR')]),
        ),
      ],
    );

    expect(find.byType(TripRecordingPipPriceLayout), findsOneWidget);
    // The nearest radar station's name leads the tile (price + km layout).
    expect(find.text('Station NEAR'), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });
}

class _AlwaysPip extends PipMode {
  @override
  bool build() => true;
}
