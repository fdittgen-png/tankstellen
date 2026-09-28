// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_input_provider.g.dart';

/// What a route endpoint MEANS, not just where it is (#4432).
enum EndpointIntent {
  /// A place the user named — typed, autocompleted or picked. It stays
  /// put: a refresh re-prices the same route.
  fixed,

  /// "Where I am": the device position, re-read from GPS at every
  /// submission. The coordinate is only the last accepted fix.
  currentLocation,
}

/// One route endpoint: its coordinate plus the intent behind it (#4432).
///
/// Start and destination are modelled the same way so that Swap moves
/// the COMPLETE semantic value between the slots. Before, only the start
/// could be "current location"; swapping it into the destination slot
/// carried the coordinate across and silently dropped the meaning, so a
/// search planned "from Geneva to where I am" routed to wherever the
/// driver had been when they last tapped the GPS button.
@immutable
class RouteEndpoint {
  const RouteEndpoint({
    this.coords,
    this.intent = EndpointIntent.fixed,
    this.capturedAt,
  });

  /// A named place (or nothing yet): never current-location.
  const RouteEndpoint.fixed(this.coords)
      : intent = EndpointIntent.fixed,
        capturedAt = null;

  final LatLng? coords;
  final EndpointIntent intent;

  /// When [coords] was MEASURED, for a current-location endpoint.
  /// Stamped through the injected `AppClock` seam, never the raw wall
  /// clock — an "age of fix" that disagrees with the test's calendar is
  /// not a test.
  final DateTime? capturedAt;

  bool get isCurrentLocation => intent == EndpointIntent.currentLocation;

  @override
  bool operator ==(Object other) =>
      other is RouteEndpoint &&
      other.coords == coords &&
      other.intent == intent &&
      other.capturedAt == capturedAt;

  @override
  int get hashCode => Object.hash(coords, intent, capturedAt);
}

/// Which endpoint of the route an operation addresses.
enum RouteEndpointSlot { start, end }

/// State for the route input widget: resolved coordinates for start/end/stops
/// plus the number of stops and the in-flight search flag.
///
/// Text field values are kept in local `TextEditingController`s (must live in
/// a `StatefulWidget` for lifecycle reasons). Everything else is here so that
/// widget rebuilds are selective and setState is avoided.
class RouteInputState {
  /// #4432 — the start, with its intent. See [RouteEndpoint].
  final RouteEndpoint start;

  /// #4432 — the destination, modelled exactly like [start].
  final RouteEndpoint end;

  final List<LatLng?> stopCoords;
  final int stopCount;
  final bool isSearching;

  /// Whether the start / destination fields have any text (#2131).
  /// Surfaced so the criteria-screen FAB can mirror the inline submit
  /// button's enabled state without taking ownership of the text
  /// controllers (which must live in [RouteInput] for lifecycle reasons).
  final bool hasStartText;
  final bool hasEndText;

  const RouteInputState({
    this.start = const RouteEndpoint(),
    this.end = const RouteEndpoint(),
    this.stopCoords = const [],
    this.stopCount = 0,
    this.isSearching = false,
    this.hasStartText = false,
    this.hasEndText = false,
  });

  LatLng? get startCoords => start.coords;
  LatLng? get endCoords => end.coords;

  /// #4432 — the start is the "current position" one, captured from GPS
  /// rather than typed or picked from the autocomplete.
  ///
  /// The field said "Current location" while holding wherever the driver
  /// was when they last tapped the GPS button. At motorway speed that is
  /// tens of kilometres, and the route was then drawn from there. The
  /// intent is what lets the search re-read GPS before routing, and what
  /// lets the UI qualify the label when the re-read fails.
  bool get startIsCurrentLocation => start.isCurrentLocation;

  /// When [startCoords] was read from GPS, or null when it was not.
  DateTime? get startCapturedAt => start.capturedAt;

  /// #4432 — the destination holds "where I am" (after a Swap).
  bool get endIsCurrentLocation => end.isCurrentLocation;

  DateTime? get endCapturedAt => end.capturedAt;

