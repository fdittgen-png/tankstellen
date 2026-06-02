// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/approach/providers/approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/gps_only_recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/approach_overlay_enabled_provider.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2646 integration regression — the fuel-station radar + swipe must work in
/// GPS-only recording, not just OBD2.
///
/// ## What broke
///
/// In GPS-only recording two consumers subscribe to GPS in the same frame:
/// the [GpsOnlyRecordingPipeline] (synchronous, unconditional) and the live
/// [ApproachDetector] (the moment `tripState.isActive` flips true). Each
/// opened its OWN `getPositionStream`; geolocator's single platform
/// EventChannel feeds only one listener, so the recorder starved the detector.
/// The detector never left `ApproachIdle`, so `radarCandidateListProvider`'s
/// `is! ApproachPolling → const []` gate returned an empty list, the radar
/// card showed its placeholder, and swipe — only built on the non-empty data
/// branch — was a literal no-op.
///
/// ## This test
///
/// Drives the REAL pipeline AND the real `approachStateProvider` against ONE
/// fake geolocator that faithfully models the single-channel contention: each
/// `getPositionStream` call returns its own single-subscription controller,
/// and a fix is delivered only to the FIRST-opened controller (the channel
/// "winner"). It then asserts the detector receives the fix → reaches
/// `ApproachPolling` → `radarCandidateListProvider` is non-empty (the radar /
/// swipe path is reachable).
///
/// On master (two raw streams) the detector is starved and this is RED. With
/// the shared, refcounted broadcast source both consumers multiplex onto one
/// underlying subscription, so the detector gets every fix and it is GREEN.

Position _pos({required double lat, required double lng, double speed = 12}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 6, 1, 9),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 0,
    );

/// Geolocator fake that models geolocator's single platform EventChannel:
/// every `getPositionStream` call returns its own Dart-level controller, but
/// they all share ONE platform channel that delivers fixes to only the
/// **most-recently-attached** listener (the platform's onListen replaces the
/// active sink). Two independent raw `getPositionStream` listeners therefore
/// do NOT both receive fixes — the later subscriber wins and the earlier one
/// is starved, exactly the production race.
///
/// In this test the live detector subscribes first (its stream provider
/// builds when the trip flips active), then the recorder subscribes in
/// `pipeline.start()` — so on the pre-#2646 two-raw-streams design the
/// recorder wins and the detector is starved (RED). The `sharedPositionStream`
/// multiplexer collapses both trip consumers onto a SINGLE `getPositionStream`
/// call (one platform listener), so there is exactly one winner and the
/// multiplexer fans every fix out to both (GREEN).
class _ContendingGeolocator extends GeolocatorWrapper {
  final List<StreamController<Position>> _attached = [];

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    late final StreamController<Position> ctl;
    ctl = StreamController<Position>(
      // Last attach wins the single platform channel.
      onListen: () => _attached.add(ctl),
      onCancel: () => _attached.remove(ctl),
    );
    return ctl.stream;
  }

  /// Deliver a fix to the channel winner — the most-recently-attached, still
  /// open listener.
  void emit(Position p) {
    // The controllers are owned by [_attached] and closed in [dispose].
    // ignore: close_sinks
    final winner = _attached.lastOrNull;
    if (winner != null && !winner.isClosed) winner.add(p);
  }

  Future<void> dispose() async {
    for (final c in List.of(_attached)) {
      if (!c.isClosed) await c.close();
    }
  }
}

/// Trip-recording notifier stub reporting a fixed phase so the live detector
/// gate (`tripState.isActive`) passes.
class _RecordingTrip extends TripRecording {
  @override
  TripRecordingState build() =>
      const TripRecordingState(phase: TripRecordingPhase.recording);
}

class _FixedProfile extends ActiveProfile {
  @override
  UserProfile? build() => const UserProfile(
        id: 'p1',
        name: 'Driver',
        approachRadiusKm: 10.0,
        approachMinPollSeconds: 1,
      );
}

