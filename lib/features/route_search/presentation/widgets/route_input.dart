// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/services/location_search_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_origin.dart';
import '../../providers/route_input_provider.dart';
import 'city_autocomplete_field.dart';
import 'route_input_current_position.dart';

/// Input widget for route-based search: start, optional stops, destination.
///
/// All fields share the same Nominatim-backed city autocomplete via
/// [CityAutocompleteField], reusing the existing [LocationSearchService].
///
/// State lives in [routeInputControllerProvider]; only the non-shareable
/// [TextEditingController]s stay in this widget because they must follow
/// Flutter's lifecycle rules.
class RouteInput extends ConsumerStatefulWidget {
  /// #4432 — the waypoints, plus when a vehicle-position origin was
  /// MEASURED, so a later refresh can judge its age.
  final void Function(List<RouteWaypoint>, DateTime?) onSearch;

  const RouteInput({super.key, required this.onSearch});

  @override
  ConsumerState<RouteInput> createState() => RouteInputWidgetState();
}

/// Public State so the parent screen can drive [resolveAndSearch] via a
/// `GlobalKey` (#2131 — the criteria-screen FAB replaces the inline
/// route submit button, but the text controllers still live here).
class RouteInputWidgetState extends ConsumerState<RouteInput>
    with RouteInputCurrentPosition {
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
        unawaited(useGpsForStart());
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

  @override
  TextEditingController endpointController(RouteEndpointSlot slot) =>
      slot == RouteEndpointSlot.start ? _startController : _endController;

  void _addStop() {
    _stopControllers.add(TextEditingController());
    ref.read(routeInputControllerProvider.notifier).addStop();
  }

  void _removeStop(int index) {
    _stopControllers[index].dispose();
    _stopControllers.removeAt(index);
    ref.read(routeInputControllerProvider.notifier).removeStop(index);
  }

  /// #3927 — exchange start and destination, text and resolved
  /// coordinates together. "Same trip, other way round" was previously a
  /// full re-type of both fields. Text is written before the coordinates
  /// so the fields' own `onTextChanged` (a `TextField.onChanged`, which
  /// a programmatic controller write never fires) cannot null out the
  /// coordinates we just swapped in.
  ///
  /// #4432 — the endpoints swap as complete values (coordinate, intent,
  /// fix time). Swapping them as bare coordinates turned a
  /// current-location start into a fixed destination at a stale fix.
  void _swapEndpoints() {
    final startText = _startController.text;
    _startController.text = _endController.text;
    _endController.text = startText;
    ref.read(routeInputControllerProvider.notifier).swapEndpoints();
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

      // Geocode whatever the user typed but never picked from the list.
      // Only a CHANGED coordinate is written back: re-setting the start
      // to its own value would clear the #4432 current-location flag.
      final geoStart = await geocodeIfNeeded(
          searchService, startCoords, _startController.text);
      if (geoStart != startCoords) {
        notifier.setStartCoords(startCoords = geoStart);
      }
      final geoEnd =
          await geocodeIfNeeded(searchService, endCoords, _endController.text);
      if (geoEnd != endCoords) notifier.setEndCoords(endCoords = geoEnd);
      for (var i = 0; i < _stopControllers.length && i < stopCoords.length;
          i++) {
        final geo = await geocodeIfNeeded(
            searchService, stopCoords[i], _stopControllers[i].text);
        if (geo != stopCoords[i]) notifier.setStopCoord(i, stopCoords[i] = geo);
      }

      // #4432 — re-read whichever endpoint means "where I am".
      final renewed = await renewCurrentLocationEndpoints(routeState,
          start: startCoords, end: endCoords);
      if (renewed == null) return;

      final waypoints = buildRouteWaypoints(
        start: renewed.start,
        startLabel: _startController.text,
        end: renewed.end,
        endLabel: _endController.text,
        stops: stopCoords,
        stopLabels: [for (final c in _stopControllers) c.text],
        originIsVehiclePosition: renewed.originIsVehicle,
        destinationIsVehiclePosition: renewed.destinationIsVehicle,
      );
      // #2872 — a missing or degenerate anchor never reaches OSRM: it
      // would route from the Gulf of Guinea and centre the route map in
      // the Sahara. Ask for a manual entry instead.
      if (waypoints == null) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            AppLocalizations.of(context).couldNotResolve,
          );
        }
        return;
      }

      widget.onSearch(waypoints, renewed.capturedAt);
    } catch (e, st) {
      // #2146 — route to the exportable log; the snackbar is transient.
      logFailure(e, st, where: 'RouteInput.resolveAndSearch');
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
            onPressed: useGpsForStart,
            tooltip: l10n.useGps,
          ),
          onCitySelected: _onStartCitySelected,
          onTextChanged: () => ref
              .read(routeInputControllerProvider.notifier)
              .setStartCoords(null),
        ),
        // #3927 — swap start ⇄ destination, right-aligned between the two
        // endpoint fields so it reads as acting on both.
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: const ValueKey('route-swap-endpoints'),
            icon: const Icon(Icons.swap_vert, size: 20),
            tooltip: l10n.criteriaSwapEndpoints,
            visualDensity: VisualDensity.compact,
            onPressed: _swapEndpoints,
          ),
        ),

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
