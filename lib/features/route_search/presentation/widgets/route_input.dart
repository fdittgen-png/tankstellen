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
import '../../providers/route_input_provider.dart';
import 'city_autocomplete_field.dart';

/// Input widget for route-based search: start, optional stops, destination.
///
/// All fields share the same Nominatim-backed city autocomplete via
/// [CityAutocompleteField], reusing the existing [LocationSearchService].
///
/// State lives in [routeInputControllerProvider]; only the non-shareable
/// [TextEditingController]s stay in this widget because they must follow
/// Flutter's lifecycle rules.
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

  bool _autoGpsTriggered = false;

  @override
  void initState() {
    super.initState();
    // Reset shared provider state for a fresh widget instance.
    safePostFrame(() {
      if (!mounted) return;
      ref.read(routeInputControllerProvider.notifier).reset();
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
      if (!mounted) return;
      final coords = LatLng(position.latitude, position.longitude);
      ref.read(routeInputControllerProvider.notifier).setStartCoords(coords);
      final l10n = AppLocalizations.of(context);
      _startController.text = l10n?.currentLocation ?? 'Current location';
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(
            context, '${l10n?.gpsError ?? "GPS error"}: $e');
      }
    }
  }

  void _addStop() {
    _stopControllers.add(TextEditingController());
    ref.read(routeInputControllerProvider.notifier).addStop();
  }

  void _removeStop(int index) {
    _stopControllers[index].dispose();
    _stopControllers.removeAt(index);
    ref.read(routeInputControllerProvider.notifier).removeStop(index);
  }

  void _onStartCitySelected(ResolvedLocation city) {
    _startController.text = city.name;
    ref
        .read(routeInputControllerProvider.notifier)
        .setStartCoords(LatLng(city.lat, city.lng));
  }

  void _onEndCitySelected(ResolvedLocation city) {
    _endController.text = city.name;
    ref
        .read(routeInputControllerProvider.notifier)
        .setEndCoords(LatLng(city.lat, city.lng));
  }

  void _onStopCitySelected(int i, ResolvedLocation city) {
    _stopControllers[i].text = city.name;
    ref
        .read(routeInputControllerProvider.notifier)
        .setStopCoord(i, LatLng(city.lat, city.lng));
  }

  Future<void> _resolveAndSearch() async {
    final routeState = ref.read(routeInputControllerProvider);
    if (routeState.isSearching) return;
    final notifier = ref.read(routeInputControllerProvider.notifier);
    notifier.setSearching(true);

    try {
      final searchService = ref.read(locationSearchServiceProvider);

      var startCoords = routeState.startCoords;
      var endCoords = routeState.endCoords;
      final stopCoords = List<LatLng?>.from(routeState.stopCoords);

      // Resolve start if needed
      if (startCoords == null && _startController.text.isNotEmpty) {
        final results =
            await searchService.searchCities(_startController.text);
        if (results.isNotEmpty) {
          startCoords = LatLng(results.first.lat, results.first.lng);
          notifier.setStartCoords(startCoords);
        }
      }

      // Resolve end if needed
      if (endCoords == null && _endController.text.isNotEmpty) {
        final results = await searchService.searchCities(_endController.text);
        if (results.isNotEmpty) {
          endCoords = LatLng(results.first.lat, results.first.lng);
          notifier.setEndCoords(endCoords);
        }
      }

      // Resolve stops
      for (var i = 0; i < _stopControllers.length; i++) {
        if (i < stopCoords.length &&
            stopCoords[i] == null &&
            _stopControllers[i].text.isNotEmpty) {
          final results =
              await searchService.searchCities(_stopControllers[i].text);
          if (results.isNotEmpty) {
            stopCoords[i] = LatLng(results.first.lat, results.first.lng);
            notifier.setStopCoord(i, stopCoords[i]);
          }
        }
      }

      if (startCoords == null || endCoords == null) {
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
          lat: startCoords.latitude,
          lng: startCoords.longitude,
          label: _startController.text,
        ),
        for (var i = 0; i < stopCoords.length; i++)
          if (stopCoords[i] != null)
            RouteWaypoint(
              lat: stopCoords[i]!.latitude,
              lng: stopCoords[i]!.longitude,
              label: _stopControllers[i].text,
            ),
        RouteWaypoint(
          lat: endCoords.latitude,
          lng: endCoords.longitude,
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
      if (mounted) notifier.setSearching(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final searchService = ref.watch(locationSearchServiceProvider);
    final routeState = ref.watch(routeInputControllerProvider);

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
          onCitySelected: _onStartCitySelected,
          onTextChanged: () =>
              ref.read(routeInputControllerProvider.notifier).setStartCoords(null),
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
                tooltip: l10n?.remove ?? 'Remove',
                onPressed: () => _removeStop(i),
              ),
              onCitySelected: (city) => _onStopCitySelected(i, city),
              onTextChanged: () => ref
                  .read(routeInputControllerProvider.notifier)
                  .setStopCoord(i, null),
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
          onCitySelected: _onEndCitySelected,
          onTextChanged: () =>
              ref.read(routeInputControllerProvider.notifier).setEndCoords(null),
        ),
        const SizedBox(height: 8),

        // Search button — listens to controllers so it enables as the user
        // types, without needing setState.
        ListenableBuilder(
          listenable: Listenable.merge([_startController, _endController]),
          builder: (context, _) {
            final canSearch = _startController.text.isNotEmpty &&
                _endController.text.isNotEmpty &&
                !routeState.isSearching;
            return FilledButton.icon(
              onPressed: canSearch ? _resolveAndSearch : null,
              icon: routeState.isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.route),
              label: Text(l10n?.searchAlongRoute ?? 'Search along route'),
            );
          },
        ),
      ],
    );
  }
}