/// Radar whose `fetchStations` returns a fixed priced set without network.
class _FakeRadar extends FuelStationRadar {
  _FakeRadar(this.stations)
      : super(
          corridorCache: CorridorLocationCache(
            fetchCorridor: (_, _, _) async => const <Station>[],
          ),
          priceCache: JitPriceCache(fetchPrice: (s) async => s),
          isBulkSource: true,
        );
  final List<Station> stations;

  @override
  Future<List<Station>> fetchStations(
    double lat,
    double lng,
    double radiusKm,
    String fuelTypeApiValue, {
    double? headingDegrees,
  }) async =>
      stations;
}

/// Station service backing `radarCandidateListProvider`'s search.
class _FakeStationService implements StationService {
  _FakeStationService(this._stations);
  final List<Station> _stations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      ServiceResult<List<Station>>(
        data: _stations,
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 6, 1, 9),
      );

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}

const _station = Station(
  id: 's-1',
  name: 'Nearby Station',
  brand: 'STAR',
  street: 'Main St',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5,
  lng: 13.4,
  e10: 1.799,
  dist: 0.3,
  isOpen: true,
);

/// Minimal host so the real pipeline can run without the notifier.
class _Host implements RecordingPipelineHost {
  @override
  TripRecordingState state = const TripRecordingState();
  @override
  String? lastTripVehicleId;
  @override
  DateTime? lastTripStartedAt;

  @override
  String? readActiveVehicleId() => null;
  @override
  void setSaveStage(TripSaveStage stage) {}
  @override
  Future<TripPersistOutcome> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
  }) async =>
      TripPersistOutcome.saved;
}

final _pipelineProvider =
    Provider.family<GpsOnlyRecordingPipeline, RecordingPipelineHost>(
  (ref, host) => GpsOnlyRecordingPipeline(ref: ref, host: host),
);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  silenceErrorLoggerSpool();

  test(
      'GPS-only recording: the recorder + the live ApproachDetector both '
      'consume the shared GPS source, so the detector reaches ApproachPolling '
      'and the radar candidate list is non-empty (#2646)', () async {
    final geo = _ContendingGeolocator();
    addTearDown(geo.dispose);

    final container = ProviderContainer(overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      tripRecordingProvider.overrideWith(_RecordingTrip.new),
      activeProfileProvider.overrideWith(_FixedProfile.new),
      effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
      approachOverlayEnabledProvider.overrideWithValue(true),
      fuelStationRadarProvider.overrideWithValue(_FakeRadar(const [_station])),
      stationServiceProvider
          .overrideWithValue(_FakeStationService(const [_station])),
    ]);
    addTearDown(container.dispose);

    // Keep the live approach detector alive (it subscribes to GPS the moment
    // it builds, because the trip reports `recording`).
    final approachSub = container.listen(approachStateProvider, (_, _) {});
    addTearDown(approachSub.close);
    container.listen(effectiveApproachStateProvider, (_, _) {});

    // The recorder opens its (shared) GPS subscription synchronously — this is
    // the consumer that "wins" the channel in the contention model.
    final pipeline = container.read(_pipelineProvider(_Host()));
    pipeline.start();
    addTearDown(() => pipeline.stop());

    // Let the detector's stream provider build + subscribe.
    await _pump();
    await _pump();

    // One GPS fix: delivered to the channel winner. On the pre-#2646 design
    // the detector is on a SECOND, starved stream and never sees this.
    geo.emit(_pos(lat: 52.5, lng: 13.4));
    await _pump();
    await _pump();

    final approach = container.read(approachStateProvider).value;
    expect(approach, isA<ApproachPolling>(),
        reason: 'the detector must receive the recorder\'s fix and leave '
            'ApproachIdle — on master it is starved and stays Idle');

    final candidates =
        await container.read(radarCandidateListProvider.future);
    expect(candidates, isNotEmpty,
        reason: 'ApproachPolling → radarCandidateListProvider returns the '
            'ranked priced list, so the radar card / swipe path is reachable '
            '(empty on master because the detector never polled)');
    expect(candidates.first.id, _station.id);
  });
}
