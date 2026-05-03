import 'package:freezed_annotation/freezed_annotation.dart';

part 'traffic_signal.freezed.dart';
part 'traffic_signal.g.dart';

/// One traffic-signal node sourced from OpenStreetMap (#1125 phase 1).
///
/// Represents a single OSM `node` tagged `highway=traffic_signals`. The
/// future glide-coach feature consumes this stream of signals to detect
/// "imminent red lights ahead" given the user's current GPS heading and
/// suggest a coast/throttle-off moment to save fuel.
///
/// Phase 1 is the bounded data layer only: domain entity + Overpass API
/// client + Hive cache. Subsequent phases (imminent-signal detection,
/// throttle correlation, haptic firing) all need device testing and live
/// outside the autonomous-worker scope.
///
/// Field semantics mirror the Overpass JSON shape so this entity can be
/// re-serialised back to disk without lossy translation:
/// - [id] is the OSM node id, stringified so future sources (custom
///   community-mapped signals, manual annotations) can use non-numeric ids.
/// - [lat] / [lng] use OSM convention — latitude first, longitude second.
/// - [crossing] mirrors `tags.crossing` (e.g. `traffic_signals`,
///   `marked`, `uncontrolled`); null when the node has no `crossing` tag.
/// - [highway] mirrors `tags.highway` (always `traffic_signals` in
///   practice for the bounded query, but persisted for future tag-based
///   filtering).
@freezed
abstract class TrafficSignal with _$TrafficSignal {
  const factory TrafficSignal({
    required String id,
    required double lat,
    required double lng,
    String? crossing,
    String? highway,
  }) = _TrafficSignal;

  factory TrafficSignal.fromJson(Map<String, dynamic> json) =>
      _$TrafficSignalFromJson(json);
}
