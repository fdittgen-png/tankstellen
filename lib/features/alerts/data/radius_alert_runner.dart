import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_service.dart';
import '../domain/entities/radius_alert.dart';
import '../domain/radius_alert_evaluator.dart';
import 'radius_alert_dedup.dart';
import 'radius_alert_store.dart';

/// Source of price samples for one [RadiusAlert]. The background
/// isolate implementation queries the country's StationService (see
/// [background_service.dart]); unit tests inject a precomputed list
/// so they can drive every code path without hitting the network or
/// the Riverpod graph.
typedef SamplesForAlert = Future<List<StationPriceSample>> Function(
    RadiusAlert alert);

/// Glue between the background price refresh cycle and the radius
/// alert evaluator (#578 phase 3).
///
/// The background isolate calls [run] once per cycle. The runner:
///   1. loads every active [RadiusAlert] from [RadiusAlertStore],
///   2. asks the [samplesFor] callback for stations currently in
///      range of each alert (per-country StationService in the real
///      path, fake fixtures in tests),
///   3. uses [RadiusAlertEvaluator] to pick the matching samples,
///   4. runs each (alert, station) match past [RadiusAlertDedup]
///      (12 h default window + further-drop override), and
///   5. fires one local notification per surviving match through the
///      injected [NotificationService].
///
/// All collaborators are injected so the service-level integration
/// test can seed an alert + a fake samples provider and assert that
/// the notifier was called exactly once.
class RadiusAlertRunner {
  final RadiusAlertStore store;
  final RadiusAlertDedup dedup;
  final NotificationService notifier;
  final RadiusAlertEvaluator evaluator;

  /// User-facing notification copy. Background isolates can't reach
  /// ARB bundles (no BuildContext) so the caller passes in a pure
  /// function that formats against the event payload. Keep the
  /// signature stable so the main-isolate preview and the BG runner
  /// emit identical strings.
  final RadiusAlertCopy Function(RadiusAlertNotification event)
      copyBuilder;

  RadiusAlertRunner({
    required this.store,
    required this.dedup,
    required this.notifier,
    required this.copyBuilder,
    RadiusAlertEvaluator? evaluator,
  }) : evaluator = evaluator ?? const RadiusAlertEvaluator();

  /// Execute the whole pipeline. Returns the list of fired events
  /// (may be empty) so callers can log / assert / update a widget
  /// status line without re-walking state.
  ///
  /// Safe to call with no active alerts: the runner returns an empty
  /// list and never touches the notifier.
  Future<List<RadiusAlertNotification>> run({
    required DateTime now,
    required SamplesForAlert samplesFor,
  }) async {
    final alerts = await store.list();
    final active = alerts.where((a) => a.enabled).toList();
    if (active.isEmpty) return const [];

    final fired = <RadiusAlertNotification>[];
    for (final alert in active) {
      try {
        final samples = await samplesFor(alert);
        if (samples.isEmpty) continue;
        final matches = evaluator.matches(alert, samples).toList();
        if (matches.isEmpty) continue;
        for (final match in matches) {
          final allow = await dedup.shouldNotify(
            alertId: alert.id,
            stationId: match.stationId,
            currentPrice: match.pricePerLiter,
            now: now,
          );
          if (!allow) continue;

          final event = RadiusAlertNotification(
            alert: alert,
            stationId: match.stationId,
            price: match.pricePerLiter,
          );
          final copy = copyBuilder(event);
          await notifier.showPriceAlert(
            id: _notificationId(alert.id, match.stationId),
            title: copy.title,
            body: copy.body,
          );
          await dedup.recordFire(
            alertId: alert.id,
            stationId: match.stationId,
            price: match.pricePerLiter,
            now: now,
          );
          fired.add(event);
        }
      } catch (e) {
        // One bad alert (e.g. country API down) must not block the
        // rest — log and keep going.
        debugPrint('RadiusAlertRunner: alert ${alert.id} failed: $e');
      }
    }
    return fired;
  }

  /// Stable notification id per (alert, station) pair. Re-fires
  /// overwrite the existing notification in place rather than
  /// stacking a fresh banner for every periodic check.
  static int _notificationId(String alertId, String stationId) =>
      'radius:$alertId:$stationId'.hashCode;
}

/// Everything the notification-copy builder needs to format a single
/// fired radius alert. Kept as a plain value object so the main-
/// isolate preview and the BG runner produce identical strings.
class RadiusAlertNotification {
  final RadiusAlert alert;
  final String stationId;
  final double price;

  const RadiusAlertNotification({
    required this.alert,
    required this.stationId,
    required this.price,
  });
}

/// User-facing copy for a radius alert notification.
class RadiusAlertCopy {
  final String title;
  final String body;
  const RadiusAlertCopy({required this.title, required this.body});
}
