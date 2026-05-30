// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approach_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Real-data approach detector (#2163, #2283) — wires [ApproachDetector] to
/// the live trip-recording flow, backed by the Fuel Station Radar.
///
/// Active only while a trip is recording: cold-start cost (a GPS
/// subscription) is bounded to the window where the user is actually
/// driving. The detector is recreated whenever the user edits their profile's
/// approach config or fuel type (per ADR 0011 — the detector itself does not
/// watch the profile).
///
/// ### Data source (#2283)
///
/// The detector's `fetchStations` is delegated to [fuelStationRadarProvider]
/// instead of hitting the search chain on every poll. The radar serves the
/// **cached wide-area corridor** locations (zero network while inside a
/// covered tile) and JIT-fetches the price for only the imminent station(s).
/// The detector's geofence (radius + heading lock) runs locally against that
/// cached set — so the detector's public API and state machine are unchanged;
/// only the bytes flowing into `fetchStations` moved off the per-poll network
/// path onto the corridor cache.
///
/// The UI consumes [effectiveApproachStateProvider] rather than this stream
/// directly, so the in-app simulator (debug button on the trip-recording
/// screen) can override the real signal for testing.

@ProviderFor(approachState)
final approachStateProvider = ApproachStateProvider._();

/// Real-data approach detector (#2163, #2283) — wires [ApproachDetector] to
/// the live trip-recording flow, backed by the Fuel Station Radar.
///
/// Active only while a trip is recording: cold-start cost (a GPS
/// subscription) is bounded to the window where the user is actually
/// driving. The detector is recreated whenever the user edits their profile's
/// approach config or fuel type (per ADR 0011 — the detector itself does not
/// watch the profile).
///
/// ### Data source (#2283)
///
/// The detector's `fetchStations` is delegated to [fuelStationRadarProvider]
/// instead of hitting the search chain on every poll. The radar serves the
/// **cached wide-area corridor** locations (zero network while inside a
/// covered tile) and JIT-fetches the price for only the imminent station(s).
/// The detector's geofence (radius + heading lock) runs locally against that
/// cached set — so the detector's public API and state machine are unchanged;
/// only the bytes flowing into `fetchStations` moved off the per-poll network
/// path onto the corridor cache.
///
/// The UI consumes [effectiveApproachStateProvider] rather than this stream
/// directly, so the in-app simulator (debug button on the trip-recording
/// screen) can override the real signal for testing.

final class ApproachStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApproachState>,
          ApproachState,
          Stream<ApproachState>
        >
    with $FutureModifier<ApproachState>, $StreamProvider<ApproachState> {
  /// Real-data approach detector (#2163, #2283) — wires [ApproachDetector] to
  /// the live trip-recording flow, backed by the Fuel Station Radar.
  ///
  /// Active only while a trip is recording: cold-start cost (a GPS
  /// subscription) is bounded to the window where the user is actually
  /// driving. The detector is recreated whenever the user edits their profile's
  /// approach config or fuel type (per ADR 0011 — the detector itself does not
  /// watch the profile).
  ///
  /// ### Data source (#2283)
  ///
  /// The detector's `fetchStations` is delegated to [fuelStationRadarProvider]
  /// instead of hitting the search chain on every poll. The radar serves the
  /// **cached wide-area corridor** locations (zero network while inside a
  /// covered tile) and JIT-fetches the price for only the imminent station(s).
  /// The detector's geofence (radius + heading lock) runs locally against that
  /// cached set — so the detector's public API and state machine are unchanged;
  /// only the bytes flowing into `fetchStations` moved off the per-poll network
  /// path onto the corridor cache.
  ///
  /// The UI consumes [effectiveApproachStateProvider] rather than this stream
  /// directly, so the in-app simulator (debug button on the trip-recording
  /// screen) can override the real signal for testing.
  ApproachStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approachStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approachStateHash();

  @$internal
  @override
  $StreamProviderElement<ApproachState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ApproachState> create(Ref ref) {
    return approachState(ref);
  }
}

String _$approachStateHash() => r'65cc7b55def7d6213d818cd779520c3f0bd09ad6';
