// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/features/approach/providers/approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Unit tests for the live `approachStateProvider` (#2163 / #2283) — the
/// real-data wire that subscribes to the GPS stream and feeds an
/// [ApproachDetector] only while a trip is recording. Adapted from
/// `test/core/location/movement_detection_provider_test.dart`.
///
/// Covers the lifecycle the merge layer and the simulator tests do NOT:
///   - trip inactive / no profile → `ApproachIdle`, GPS NOT subscribed
///   - trip active + profile → GPS subscribed, detector emits states
///   - dispose / trip-end → GPS subscription torn down
///   - re-enable (inactive → active) → GPS re-subscribed (fresh detector)
Position _pos({required double lat, required double lng, double speed = 10}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 5, 1, 9, 0, 0),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

/// Geolocator fake exposing a controllable broadcast stream so the test
/// can observe subscription lifecycle (`hasListener`) and push fixes.
class _FakeGeolocator extends GeolocatorWrapper {
  final StreamController<Position> controller =
      StreamController<Position>.broadcast();

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      controller.stream;

  void close() {
    if (!controller.isClosed) controller.close();
  }
}

/// [FuelStationRadar] subclass whose `fetchStations` returns a fixed list
/// without touching the network or the caches. The caches are real but
/// their fetch closures are stubs that are never reached because we
/// override `fetchStations` itself.
class _FakeRadar extends FuelStationRadar {
  final List<Station> stations;
  int fetchCalls = 0;

  _FakeRadar(this.stations)
      : super(
          corridorCache: CorridorLocationCache(
            fetchCorridor: (_, _, _) async => const <Station>[],
          ),
          priceCache: JitPriceCache(fetchPrice: (s) async => s),
          isBulkSource: true,
        );

  @override
  Future<List<Station>> fetchStations(
    double lat,
    double lng,
    double radiusKm,
    String fuelTypeApiValue, {
    double? headingDegrees,
  }) async {
    fetchCalls++;
    return stations;
  }
}

/// Mutable holder so a single override factory can flip the reported
/// trip phase between `build()` invalidations — Riverpod reuses the
/// notifier instance on `invalidate`, so capturing the phase in the
/// constructor would freeze it. Reading the holder inside `build()` is
/// what lets the re-enable test simulate "trip just started".
class _TripPhaseHolder {
  _TripPhaseHolder(this.phase);
  TripRecordingPhase phase;
}

/// Trip-recording notifier stub that reports the holder's current phase.
class _FakeTripRecording extends TripRecording {
  final _TripPhaseHolder holder;
  _FakeTripRecording(this.holder);

  @override
  TripRecordingState build() => TripRecordingState(phase: holder.phase);
}

/// Active-profile notifier stub returning a fixed profile (or null).
class _FakeActiveProfile extends ActiveProfile {
  final UserProfile? profile;
  _FakeActiveProfile(this.profile);

  @override
  UserProfile? build() => profile;
}

const _profile = UserProfile(
  id: 'p1',
  name: 'Test Driver',
  approachRadiusKm: 1.0,
  approachMinPollSeconds: 5,
);

const _station = Station(
  id: 's-1',
  name: 'Test Station',
  brand: 'STAR',
  street: 'Test Street',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5,
  lng: 13.4,
  e10: 1.799,
  isOpen: true,
);

ProviderContainer _container({
  required _FakeGeolocator geo,
  required _FakeRadar radar,
  required TripRecordingPhase phase,
  UserProfile? profile = _profile,
  FuelType fuel = FuelType.e10,
}) {
  final holder = _TripPhaseHolder(phase);
  return ProviderContainer(
    overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      fuelStationRadarProvider.overrideWithValue(radar),
      tripRecordingProvider.overrideWith(() => _FakeTripRecording(holder)),
      activeProfileProvider.overrideWith(() => _FakeActiveProfile(profile)),
      effectiveFuelTypeProvider.overrideWithValue(fuel),
    ],
  );
}

