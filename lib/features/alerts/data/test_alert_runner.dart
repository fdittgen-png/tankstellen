// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/notifications/notification_payload.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/entities/radius_alert.dart';
import '../domain/radius_alert_evaluator.dart';

/// Developer / Debug-mode test hook that exercises the radius-alert
/// pipeline end-to-end against a synthetic, in-range, below-target match
/// (#2248).
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

  /// Build the in-memory alert + sample, evaluate them, and fire the
  /// notification when the synthetic station matches (it always does by
  /// construction). [title] / [body] are the localised copy passed in
  /// from the UI so this layer holds no user-facing strings.
  ///
  /// First requests the OS notification permission (a no-op when already
  /// granted) so an Android 13+ device that has never granted
  /// POST_NOTIFICATIONS prompts the user, mirroring the production path
  /// that requests it from a foreground user-intent moment. Returns the
  /// number of notifications delivered.
  Future<int> run({
    required String title,
    required String body,
    DateTime? now,
  }) async {
    final granted = await notifier.requestPermission();
    if (!granted) return 0;

    final at = now ?? DateTime.now();
    final alert = RadiusAlert(
      id: alertId,
      fuelType: 'diesel',
      threshold: 1.50,
      centerLat: 0,
      centerLng: 0,
      radiusKm: 10,
      label: 'Test alert',
      createdAt: at,
    );
    // A single in-range, below-threshold sample so the evaluator yields
    // exactly one match — same colocation + same-fuel + at-or-below-price
    // rules the production runner relies on.
    const sample = StationPriceSample(
      stationId: 'debug-test-station',
      name: 'Debug station',
      lat: 0,
      lng: 0,
      fuelType: 'diesel',
      pricePerLiter: 1.40,
    );

    final matches = evaluator.matches(alert, [sample]).toList();
    if (matches.isEmpty) return 0;

    final payload = NotificationPayload(
      kind: NotificationPayload.kindRadius,
      stationId: matches.first.stationId,
      country: 'de',
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
