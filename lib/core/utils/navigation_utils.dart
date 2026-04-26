import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
      debugPrint('Navigation geo: URI failed: $e\n$st');
    }

    // Fallback: Google Maps web URL — works universally via browser.
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// Open a route in Google Maps with multiple waypoints.
  ///
  /// [origin] — start point as "lat,lng" string.
  /// [destination] — end point as "lat,lng" string.
  /// [waypoints] — intermediate stops, each as "lat,lng".
  ///
  /// Stations should be sorted by their position along the route
  /// BEFORE calling this method to avoid zigzag routing.
  static Future<void> openRouteInMaps({
    required String origin,
    required String destination,
    List<String> waypoints = const [],
  }) async {
    var url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    if (waypoints.isNotEmpty) {
      url += '&waypoints=${waypoints.join('|')}';
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