void main() {
  group('approachStateProvider lifecycle (#2163 / #2283)', () {
    late _FakeGeolocator geo;
    late _FakeRadar radar;

    setUp(() {
      geo = _FakeGeolocator();
      radar = _FakeRadar(const [_station]);
    });

    tearDown(() => geo.close());

    test('no trip active → ApproachIdle and the GPS stream is NOT subscribed',
        () async {
      final container = _container(
        geo: geo,
        radar: radar,
        phase: TripRecordingPhase.idle,
      );
      addTearDown(container.dispose);

      final sub = container.listen(approachStateProvider, (_, _) {});
      addTearDown(sub.close);

      // `Stream.value(...)` emits on a microtask — pump so the AsyncValue
      // carries the data instead of the initial AsyncLoading.
      await container.read(approachStateProvider.future);

      expect(sub.read().value, isA<ApproachIdle>(),
          reason: 'idle trip yields the constant idle stream');
      expect(geo.controller.hasListener, isFalse,
          reason: 'cost-bounded: no GPS subscription unless recording');
    });

    test('profile == null → ApproachIdle even when a trip is active',
        () async {
      final container = _container(
        geo: geo,
        radar: radar,
        phase: TripRecordingPhase.recording,
        profile: null,
      );
      addTearDown(container.dispose);

      final sub = container.listen(approachStateProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(approachStateProvider.future);

      expect(sub.read().value, isA<ApproachIdle>());
      expect(geo.controller.hasListener, isFalse);
    });

    test(
        'trip recording + profile → GPS subscribed; a fix drives the detector '
        'off Idle into Polling', () async {
      final container = _container(
        geo: geo,
        radar: radar,
        phase: TripRecordingPhase.recording,
      );
      addTearDown(container.dispose);

      final states = <ApproachState>[];
      final sub = container.listen<AsyncValue<ApproachState>>(
        approachStateProvider,
        (_, next) {
          final v = next.value;
          if (v != null) states.add(v);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // The detector subscribes to the GPS stream synchronously on build.
      expect(geo.controller.hasListener, isTrue,
          reason: 'an active trip must subscribe to the position stream');

      // First fix → detector emits ApproachPolling immediately (#2084).
      geo.controller.add(_pos(lat: 52.50, lng: 13.40));
      await Future<void>.delayed(Duration.zero);

      expect(
        states.whereType<ApproachPolling>(),
        isNotEmpty,
        reason: 'first GPS sample must flip the detector from Idle → Polling',
      );
    });

    test('disposing the container tears down the GPS subscription', () async {
      final container = _container(
        geo: geo,
        radar: radar,
        phase: TripRecordingPhase.recording,
      );

      final sub = container.listen(approachStateProvider, (_, _) {});
      // Force the stream provider to build + subscribe.
      sub.read();
      await Future<void>.delayed(Duration.zero);
      expect(geo.controller.hasListener, isTrue);

      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(
        geo.controller.hasListener,
        isFalse,
        reason: 'ref.onDispose(detector.dispose) must cancel the GPS '
            'subscription when the provider is torn down',
      );
    });

    test(
        're-enable (trip idle → recording) re-subscribes with a fresh '
        'detector; the previous subscription is gone', () async {
      // Start idle: no subscription. The holder lets us flip the phase
      // while Riverpod reuses the notifier instance on invalidate.
      final holder = _TripPhaseHolder(TripRecordingPhase.idle);
      final container = ProviderContainer(
        overrides: [
          geolocatorWrapperProvider.overrideWithValue(geo),
          fuelStationRadarProvider.overrideWithValue(radar),
          tripRecordingProvider.overrideWith(() => _FakeTripRecording(holder)),
          activeProfileProvider.overrideWith(() => _FakeActiveProfile(_profile)),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive across the flip with a real listener.
      final sub = container.listen<AsyncValue<ApproachState>>(
        approachStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      expect(geo.controller.hasListener, isFalse,
          reason: 'idle → no GPS subscription');

      // Flip the trip to recording and invalidate so the keep-alive stream
      // provider rebuilds against the new trip state. Invalidating the
      // dependent provider as well forces the eager rebuild (and the
      // detector + GPS subscription) instead of waiting for a passive
      // re-listen.
      holder.phase = TripRecordingPhase.recording;
      container.invalidate(tripRecordingProvider);
      container.invalidate(approachStateProvider);
      // Re-establish a listener so the keep-alive provider rebuilds eagerly.
      final sub2 = container.listen<AsyncValue<ApproachState>>(
        approachStateProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub2.close);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        geo.controller.hasListener,
        isTrue,
        reason: 're-entering a recording trip must spin up a fresh detector '
            'and re-subscribe to the GPS stream',
      );
    });
  });
}
