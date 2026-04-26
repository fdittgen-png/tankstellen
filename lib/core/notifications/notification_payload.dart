import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Payload format embedded in price-alert notifications (#1012 phase 3).
///
/// The runner builds one of these from the cheapest match in a fired
/// alert and JSON-encodes it into the `payload` field of the local
/// notification. When the user taps the notification, the launch
/// listener decodes the payload and pushes the matching detail route.
///
/// Wire format is intentionally compact:
///
///   `{"k":"radius","s":"<stationId>","c":"de"}`
///
/// * `k` (kind) — discriminator so future notification kinds (e.g.
///   per-station price-drop, velocity alerts) can coexist on the same
///   tap dispatcher without colliding on schema.
/// * `s` (station id) — the country service's native id, passed
///   through unchanged so the resolver can hand it to the existing
///   `/station/:id` route.
/// * `c` (country) — 2-letter country code. Phase 3 emits `'de'` from
///   the BG isolate (the only StationService wired in the BG path
///   today is Tankerkönig). Stored mainly for forward compat: future
///   per-country routing or icon swaps can read it without breaking
///   the existing single-route resolver.
@immutable
class NotificationPayload {
  /// Discriminator for the radius-alert deep link (#1012 phase 3).
  /// Add new constants alongside it as future notification kinds get
  /// per-tap routes — the dispatcher's switch must stay exhaustive.
  static const String kindRadius = 'radius';

  final String kind;
  final String stationId;
  final String country;

  const NotificationPayload({
    required this.kind,
    required this.stationId,
    required this.country,
  });

  /// Encode to the on-the-wire JSON string the notification carries.
  /// Keep keys short (`k`/`s`/`c`) so the payload stays well under the
  /// per-notification size limit on Android.
  String encode() {
    return jsonEncode(<String, String>{
      'k': kind,
      's': stationId,
      'c': country,
    });
  }

  /// Parse a payload string from a notification tap.
  ///
  /// Returns `null` for any input that isn't a JSON object with the
  /// three required keys — the dispatcher must treat that as a no-op
  /// rather than a crash, because flutter_local_notifications can
  /// surface arbitrary payloads (e.g. legacy notifications fired
  /// before the schema existed).
  static NotificationPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final kind = decoded['k'];
      final stationId = decoded['s'];
      final country = decoded['c'];
      if (kind is! String || kind.isEmpty) return null;
      if (stationId is! String || stationId.isEmpty) return null;
      if (country is! String || country.isEmpty) return null;
      return NotificationPayload(
        kind: kind,
        stationId: stationId,
        country: country,
      );
    } catch (e, st) {
      debugPrint('NotificationPayload.tryDecode failed: $e\n$st');
      return null;
    }
  }

  /// Resolve to the router path the deep-link should push.
  ///
  /// Today every supported kind lands on `/station/:id`. Country is
  /// captured in [country] but not yet folded into the path because
  /// the existing detail route is country-agnostic. Adding a country
  /// segment later is a follow-up route change, not a payload change.
  String? toRouterPath() {
    switch (kind) {
      case kindRadius:
        return '/station/$stationId';
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPayload &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          stationId == other.stationId &&
          country == other.country;

  @override
  int get hashCode => Object.hash(kind, stationId, country);

  @override
  String toString() =>
      'NotificationPayload(kind: $kind, stationId: $stationId, country: $country)';
}
