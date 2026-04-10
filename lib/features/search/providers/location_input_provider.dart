import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/location_search_service.dart';

part 'location_input_provider.g.dart';

/// UI state for the unified LocationInput widget. Holds the detected
/// input type, search-in-progress flag, city suggestions and the
/// user-selected city. The TextEditingController itself stays local
/// to the widget.
class LocationInputState {
  final LocationInputType inputType;
  final List<ResolvedLocation> suggestions;
  final ResolvedLocation? selectedCity;
  final bool isSearching;

  const LocationInputState({
    this.inputType = LocationInputType.gps,
    this.suggestions = const [],
    this.selectedCity,
    this.isSearching = false,
  });

  LocationInputState copyWith({
    LocationInputType? inputType,
    List<ResolvedLocation>? suggestions,
    ResolvedLocation? selectedCity,
    bool clearSelectedCity = false,
    bool? isSearching,
  }) {
    return LocationInputState(
      inputType: inputType ?? this.inputType,
      suggestions: suggestions ?? this.suggestions,
      selectedCity:
          clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

@riverpod
class LocationInputController extends _$LocationInputController {
  @override
  LocationInputState build() => const LocationInputState();

  void setInputType(LocationInputType type) {
    state = state.copyWith(
      inputType: type,
      clearSelectedCity: true,
      suggestions: type != LocationInputType.city ? const [] : state.suggestions,
    );
  }

  void setSearching(bool value) => state = state.copyWith(isSearching: value);

  void setSuggestions(List<ResolvedLocation> suggestions) =>
      state = state.copyWith(suggestions: suggestions);

  void selectCity(ResolvedLocation city) {
    state = state.copyWith(
      selectedCity: city,
      suggestions: const [],
    );
  }

  void clear() {
    state = const LocationInputState();
  }
}
