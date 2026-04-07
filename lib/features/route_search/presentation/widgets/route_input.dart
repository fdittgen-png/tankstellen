import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/services/location_search_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/route_info.dart';
import 'city_autocomplete_field.dart';

/// Input widget for route-based search: start, optional stops, destination.
///
/// All fields share the same Nominatim-backed city autocomplete via
/// [CityAutocompleteField], reusing the existing [LocationSearchService].
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
    safePostFrame(() {
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
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(
            context, '${l10n?.gpsError ?? "GPS error"}: $e');
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

  void _onCitySelected(ResolvedLocation city,
      TextEditingController controller, void Function(LatLng) setCoords) {
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
        final results =
            await searchService.searchCities(_startController.text);
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
          final results =
              await searchService.searchCities(_stopControllers[i].text);
          if (results.isNotEmpty) {
            _stopCoords[i] = LatLng(results.first.lat, results.first.lng);
          }
        }
      }

      if (_startCoords == null || _endCoords == null) {
        if (mounted) {
          SnackBarHelper.showError(
              context,
              AppLocalizations.of(context)?.couldNotResolve ??
                  'Could not resolve start or destination');
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
        SnackBarHelper.showError(context,
            '${AppLocalizations.of(context)?.errorUnknown ?? "Error"}: $e');
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
        CityAutocompleteField(
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
            child: CityAutocompleteField(
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
              label: Text(l10n?.addStop ?? 'Add stop',
                  style: theme.textTheme.bodySmall),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),

        // Destination field with autocomplete
        CityAutocompleteField(
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.route),
          label: Text(l10n?.searchAlongRoute ?? 'Search along route'),
        ),
      ],
    );
  }
}