  RouteEndpoint endpoint(RouteEndpointSlot slot) =>
      slot == RouteEndpointSlot.start ? start : end;

  /// True when both endpoints carry text and no search is in flight —
  /// the same gate the (now removed) inline `RouteSearchButton` used.
  bool get canSearch => hasStartText && hasEndText && !isSearching;

  RouteInputState copyWith({
    RouteEndpoint? start,
    RouteEndpoint? end,
    List<LatLng?>? stopCoords,
    int? stopCount,
    bool? isSearching,
    bool? hasStartText,
    bool? hasEndText,
  }) {
    return RouteInputState(
      start: start ?? this.start,
      end: end ?? this.end,
      stopCoords: stopCoords ?? this.stopCoords,
      stopCount: stopCount ?? this.stopCount,
      isSearching: isSearching ?? this.isSearching,
      hasStartText: hasStartText ?? this.hasStartText,
      hasEndText: hasEndText ?? this.hasEndText,
    );
  }
}

@riverpod
class RouteInputController extends _$RouteInputController {
  @override
  RouteInputState build() => const RouteInputState();

  /// Set a start the user NAMED — typed, autocompleted or picked.
  ///
  /// #4432 — always clears the current-location intent and its capture
  /// stamp: whatever this coordinate is, it is no longer "where I am".
  void setStartCoords(LatLng? coords) {
    state = state.copyWith(start: RouteEndpoint.fixed(coords));
  }

  /// #4432 — set the start from a GPS fix taken at [capturedAt].
  ///
  /// Distinct from [setStartCoords] because the pair (coordinate,
  /// when it was read) is the whole point: the search re-reads GPS
  /// before routing, and shows the age when it cannot.
  void setStartFromCurrentPosition(LatLng coords, DateTime capturedAt) =>
      setFromCurrentPosition(RouteEndpointSlot.start, coords, capturedAt);

  /// Set a destination the user NAMED; clears any current-location
  /// intent, exactly like [setStartCoords].
  void setEndCoords(LatLng? coords) {
    state = state.copyWith(end: RouteEndpoint.fixed(coords));
  }

  /// #4432 — record a GPS fix for whichever endpoint holds the
  /// current-location intent.
  void setFromCurrentPosition(
    RouteEndpointSlot slot,
    LatLng coords,
    DateTime capturedAt,
  ) {
    final endpoint = RouteEndpoint(
      coords: coords,
      intent: EndpointIntent.currentLocation,
      capturedAt: capturedAt,
    );
    state = slot == RouteEndpointSlot.start
        ? state.copyWith(start: endpoint)
        : state.copyWith(end: endpoint);
  }

  /// #3927 / #4432 — exchange start and destination as complete values:
  /// coordinate, intent and fix time travel together, so "current
  /// location" swapped into the destination is still re-read from GPS at
  /// the next search.
  void swapEndpoints() {
    state = state.copyWith(start: state.end, end: state.start);
  }

  void setStopCoord(int index, LatLng? coords) {
    final updated = List<LatLng?>.from(state.stopCoords);
    if (index >= 0 && index < updated.length) {
      updated[index] = coords;
      state = state.copyWith(stopCoords: updated);
    }
  }

  void addStop() {
    final updated = List<LatLng?>.from(state.stopCoords)..add(null);
    state =
        state.copyWith(stopCoords: updated, stopCount: state.stopCount + 1);
  }

  void removeStop(int index) {
    if (index < 0 || index >= state.stopCoords.length) return;
    final updated = List<LatLng?>.from(state.stopCoords)..removeAt(index);
    state =
        state.copyWith(stopCoords: updated, stopCount: state.stopCount - 1);
  }

  void setSearching(bool value) {
    state = state.copyWith(isSearching: value);
  }

  void setHasStartText(bool value) {
    if (state.hasStartText == value) return;
    state = state.copyWith(hasStartText: value);
  }

  void setHasEndText(bool value) {
    if (state.hasEndText == value) return;
    state = state.copyWith(hasEndText: value);
  }

  void reset() {
    state = const RouteInputState();
  }
}
