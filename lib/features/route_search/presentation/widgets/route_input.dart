// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/services/location_search_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/utils/geo_utils.dart';
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
  ConsumerState<RouteInput> createState() => RouteInputWidgetState();
}

/// Public State so the parent screen can drive [resolveAndSearch] via a
/// `GlobalKey` (#2131 — the criteria-screen FAB replaces the inline
/// route submit button, but the text controllers still live here).
class RouteInputWidgetState extends ConsumerState<RouteInput> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _stopControllers = <TextEditingController>[];

  bool _autoGpsTriggered = false;

  @override
  void initState() {
    super.initState();
    // Mirror text-presence into the shared provider so the criteria-
    // screen FAB can mirror the (old) inline submit button's enabled
    // state without owning these controllers.
    _startController.addListener(_syncStartText);
    _endController.addListener(_syncEndText);
    // Reset shared provider state for a fresh widget instance.
    safePostFrame(() {
      if (!mounted) return;
      ref.read(routeInputControllerProvider.notifier).reset();
      if (!_autoGpsTriggered) {
        _autoGpsTriggered = true;
        unawaited(_useGpsForStart());
      }
    });
  }

  void _syncStartText() {
    if (!mounted) return;
    ref
        .read(routeInputControllerProvider.notifier)
        .setHasStartText(_startController.text.isNotEmpty);
  }

  void _syncEndText() {
    if (!mounted) return;
    ref
        .read(routeInputControllerProvider.notifier)
        .setHasEndText(_endController.text.isNotEmpty);
  }

  @override
  void dispose() {
    _startController.removeListener(_syncStartText);
    _endController.removeListener(_syncEndText);
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
      // #2872 — defence-in-depth behind getCurrentPosition's own guard:
      // never seed the route start from a degenerate fix. A (0,0)/(lat,0)
      // origin makes OSRM route from the Gulf of Guinea and centres the
      // route map in the Sahara. Fall through to the manual-entry / GPS
      // error path instead of calling setStartCoords.
      if (!isUsableCoord(position.latitude, position.longitude)) {
        throw const LocationException(
          message: 'Degenerate GPS fix; ask the user for a manual start.',
        );
      }
      final coords = LatLng(position.latitude, position.longitude);
      ref.read(routeInputControllerProvider.notifier).setStartCoords(coords);
      final l10n = AppLocalizations.of(context);
      _startController.text = l10n.currentLocation;
    } catch (e, st) {
      // #2146 — route to the exportable log; the snackbar is transient.
      unawaited(
        errorLogger.log(
          ErrorLayer.ui,
          e,
          st,
          context: const {'where': 'RouteInput._useGpsForStart'},
        ),
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(context, '${l10n.gpsError}: $e');
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

  /// Resolve any unresolved city text into coordinates and invoke
  /// [RouteInput.onSearch] with the waypoints. Public so the shell-level
  /// FAB can trigger it via [RouteInputWidgetState] (#2131).
  Future<void> resolveAndSearch() async {
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
        final results = await searchService.searchCities(_startController.text);
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
          final results = await searchService.searchCities(
            _stopControllers[i].text,
          );
          if (results.isNotEmpty) {
            stopCoords[i] = LatLng(results.first.lat, results.first.lng);
            notifier.setStopCoord(i, stopCoords[i]);
          }
        }
      }

      // #2872 — a required endpoint that is missing OR degenerate ((0,0),
      // a one-axis-unacquired (lat,0), or out-of-range) must not reach
      // OSRM: it would route from the Gulf of Guinea and centre the route
      // map in the Sahara. Treat an unusable start/destination exactly
      // like an unresolved one and ask the user for a manual entry.
      if (startCoords == null ||
          endCoords == null ||
          !isUsableCoord(startCoords.latitude, startCoords.longitude) ||
          !isUsableCoord(endCoords.latitude, endCoords.longitude)) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            AppLocalizations.of(context).couldNotResolve,
          );
        }
        return;
      }

      final waypoints = <RouteWaypoint>[
        RouteWaypoint(
          lat: startCoords.latitude,
          lng: startCoords.longitude,
          label: _startController.text,
        ),
        // #2872 — silently drop a degenerate optional stop (a Nominatim
        // geocode that fell back to (lat,0) via the `?? 0` default) rather
        // than letting it bend the route to null island. Start/end are the
        // anchors and are already validated above.
        for (var i = 0; i < stopCoords.length; i++)
          if (stopCoords[i] != null &&
              isUsableCoord(stopCoords[i]!.latitude, stopCoords[i]!.longitude))
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
    } catch (e, st) {
      // #2146 — route to the exportable log; the snackbar is transient.
      unawaited(
        errorLogger.log(
          ErrorLayer.ui,
          e,
          st,
          context: const {'where': 'RouteInput.resolveAndSearch'},
        ),
      );
      if (mounted) {
        SnackBarHelper.showError(
          context,
          '${AppLocalizations.of(context).errorUnknown}: $e',
        );
      }
    } finally {
      // #2139 — always reset isSearching, even if the widget unmounted
      // mid-await. The captured notifier reference stays valid for the
      // provider's lifetime (try/catch covers the rare case where the
      // provider has been auto-disposed already).
      try {
        notifier.setSearching(false);
      } catch (_) {
        // ignore: silent_catch — Provider disposed — state is gone anyway.
      }
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
          label: l10n.start,
          hint: l10n.cityAddressOrGps,
          prefixIcon: Icons.trip_origin,
          suffixWidget: IconButton(
            icon: const Icon(Icons.my_location, size: 18),
            onPressed: _useGpsForStart,
            tooltip: l10n.useGps,
          ),
          onCitySelected: _onStartCitySelected,
          onTextChanged: () => ref
              .read(routeInputControllerProvider.notifier)
              .setStartCoords(null),
        ),
        const SizedBox(height: 6),

        // Optional stops with autocomplete
        for (var i = 0; i < _stopControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: CityAutocompleteField(
              controller: _stopControllers[i],
              searchService: searchService,
              label: '${l10n.stop} ${i + 1}',
              hint: l10n.cityOrAddress,
              prefixIcon: Icons.more_vert,
              suffixWidget: IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: l10n.remove,
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
              label: Text(l10n.addStop, style: theme.textTheme.bodySmall),
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
          label: l10n.destination,
          hint: l10n.cityOrAddress,
          prefixIcon: Icons.place,
          onCitySelected: _onEndCitySelected,
          onTextChanged: () => ref
              .read(routeInputControllerProvider.notifier)
              .setEndCoords(null),
        ),
        // #2131 — the inline "Search along route" submit button moved
        // to the central FAB. RouteInput now owns inputs only;
        // [RouteInputWidgetState.resolveAndSearch] is driven from the
        // criteria-screen FAB via a `GlobalKey`.
      ],
    );
  }
}
