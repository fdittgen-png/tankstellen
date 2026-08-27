// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;

/// Backend-neutral outcome of a location-permission check/request.
///
/// `permanentlyDenied` covers every terminal state the OS can no longer
/// recover from via a runtime dialog (permission_handler's
/// `permanentlyDenied` + `restricted`, geolocator's `deniedForever`) —
/// callers route those to a rationale → Settings fallback.
enum LocationPermissionOutcome { granted, denied, permanentlyDenied }

/// Facade over the two location-permission operations the app needs
/// (#3614): the while-in-use grant that gates GPS streams, and the
/// always/background grant that gates hands-free auto-record.
///
/// ## Why two plugin backends live behind one API
///
/// geolocator is the app's GPS dependency and owns the while-in-use
/// check/request pair ([ensureWhileInUse] — routed through the
/// `GeolocatorWrapper` seams its call site already fakes in tests).
/// But geolocator has **no** background/"always" request API at all, so
/// [requestAlways] (and the two-step foreground prompt that Android
/// requires before it, [requestWhileInUse], plus the Settings fallback)
/// keep their permission_handler backend — swapping them would change
/// the OS prompt sequence in a store-compliance-sensitive flow.
/// permission_handler otherwise remains the battery/camera plugin (see
/// the siblings in this folder).
///
/// Every backend is an injectable seam so widget/unit tests can fake
/// the OS without binding either plugin.
class LocationPermissions {
  const LocationPermissions({
    this._checkWhileInUseBackend,
    this._requestWhileInUseBackend,
    this._foregroundPromptBackend,
    this._alwaysPromptBackend,
    this._openSettingsBackend,
  });

  final Future<geo.LocationPermission> Function()? _checkWhileInUseBackend;
  final Future<geo.LocationPermission> Function()? _requestWhileInUseBackend;
  final Future<ph.PermissionStatus> Function()? _foregroundPromptBackend;
  final Future<ph.PermissionStatus> Function()? _alwaysPromptBackend;
  final Future<bool> Function()? _openSettingsBackend;

  /// Check the while-in-use grant and fire the OS prompt only when the
  /// state is a plain (recoverable) denial — the exact sequence the GPS
  /// stream opener has always run: `deniedForever` is never re-prompted.
  Future<LocationPermissionOutcome> ensureWhileInUse() async {
    var permission =
        await (_checkWhileInUseBackend ?? geo.Geolocator.checkPermission)();
    if (permission == geo.LocationPermission.denied) {
      permission = await (_requestWhileInUseBackend ??
          geo.Geolocator.requestPermission)();
    }
    return _fromGeolocator(permission);
  }

  /// Fire the OS foreground-location prompt unconditionally. Android
  /// requires this grant before it will even consider an
  /// `ACCESS_BACKGROUND_LOCATION` prompt (#1302), so [requestAlways]
  /// callers run this first.
  Future<LocationPermissionOutcome> requestWhileInUse() async =>
      _fromStatus(await (_foregroundPromptBackend ??
          ph.Permission.location.request)());

  /// Fire the OS background/"always" location prompt. On Android 11+ a
  /// permanent denial can never recover via runtime dialog — callers
  /// route [LocationPermissionOutcome.permanentlyDenied] to a rationale
  /// dialog with an open-Settings CTA.
  Future<LocationPermissionOutcome> requestAlways() async =>
      _fromStatus(await (_alwaysPromptBackend ??
          ph.Permission.locationAlways.request)());

  /// Open the OS app-settings page (the permanently-denied fallback).
  Future<void> openAppSettings() async {
    await (_openSettingsBackend ?? ph.openAppSettings)();
  }

  static LocationPermissionOutcome _fromGeolocator(
    geo.LocationPermission permission,
  ) {
    switch (permission) {
      case geo.LocationPermission.whileInUse:
      case geo.LocationPermission.always:
        return LocationPermissionOutcome.granted;
      case geo.LocationPermission.deniedForever:
        return LocationPermissionOutcome.permanentlyDenied;
      case geo.LocationPermission.denied:
      case geo.LocationPermission.unableToDetermine:
        return LocationPermissionOutcome.denied;
    }
  }

  static LocationPermissionOutcome _fromStatus(ph.PermissionStatus status) {
    if (status.isGranted) return LocationPermissionOutcome.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionOutcome.permanentlyDenied;
    }
    return LocationPermissionOutcome.denied;
  }
}
