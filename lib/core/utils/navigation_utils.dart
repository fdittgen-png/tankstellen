// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:url_launcher/url_launcher.dart';
import '../../core/logging/error_logger.dart';

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
      final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } on Exception catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Navigation geo: URI failed'}));
    }

    // Fallback: Google Maps web URL — works universally via browser.
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
            await launchUrl(geoUri, mode: LaunchMode.externalApplication);
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

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
