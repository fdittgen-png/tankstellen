// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/logging/error_logger.dart';
import '../services/station_offer.dart';

/// The platform launch, as a seam (#4348) — so a behavioural test can
/// prove WHICH destination a station action hands the OS, and that a
/// reference-price location hands it none.
typedef MapsLauncher = Future<bool> Function(Uri uri, LaunchMode mode);

Future<bool> _platformLaunch(Uri uri, LaunchMode mode) =>
    launchUrl(uri, mode: mode);

/// Centralized navigation utility for opening stations in external maps apps.
///
/// Uses a two-step strategy:
/// 1. Try `geo:` URI scheme — lets the OS present a picker if multiple
///    navigation apps are installed (Google Maps, Waze, OsmAnd, etc.)
/// 2. Falls back to Google Maps web URL if `geo:` is not handled.
///
/// This avoids duplicating the same navigation logic across 4+ screens.
class NavigationUtils {
  NavigationUtils._();

  /// Every launch goes through this. Production leaves it alone; a test
  /// swaps in a recorder and restores [resetLauncher] in `tearDown`.
  @visibleForTesting
  static MapsLauncher launcher = _platformLaunch;

  @visibleForTesting
  static void resetLauncher() => launcher = _platformLaunch;

  /// Open a SEARCH RESULT in the maps app — gated on what it is (#4348).
  ///
  /// The one entry point every station surface uses. A reference price
  /// stood in at a city centroid or a prefecture seat (LU, GR) is not a
  /// place anyone can buy fuel, so it launches nothing and answers false;
  /// the surface should not have offered the action in the first place
  /// ([StationOffer.canNavigate]), and this is the backstop if it did.
  static Future<bool> openStation({
    required String stationId,
    required double lat,
    required double lng,
    String? label,
  }) async {
    final offer =
        StationOffer.forStation(stationId: stationId, lat: lat, lng: lng);
    if (!offer.canNavigate) return false;
    await openInMaps(lat, lng, label: label);
    return true;
  }

  /// Open a single location in the user's preferred maps/navigation app.
  ///
  /// [lat], [lng] — coordinates of the destination.
  /// [label] — optional display name shown in the maps app (e.g., station brand).
  static Future<void> openInMaps(double lat, double lng, {String? label}) async {
    // Build geo: URI — the standard Android/iOS intent for map locations.
    // The (label) suffix is a display name hint, URL-encoded for safety.
    final query = label != null
        ? '?q=$lat,$lng(${Uri.encodeComponent(label)})'
        : '?q=$lat,$lng';
    final geoUri = Uri.parse('geo:$lat,$lng$query');

    try {
      final launched = await launcher(geoUri, LaunchMode.externalApplication);
      if (launched) return;
    } on Exception catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Navigation geo: URI failed'}));
    }

    // Fallback: Google Maps web URL — works universally via browser.
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launcher(webUri, LaunchMode.externalApplication);
  }

  /// Open a route through multiple stations in the user's preferred
  /// maps/navigation app.
  ///
  /// [origin] — start point as "lat,lng" string.
  /// [destination] — end point as "lat,lng" string.
  /// [waypoints] — intermediate stops, each as "lat,lng".
  ///
  /// Stations should be sorted by their position along the route
  /// BEFORE calling this method to avoid zigzag routing.
  ///
  /// Like [openInMaps], this prefers the OS's DEFAULT maps app via a `geo:`
  /// intent to the destination (Organic Maps, OsmAnd, Waze, Google Maps…),
  /// instead of forcing Google Maps. Multi-stop routing has no cross-app URI
  /// scheme, so the intermediate [waypoints] are only carried by the Google
  /// Maps web fallback below — used when no installed app handles `geo:`
  /// (e.g. a GMS-free / F-Droid device with no maps app). See #3474.
  static Future<void> openRouteInMaps({
    required String origin,
    required String destination,
    List<String> waypoints = const [],
  }) async {
    final geoUri = _geoUriForLatLng(destination);
    if (geoUri != null) {
      try {
        final launched =
            await launcher(geoUri, LaunchMode.externalApplication);
        if (launched) return;
      } on Exception catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'Route navigation geo: URI failed'}));
      }
    }

    // Fallback: Google Maps web with the full multi-stop route.
    var url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    if (waypoints.isNotEmpty) {
      url += '&waypoints=${waypoints.join('|')}';
    }

    await launcher(Uri.parse(url), LaunchMode.externalApplication);
  }

  /// Build a `geo:lat,lng?q=lat,lng` URI from a `"lat,lng"` string, or `null`
  /// if it is not a valid coordinate pair (so the caller can fall back).
  static Uri? _geoUriForLatLng(String latLng) {
    final parts = latLng.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  }
}
