import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_input_provider.g.dart';

/// State for the route input widget: resolved coordinates for start/end/stops
/// plus the number of stops and the in-flight search flag.
///
/// Text field values are kept in local `TextEditingController`s (must live in
/// a `StatefulWidget` for lifecycle reasons). Everything else is here so that
/// widget rebuilds are selective and setState is avoided.
class RouteInputState {
  final LatLng? startCoords;
  final LatLng? endCoords;
  final List<LatLng?> stopCoords;
  final int stopCount;
  final bool isSearching;

  const RouteInputState({
    this.startCoords,
    this.endCoords,
    this.stopCoords = const [],
    this.stopCount = 0,
    this.isSearching = false,
  });

  RouteInputState copyWith({
    LatLng? startCoords,
    bool clearStartCoords = false,
    LatLng? endCoords,
    bool clearEndCoords = false,
    List<LatLng?>? stopCoords,
    int? stopCount,
    bool? isSearching,
  }) {
    return RouteInputState(
      startCoords:
          clearStartCoords ? null : (startCoords ?? this.startCoords),
      endCoords: clearEndCoords ? null : (endCoords ?? this.endCoords),
      stopCoords: stopCoords ?? this.stopCoords,
      stopCount: stopCount ?? this.stopCount,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

@riverpod
class RouteInputController extends _$RouteInputController {
  @override
  RouteInputState build() => const RouteInputState();

  void setStartCoords(LatLng? coords) {
    state = state.copyWith(
      startCoords: coords,
      clearStartCoords: coords == null,
    );
  }

  void setEndCoords(LatLng? coords) {
    state = state.copyWith(
      endCoords: coords,
      clearEndCoords: coords == null,
    );
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

  void reset() {
    state = const RouteInputState();
  }
}
