// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_origin.dart';
import '../../providers/route_input_provider.dart';
import 'route_input.dart';

/// The route endpoints re-read at submission time (#4432).
typedef RenewedEndpoints = ({
  LatLng? start,
  LatLng? end,
  bool originIsVehicle,
  bool destinationIsVehicle,
  DateTime? capturedAt,
});

/// The current-location half of [RouteInputWidgetState] (#4432): seeding
/// the start from GPS, writing a resolved fix into whichever endpoint
/// holds the current-location intent, and re-reading those endpoints
/// when a search is submitted.
mixin RouteInputCurrentPosition on ConsumerState<RouteInput> {
  /// The text field of [slot].
  @protected
  TextEditingController endpointController(RouteEndpointSlot slot);

  /// Seed the start from GPS. The #2872 degenerate-fix guard and the
  /// #2146 logging live in [captureCurrentPositionOrigin]; what stays
  /// here is the widget's own concern — whose text this may overwrite.
  @protected
  Future<void> useGpsForStart() async {
    final field = endpointController(RouteEndpointSlot.start);
    final before = field.text;
    final origin = await captureCurrentPositionOrigin(
      locationService: ref.read(locationServiceProvider),
      clock: ref.read(appClockProvider),
    );
    if (!mounted) return;
    // #4432 — a late fix must never overwrite an endpoint the user has
    // typed, picked or swapped while it was in flight. The auto-trigger
    // in initState races the driver's first keystroke by design.
    if (field.text != before) return;
    if (origin.coords == null) {
      // #1692 — a localized message, never a raw exception toString().
      SnackBarHelper.showError(context, AppLocalizations.of(context).gpsError);
      return;
    }
    adoptCurrentPosition(RouteEndpointSlot.start, origin);
  }

  /// Write [origin] into the [slot] field and the shared state.
  ///
  /// The label may never assert a freshness the coordinate does not
  /// have: a fix accepted as current reads "Current location"; anything
  /// else reads as the previous position it is, with its age. The stamp
  /// stored alongside is the fix's own measurement time, so the age is
  /// a measurement rather than a record of when some code ran. Either
  /// endpoint can hold the current-location intent (after a Swap), so
  /// the slot is explicit.
  @protected
  void adoptCurrentPosition(
    RouteEndpointSlot slot,
    ResolvedRouteOrigin origin,
  ) {
    final coords = origin.coords;
    if (coords == null) return;
    final l10n = AppLocalizations.of(context);
    ref.read(routeInputControllerProvider.notifier).setFromCurrentPosition(
          slot,
          coords,
          ref.read(appClockProvider).now().subtract(origin.age),
        );
    endpointController(slot).text = origin.isStale
        ? l10n.routeOriginStaleCurrentLocation(
            formatPositionAge(l10n, origin.age))
        : l10n.currentLocation;
  }

  /// Re-read every current-location endpoint of [input] at submission
  /// time; [start] / [end] are the coordinates resolved so far. Null when
  /// the widget went away meanwhile.
  ///
  /// "Position actuelle" must mean the position NOW: the stored fix is
  /// where the driver was when they tapped the button, which at motorway
  /// speed starts the corridor 50 km behind them. Whichever endpoint holds
  /// that intent — the destination does after a Swap — is re-read.
  /// Bounded by [resolveCurrentPositionOrigin], so a slow or refused fix
  /// degrades to the stored coordinate (relabelled with its age) rather
  /// than hanging the search behind the platform's acquisition.
  @protected
  Future<RenewedEndpoints?> renewCurrentLocationEndpoints(
    RouteInputState input, {
    required LatLng? start,
    required LatLng? end,
  }) async {
    var renewed = (
      start: start,
      end: end,
      originIsVehicle: false,
      destinationIsVehicle: false,
      capturedAt: null as DateTime?,
    );
    for (final slot in RouteEndpointSlot.values.reversed) {
      final stored = input.endpoint(slot);
      if (!stored.isCurrentLocation) continue;
      final origin = await resolveCurrentPositionOrigin(
        locationService: ref.read(locationServiceProvider),
        clock: ref.read(appClockProvider),
        stored: stored.coords,
        capturedAt: stored.capturedAt,
      );
      if (!mounted) return null;
      adoptCurrentPosition(slot, origin);
      final coords = origin.coords;
      if (coords == null) continue;
      final at = ref.read(routeInputControllerProvider).endpoint(slot);
      renewed = slot == RouteEndpointSlot.start
          ? (
              start: coords,
              end: renewed.end,
              originIsVehicle: true,
              destinationIsVehicle: renewed.destinationIsVehicle,
              capturedAt: at.capturedAt,
            )
          : (
              start: renewed.start,
              end: coords,
              originIsVehicle: renewed.originIsVehicle,
              destinationIsVehicle: true,
              capturedAt: at.capturedAt,
            );
    }
    return renewed;
  }
}
