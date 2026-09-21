// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/trips/domain/services/motion_gate.dart';
import 'package:tankstellen/features/trips/providers/motion_gated_gps_source.dart';

/// #4353 — the recording GPS source runs ONE stable, actually-applied
/// profile for the whole trip.
///
/// ## Why the swap had to go
///
/// `onSpeed` used to open a new `sharedPositionStream` at the gate's new
/// cadence and cancel the old one afterwards. `geolocator_android` caches
/// its `_positionStream` and clears the cache only on last-listener cancel
/// (`geolocator_android-5.0.3/lib/src/geolocator_android.dart:169-171`,
/// `:207-212`), so the overlapping re-open was handed the OLD stream at the
/// OLD settings: the cadence never actually changed, and `profile` reported
/// a battery saving that had not happened. A swap that DID land would be
/// worse still — it tears the recording foreground service down and
/// re-promotes it mid-trip, a background start Android may refuse.
///
/// So the gate is still evaluated (its verdict is journalled as
/// [MotionGatedGpsSource.wouldBeProfile]) but it no longer touches the
/// subscription, and [MotionGatedGpsSource.profile] reports only what is
/// APPLIED.
class _CountingGeolocator extends GeolocatorWrapper {
  int sharedOpens = 0;
  final List<LocationSettings?> openedSettings = [];
  final List<StreamController<Position>> _controllers = [];

  @override
  Stream<Position> sharedPositionStream({
    LocationSettings? locationSettings,
    bool recording = false,
  }) {
    sharedOpens++;
    openedSettings.add(locationSettings);
    final ctl = StreamController<Position>.broadcast();
    _controllers.add(ctl);
    return ctl.stream;
  }

  Future<void> dispose() async {
    for (final c in _controllers) {
      if (!c.isClosed) await c.close();
    }
  }
}

void main() {
  late _CountingGeolocator geo;
  late ProviderContainer container;

  MotionGatedGpsSource build({bool fgsEnabled = true, MotionGate? gate}) {
    final harness = Provider<MotionGatedGpsSource>(
      (ref) => MotionGatedGpsSource(
        ref: ref,
        onPosition: (_) {},
        gate: gate,
        foregroundServiceEnabled: fgsEnabled,
      ),
    );
    return container.read(harness);
  }

  setUp(() {
    geo = _CountingGeolocator();
    container = ProviderContainer(
      overrides: [geolocatorWrapperProvider.overrideWithValue(geo)],
    );
  });

  tearDown(() async {
    container.dispose();
    await geo.dispose();
  });

  group('MotionGatedGpsSource stable profile (#4353)', () {
    test(
        'a stationary stretch NEVER re-opens the subscription, and the '
        'applied profile stays fine', () async {
      final source = build()..start();
      expect(geo.sharedOpens, 1);

      // 60 s of standing still: the old gate would have swapped to coarse
      // here (and, because of the plugin cache, changed nothing but the
      // reported profile).
      for (var s = 1; s <= 60; s++) {
        source.onSpeed(0, Duration(seconds: s));
      }

      expect(geo.sharedOpens, 1,
          reason: 'no mid-trip swap: one stable, applied profile per trip');
      expect(source.profile, GpsProfile.fine,
          reason: 'profile reports what is APPLIED, and nothing changed it');

      await source.cancel();
    });

    test(
        "the gate's verdict is still recorded as wouldBeProfile, for the "
        'journal', () async {
      final source = build()..start();
      expect(source.wouldBeProfile, GpsProfile.fine);

      // Sustained slow-and-still past MotionGate.stationaryAfter (20 s).
      for (var s = 1; s <= 30; s++) {
        source.onSpeed(0, Duration(seconds: s));
      }
      expect(source.wouldBeProfile, GpsProfile.coarse,
          reason: 'the saving adaptive sampling WOULD have made is visible');
      expect(source.profile, GpsProfile.fine,
          reason: 'but it was not applied, and profile must not claim it was');

      // Pulling away re-fines the verdict immediately.
      source.onSpeed(40, const Duration(seconds: 31));
      expect(source.wouldBeProfile, GpsProfile.fine);
      expect(geo.sharedOpens, 1);

      await source.cancel();
    });

    test('the verdict is computed even in a build that could not apply it',
        () async {
      final source = build(fgsEnabled: false)..start();
      expect(source.adaptiveSamplingSupported, isFalse,
          reason: 'no recording FGS: a coarse profile would save nothing');

      for (var s = 1; s <= 30; s++) {
        source.onSpeed(0, Duration(seconds: s));
      }
      expect(source.wouldBeProfile, GpsProfile.coarse);
      expect(source.profile, GpsProfile.fine);
      expect(geo.sharedOpens, 1);

      await source.cancel();
    });

    test('the one subscription is opened as a recording consumer', () async {
      final source = build()..start();
      expect(geo.openedSettings, hasLength(1));
      expect(geo.openedSettings.single, isNotNull,
          reason: 'the fine recording settings, not a bare default');

      await source.cancel();
      expect(geo.sharedOpens, 1);
    });
  });
}
