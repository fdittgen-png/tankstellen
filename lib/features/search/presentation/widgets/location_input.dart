import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/services/location_search_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../profile/providers/profile_provider.dart';

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
  List<ResolvedLocation> _suggestions = [];
  ResolvedLocation? _selectedCity;
  bool _isSearching = false;
  LocationInputType _inputType = LocationInputType.gps;

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

    setState(() {
      _inputType = type;
      _selectedCity = null;
      if (type != LocationInputType.city) _suggestions = [];
    });

    if (type == LocationInputType.city) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        _fetchSuggestions(value);
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final service = ref.read(locationSearchServiceProvider);
      final results = await service.searchCities(query);
      if (mounted) setState(() => _suggestions = results);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _submit() {
    final country = ref.read(activeCountryProvider);
    final text = _controller.text.trim();

    if (_selectedCity != null) {
      widget.onCitySearch(_selectedCity!);
      return;
    }

    switch (_inputType) {
      case LocationInputType.gps:
        widget.onGpsSearch();
      case LocationInputType.zip:
        if (RegExp(country.postalCodeRegex).hasMatch(text)) {
          widget.onZipSearch(text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enter a valid ${country.postalCodeLength}-digit '
                '${country.postalCodeLabel}',
              ),
            ),
          );
        }
      case LocationInputType.city:
        // If they typed a city but didn't select a suggestion, search anyway
        if (_suggestions.isNotEmpty) {
          widget.onCitySearch(_suggestions.first);
        }
    }
  }

  IconData get _prefixIcon => switch (_inputType) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Location search field',
          textField: true,
          child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: _hintText(country),
            prefixIcon: Icon(_prefixIcon),
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: 'Clear search input',
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Use GPS location',
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                    widget.onGpsSearch();
                  },
                ),
              ],
            ),
          ),
          onChanged: _onChanged,
          onSubmitted: (_) => _submit(),
        ),
        ),
        // City suggestions dropdown
        if (_suggestions.isNotEmpty)
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
              itemCount: _suggestions.length,
              itemBuilder: (ctx, i) {
                final city = _suggestions[i];
                final isSelected = _selectedCity == city;
                return ListTile(
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
                    setState(() {
                      _selectedCity = city;
                      _controller.text = city.name;
                      _suggestions = [];
                    });
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
