import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/services/location_search_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/route_info.dart';

/// Input widget for route-based search: start, optional stops, destination.
///
/// All fields share the same Nominatim-backed city autocomplete via
/// [_CityAutocompleteField], reusing the existing [LocationSearchService].
class RouteInput extends ConsumerStatefulWidget {
  final void Function(List<RouteWaypoint> waypoints) onSearch;

  const RouteInput({super.key, required this.onSearch});

  @override
  ConsumerState<RouteInput> createState() => _RouteInputState();
}

class _RouteInputState extends ConsumerState<RouteInput> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _stopControllers = <TextEditingController>[];

  LatLng? _startCoords;
  LatLng? _endCoords;
  final _stopCoords = <LatLng?>[];

  bool _isSearching = false;
  bool _autoGpsTriggered = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill start with current position so user doesn't have to tap GPS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoGpsTriggered) {
        _autoGpsTriggered = true;
        _useGpsForStart();
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    for (final c in _stopControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useGpsForStart() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      _startCoords = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      _startController.text = l10n?.currentLocation ?? 'Current location';
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error: $e')),
        );
      }
    }
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
      _stopCoords.add(null);
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
      _stopCoords.removeAt(index);
    });
  }

  void _onCitySelected(ResolvedLocation city, TextEditingController controller, void Function(LatLng) setCoords) {
    controller.text = city.name;
    setCoords(LatLng(city.lat, city.lng));
    setState(() {});
  }

  Future<void> _resolveAndSearch() async {
    if (_isSearching) return;
    setState(() => _isSearching = true);

    try {
      final searchService = ref.read(locationSearchServiceProvider);

      // Resolve start if needed
      if (_startCoords == null && _startController.text.isNotEmpty) {
        final results = await searchService.searchCities(_startController.text);
        if (results.isNotEmpty) {
          _startCoords = LatLng(results.first.lat, results.first.lng);
        }
      }

      // Resolve end if needed
      if (_endCoords == null && _endController.text.isNotEmpty) {
        final results = await searchService.searchCities(_endController.text);
        if (results.isNotEmpty) {
          _endCoords = LatLng(results.first.lat, results.first.lng);
        }
      }

      // Resolve stops
      for (var i = 0; i < _stopControllers.length; i++) {
        if (_stopCoords[i] == null && _stopControllers[i].text.isNotEmpty) {
          final results = await searchService.searchCities(_stopControllers[i].text);
          if (results.isNotEmpty) {
            _stopCoords[i] = LatLng(results.first.lat, results.first.lng);
          }
        }
      }

      if (_startCoords == null || _endCoords == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.couldNotResolve ?? 'Could not resolve start or destination')),
          );
        }
        return;
      }

      final waypoints = <RouteWaypoint>[
        RouteWaypoint(
          lat: _startCoords!.latitude,
          lng: _startCoords!.longitude,
          label: _startController.text,
        ),
        for (var i = 0; i < _stopCoords.length; i++)
          if (_stopCoords[i] != null)
            RouteWaypoint(
              lat: _stopCoords[i]!.latitude,
              lng: _stopCoords[i]!.longitude,
              label: _stopControllers[i].text,
            ),
        RouteWaypoint(
          lat: _endCoords!.latitude,
          lng: _endCoords!.longitude,
          label: _endController.text,
        ),
      ];

      widget.onSearch(waypoints);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final searchService = ref.watch(locationSearchServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Start field with autocomplete
        _CityAutocompleteField(
          controller: _startController,
          searchService: searchService,
          label: l10n?.start ?? 'Start',
          hint: l10n?.cityAddressOrGps ?? 'City, address, or GPS',
          prefixIcon: Icons.trip_origin,
          suffixWidget: IconButton(
            icon: const Icon(Icons.my_location, size: 18),
            onPressed: _useGpsForStart,
            tooltip: l10n?.useGps ?? 'Use GPS',
          ),
          onCitySelected: (city) => _onCitySelected(
            city, _startController, (c) => _startCoords = c,
          ),
          onTextChanged: () => _startCoords = null,
        ),
        const SizedBox(height: 6),

        // Optional stops with autocomplete
        for (var i = 0; i < _stopControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _CityAutocompleteField(
              controller: _stopControllers[i],
              searchService: searchService,
              label: '${l10n?.stop ?? "Stop"} ${i + 1}',
              hint: l10n?.cityOrAddress ?? 'City or address',
              prefixIcon: Icons.more_vert,
              suffixWidget: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _removeStop(i),
              ),
              onCitySelected: (city) => _onCitySelected(
                city, _stopControllers[i], (c) => _stopCoords[i] = c,
              ),
              onTextChanged: () => _stopCoords[i] = null,
            ),
          ),

        // Add stop button
        if (_stopControllers.length < 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n?.addStop ?? 'Add stop', style: theme.textTheme.bodySmall),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),

        // Destination field with autocomplete
        _CityAutocompleteField(
          controller: _endController,
          searchService: searchService,
          label: l10n?.destination ?? 'Destination',
          hint: l10n?.cityOrAddress ?? 'City or address',
          prefixIcon: Icons.place,
          onCitySelected: (city) => _onCitySelected(
            city, _endController, (c) => _endCoords = c,
          ),
          onTextChanged: () => _endCoords = null,
        ),
        const SizedBox(height: 8),

        // Search button
        FilledButton.icon(
          onPressed: (_startController.text.isNotEmpty &&
                  _endController.text.isNotEmpty &&
                  !_isSearching)
              ? _resolveAndSearch
              : null,
          icon: _isSearching
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.route),
          label: Text(l10n?.searchAlongRoute ?? 'Search along route'),
        ),
      ],
    );
  }
}

/// Reusable text field with debounced city autocomplete suggestions.
///
/// Queries [LocationSearchService.searchCities] as the user types (1s debounce)
/// and shows a dropdown of matching cities. Selecting a city fills the field
/// and calls [onCitySelected] with the resolved coordinates.
class _CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final LocationSearchService searchService;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final void Function(ResolvedLocation city) onCitySelected;
  final VoidCallback onTextChanged;

  const _CityAutocompleteField({
    required this.controller,
    required this.searchService,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixWidget,
    required this.onCitySelected,
    required this.onTextChanged,
  });

  @override
  State<_CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<_CityAutocompleteField> {
  Timer? _debounce;
  List<ResolvedLocation> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged(String value) {
    widget.onTextChanged();
    _debounce?.cancel();

    if (value.trim().length < 2) {
      _removeOverlay();
      return;
    }

    // Only search if it looks like a city name (not digits = postal code)
    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final results = await widget.searchService.searchCities(value.trim());
        if (mounted) {
          _suggestions = results.take(5).toList();
          _showSuggestions = _suggestions.isNotEmpty;
          _isLoading = false;
          if (_showSuggestions && _focusNode.hasFocus) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      } catch (e) {
        debugPrint('Route autocomplete failed: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _selectCity(ResolvedLocation city) {
    widget.controller.text = city.name;
    widget.onCitySelected(city);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final city = _suggestions[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.place, size: 16),
                    title: Text(city.name, style: const TextStyle(fontSize: 13)),
                    onTap: () => _selectCity(city),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.prefixIcon, size: 18),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.suffixWidget,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: _onTextChanged,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}
