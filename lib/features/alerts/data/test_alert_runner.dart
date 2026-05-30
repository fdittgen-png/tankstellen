// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/notifications/notification_payload.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/entities/radius_alert.dart';
import '../domain/radius_alert_evaluator.dart';

/// Developer / Debug-mode test hook that exercises the radius-alert
/// pipeline end-to-end against an in-range, below-target match (#2248).
///
/// The production [RadiusAlertRunner] is wired to Hive-backed
/// [RadiusAlertStore] / [RadiusAlertDedup] collaborators and the live
/// per-country StationService, so driving it from a UI button would touch
/// the user's persisted watchlist and dedup state. This runner instead
/// fabricates one [RadiusAlert] plus one matching [StationPriceSample]
/// entirely in memory and feeds them through the SAME
/// [RadiusAlertEvaluator] and the SAME [NotificationService] that the real
/// pipeline uses — so a developer can verify that evaluation → match
/// selection → notification delivery all work, including the
/// POST_NOTIFICATIONS permission grant and the Android channel, without
/// mutating any persisted alert.
///
/// #2408 — the matched sample carries a REAL station id (resolved by the
/// caller from the current search results) so the encoded
/// [NotificationPayload.stationId] deep-links to a station that
/// [stationDetailProvider] can actually resolve. Tapping the notification
/// then opens a station-detail screen that LOADS instead of hanging in the
/// shimmer skeleton forever against a non-resolving `debug-test-station`.
/// The synthetic sample remains only as a last resort when the caller has
/// no real station to offer — and the caller is expected to gate on that
/// (showing "search first") rather than firing a stuck deep-link.
///
/// Returns the number of notifications the run produced (0 when the OS
/// permission is denied, otherwise 1).
class TestAlertRunner {
  final NotificationService notifier;
  final RadiusAlertEvaluator evaluator;

  TestAlertRunner({
    required this.notifier,
    RadiusAlertEvaluator? evaluator,
  }) : evaluator = evaluator ?? const RadiusAlertEvaluator();

  /// Stable notification id for the synthetic test alert so repeated
  /// runs update the existing banner instead of stacking new ones.
  static int get notificationId => 'radius:debug-test-alert'.hashCode;

  /// Synthetic alert id used by the test run. Kept stable so the
  /// notification id is deterministic.
  static const String alertId = 'debug-test-alert';

  /// Last-resort synthetic sample used only when the caller has no real
  /// station to offer. Its `debug-test-station` id does NOT resolve in
  /// [stationDetailProvider], so tapping the resulting notification lands
  /// on an infinite shimmer (#2408). Callers should resolve a REAL station
  /// (see [run]'s [station] argument) and only fall back here when there
  /// is genuinely no station available — in which case the UI is expected
  /// to gate the run rather than fire this stuck deep-link.
  static const StationPriceSample _syntheticSample = StationPriceSample(
    stationId: 'debug-test-station',
    name: 'Debug station',
    lat: 0,
    lng: 0,
    fuelType: 'diesel',
    pricePerLiter: 1.40,
  );

  /// Build the in-memory alert + sample, evaluate them, and fire the
  /// notification when the station matches (it always does by
  /// construction). [title] / [body] are the localised copy passed in
  /// from the UI so this layer holds no user-facing strings.
  ///
  /// [station] is the REAL station sample to fire against (#2408): the
  /// alert is centred on it with a threshold one cent above its price so
  /// the evaluator yields exactly that station as the single match, and
  /// the encoded [NotificationPayload.stationId] is the station's real id.
  /// When `null` the runner falls back to the synthetic
  /// `debug-test-station` sample (a non-resolving deep link), so the UI
  /// must only pass `null` when it has already decided that firing a
  /// non-resolving alert is acceptable. [country] (lowercase ISO code) is
  /// stamped into the payload for forward-compat routing; it defaults to
  /// `'de'`.
  ///
  /// First requests the OS notification permission (a no-op when already
  /// granted) so an Android 13+ device that has never granted
  /// POST_NOTIFICATIONS prompts the user, mirroring the production path
  /// that requests it from a foreground user-intent moment. Returns the
  /// number of notifications delivered.
  Future<int> run({
    required String title,
    required String body,
    StationPriceSample? station,
    String country = 'de',
    DateTime? now,
  }) async {
    final granted = await notifier.requestPermission();
    if (!granted) return 0;

    final sample = station ?? _syntheticSample;
    final at = now ?? DateTime.now();
    // Centre the synthetic alert on the sample with a threshold one cent
    // above its price and a generous radius, so the evaluator yields
    // exactly this station as the single match — same colocation +
    // same-fuel + at-or-below-price rules the production runner relies on.
    final alert = RadiusAlert(
      id: alertId,
      fuelType: sample.fuelType,
      threshold: sample.pricePerLiter + 0.01,
      centerLat: sample.lat,
      centerLng: sample.lng,
      radiusKm: 50,
      label: 'Test alert',
      createdAt: at,
    );

    final matches = evaluator.matches(alert, [sample]).toList();
    if (matches.isEmpty) return 0;

    final payload = NotificationPayload(
      kind: NotificationPayload.kindRadius,
      stationId: matches.first.stationId,
      country: country,
    ).encode();
    await notifier.showPriceAlert(
      id: notificationId,
      title: title,
      body: body,
      payload: payload,
    );
    return 1;
  }
}
