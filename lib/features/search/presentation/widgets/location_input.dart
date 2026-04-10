import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/services/location_search_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/location_input_provider.dart';

/// Unified location input: auto-detects GPS (empty), ZIP (digits), or city (text).
/// Replaces the old 3-tab GPS/ZIP/City UI.
class LocationInput extends ConsumerStatefulWidget {
  final void Function() onGpsSearch;
  final void Function(String zip) onZipSearch;
  final void Function(ResolvedLocation city) onCitySearch;

  const LocationInput({
    super.key,
    required this.onGpsSearch,
    required this.onZipSearch,
    required this.onCitySearch,
  });

  @override
  ConsumerState<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends ConsumerState<LocationInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Pre-fill with profile's home zip code if configured
    safePostFrame(() {
      final profile = ref.read(activeProfileProvider);
      if (profile?.homeZipCode != null && profile!.homeZipCode!.isNotEmpty) {
        _controller.text = profile.homeZipCode!;
        _onChanged(profile.homeZipCode!);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final country = ref.read(activeCountryProvider);
    final service = ref.read(locationSearchServiceProvider);
    final type = service.detectInputType(value, country);

    ref.read(locationInputControllerProvider.notifier).setInputType(type);

    if (type == LocationInputType.city) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        _fetchSuggestions(value);
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    final controller = ref.read(locationInputControllerProvider.notifier);
    controller.setSearching(true);
    try {
      final service = ref.read(locationSearchServiceProvider);
      final results = await service.searchCities(query);
      if (mounted) controller.setSuggestions(results);
    } finally {
      if (mounted) controller.setSearching(false);
    }
  }

  void _submit() {
    final country = ref.read(activeCountryProvider);
    final uiState = ref.read(locationInputControllerProvider);
    final text = _controller.text.trim();

    if (uiState.selectedCity != null) {
      widget.onCitySearch(uiState.selectedCity!);
      return;
    }

    switch (uiState.inputType) {
      case LocationInputType.gps:
        widget.onGpsSearch();
      case LocationInputType.zip:
        if (RegExp(country.postalCodeRegex).hasMatch(text)) {
          widget.onZipSearch(text);
        } else {
          final l10n = AppLocalizations.of(context);
          SnackBarHelper.showError(
            context,
            l10n?.invalidPostalCode(
                    country.postalCodeLength.toString(), country.postalCodeLabel) ??
                'Please enter a valid ${country.postalCodeLength}-digit ${country.postalCodeLabel}',
          );
        }
      case LocationInputType.city:
        // If they typed a city but didn't select a suggestion, search anyway
        if (uiState.suggestions.isNotEmpty) {
          widget.onCitySearch(uiState.suggestions.first);
        }
    }
  }

  IconData _prefixIcon(LocationInputType type) => switch (type) {
        LocationInputType.gps => Icons.my_location,
        LocationInputType.zip => Icons.pin_drop,
        LocationInputType.city => Icons.location_city,
      };

  String _hintText(CountryConfig country) {
    return '${country.examplePostalCode}, city name, or empty for GPS';
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(activeCountryProvider);
    final uiState = ref.watch(locationInputControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _hintText(country),
                  labelText: 'Location search field',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  prefixIcon: Icon(_prefixIcon(uiState.inputType), size: 20),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (uiState.isSearching)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear search input',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.my_location, size: 18),
                        tooltip: 'Use GPS location',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                          widget.onGpsSearch();
                        },
                      ),
                    ],
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _submit(),
              );
            },
          ),
        ),
        // City suggestions dropdown
        if (uiState.suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: uiState.suggestions.length,
              itemBuilder: (ctx, i) {
                final city = uiState.suggestions[i];
                final isSelected = uiState.selectedCity == city;
                return ListTile(
                  key: ValueKey('city-${city.lat}-${city.lng}-${city.name}'),
                  dense: true,
                  selected: isSelected,
                  leading: const Icon(Icons.place, size: 18),
                  title: Text(city.name,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: city.postcode != null
                      ? Text(city.postcode!,
                          style: const TextStyle(fontSize: 11))
                      : null,
                  onTap: () {
                    _controller.text = city.name;
                    ref
                        .read(locationInputControllerProvider.notifier)
                        .selectCity(city);
                    widget.onCitySearch(city);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
