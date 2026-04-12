import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_station_provider.g.dart';

/// Tracks the currently selected station ID for inline detail display.
///
/// On wide screens, selecting a station shows its detail in a side panel
/// rather than navigating to a new route.
@riverpod
class SelectedStation extends _$SelectedStation {
  @override
  String? build() => null;

  void select(String stationId) => state = stationId;

  void clear() => state = null;
}
