import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_payload.dart';
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
/// alert evaluator (#578 phase 3 + #1012 phases 1–2).
///
/// The background isolate calls [run] once per cycle. The runner:
///   1. loads every active [RadiusAlert] from [RadiusAlertStore],
///   2. honours the per-alert frequencyPerDay throttle (#1012 phase 1)
///      so a 1×/day alert only re-evaluates once per 24 h,
///   3. asks the [samplesFor] callback for stations currently in
///      range of each alert (per-country StationService in the real
///      path, fake fixtures in tests),
///   4. uses [RadiusAlertEvaluator] to pick every matching sample,
///   5. sorts the matches by price ascending, caps at top-5,
///   6. runs the *alert as a whole* past [RadiusAlertDedup] (12 h
///      window, with a "cheaper than last fire" override), and
///   7. fires **one** grouped local notification per alert per cycle
///      with the top-N stations rolled up into one body.
///
/// The dedup record also stamps every per-station match in this cycle
/// so phase 3's per-station deep-link payload can read the last-fired
/// price for any station that appeared in a notification — even though
/// the dedup *decision* is now made at the alert level.
///
/// All collaborators are injected so the service-level integration
/// test can seed an alert + a fake samples provider and assert that
/// the notifier was called exactly once.
class RadiusAlertRunner {
  /// Maximum number of stations rendered in the grouped notification
  /// body. Keeping this small (5) means the notification stays
  /// glanceable on the Android lock screen — anything past five lines
  /// gets truncated by the system anyway, and the "+ X more" suffix
  /// tells the user to open the app for the full list.
  static const int maxStationsInBody = 5;

  final RadiusAlertStore store;
  final RadiusAlertDedup dedup;
  final NotificationService notifier;
  final RadiusAlertEvaluator evaluator;

  /// User-facing notification copy. Background isolates can't reach
  /// ARB bundles (no BuildContext) so the caller passes in a pure
  /// function that formats against the event payload. Keep the
  /// signature stable so the main-isolate preview and the BG runner
  /// emit identical strings.
  final RadiusAlertCopy Function(RadiusAlertGroupedEvent event)
      copyBuilder;

  /// 2-letter country code stamped into the deep-link payload so the
  /// tap resolver can disambiguate id collisions across countries
  /// (#1012 phase 3). Today the BG isolate only wires Tankerkönig, so
  /// this is `'de'` in production. Tests inject whatever they need.
  final String country;

  RadiusAlertRunner({
    required this.store,
    required this.dedup,
    required this.notifier,
    required this.copyBuilder,
    this.country = 'de',
    RadiusAlertEvaluator? evaluator,
  }) : evaluator = evaluator ?? const RadiusAlertEvaluator();

  /// Execute the whole pipeline. Returns the list of fired grouped
  /// events (may be empty) so callers can log / assert / update a
  /// widget status line without re-walking state.
  ///
  /// Safe to call with no active alerts: the runner returns an empty
  /// list and never touches the notifier.
  Future<List<RadiusAlertGroupedEvent>> run({
    required DateTime now,
    required SamplesForAlert samplesFor,
  }) async {
    final alerts = await store.list();
    final active = alerts.where((a) => a.enabled).toList();
    if (active.isEmpty) return const [];

    final fired = <RadiusAlertGroupedEvent>[];
    for (final alert in active) {
      try {
        // #1012 phase 1 — per-alert frequency throttling. Skip the
        // alert when it was evaluated more recently than the user-
        // configured cadence allows. A null lastEvaluatedAt means
        // "never evaluated" (brand-new alert, or pre-#1012 upgrade)
        // and falls through to evaluation regardless of frequency.
        final lastEval = await store.getLastEvaluatedAt(alert.id);
        if (lastEval != null) {
          final gap = frequencyToGap(alert.frequencyPerDay);
          if (now.difference(lastEval) < gap) {
            continue;
          }
        }

        final samples = await samplesFor(alert);
        // Record the evaluation timestamp regardless of match
        // outcome so the throttler applies to "no match" cycles too
        // — otherwise an alert with no in-range stations would be
        // re-queried every cycle and burn the StationService budget.
        await store.recordEvaluatedAt(alert.id, now);
        if (samples.isEmpty) continue;
        final matches = evaluator.matches(alert, samples).toList();
        if (matches.isEmpty) continue;

        // #1012 phase 2 — sort cheap-first and cap the rendered list
        // at top-5. The full list still drives the dedup record so
        // phase 3 can deep-link any station the user saw.
        matches.sort(
            (a, b) => a.pricePerLiter.compareTo(b.pricePerLiter));
        final cheapest = matches.first.pricePerLiter;
        final topMatches = matches.length > maxStationsInBody
            ? matches.sublist(0, maxStationsInBody)
            : List<StationPriceSample>.from(matches);
        final truncatedMore = matches.length - topMatches.length;

        // #1012 phase 2 — alert-level dedup. We notify once per alert
        // per cycle, so the dedup decision is now per-alert, keyed off
        // the cheapest current match. The "further drop" override
        // still applies: if the cheapest price has dropped below the
        // last-fired cheapest, surface again even inside the window.
        final allow = await dedup.shouldNotifyAlert(
          alertId: alert.id,
          cheapestPrice: cheapest,
          now: now,
        );
        if (!allow) continue;

        final event = RadiusAlertGroupedEvent(
          alert: alert,
          matches: topMatches,
          truncatedMoreCount: truncatedMore,
        );
        final copy = copyBuilder(event);
        // #1012 phase 3 — embed the cheapest match's id + country
        // into the notification payload so tapping the body deep-
        // links straight to the cheapest station's detail screen
        // (instead of just opening the launcher route). topMatches is
        // already sorted ascending by price, so `.first` is the
        // cheapest by definition.
        final payload = NotificationPayload(
          kind: NotificationPayload.kindRadius,
          stationId: topMatches.first.stationId,
          country: country,
        ).encode();
        await notifier.showPriceAlert(
          id: _notificationId(alert.id),
          title: copy.title,
          body: copy.body,
          payload: payload,
        );
        // Stamp the per-alert dedup row first — that's the source of
        // truth for the next cycle's gating decision.
        await dedup.recordAlertFire(
          alertId: alert.id,
          cheapestPrice: cheapest,
          now: now,
        );
        // Also keep the per-(alert, station) fire records refreshed
        // for every station in this cycle's match set. Phase 3's
        // deep-link payload needs to know "what was the price when we
        // told the user about this station last?" and that lookup
        // would be impossible if we only stamped the cheapest one.
        for (final match in matches) {
          await dedup.recordFire(
            alertId: alert.id,
            stationId: match.stationId,
            price: match.pricePerLiter,
            now: now,
          );
        }
        fired.add(event);
      } catch (e) {
        // One bad alert (e.g. country API down) must not block the
        // rest — log and keep going.
        debugPrint('RadiusAlertRunner: alert ${alert.id} failed: $e');
      }
    }
    return fired;
  }

  /// Stable notification id per alert. Re-fires overwrite the
  /// existing grouped notification in place rather than stacking a
  /// fresh banner for every periodic check.
  ///
  /// Phase 1 / #578 keyed this by (alertId, stationId) because every
  /// match produced its own banner; phase 2 collapses the whole alert
  /// into one banner so the id is keyed on alertId alone.
  static int _notificationId(String alertId) =>
      'radius:$alertId'.hashCode;
}

/// Everything the notification-copy builder needs to format one fired
/// radius alert (#1012 phase 2). Carries the full top-N station list
/// plus a `truncatedMoreCount` so the body renderer can append the
/// "+ X more" suffix when matches got capped.
///
/// Kept as a plain value object so the main-isolate preview and the
/// BG runner produce identical strings.
class RadiusAlertGroupedEvent {
  final RadiusAlert alert;

  /// Matching stations, sorted cheapest first and capped to the
  /// runner's [RadiusAlertRunner.maxStationsInBody] limit.
  final List<StationPriceSample> matches;

  /// Number of additional matching stations that were dropped from
  /// [matches] because of the top-N cap. Zero when nothing was
  /// truncated. Body renderers use this to print "+ X more".
  final int truncatedMoreCount;

  const RadiusAlertGroupedEvent({
    required this.alert,
    required this.matches,
    this.truncatedMoreCount = 0,
  });

  /// Convenience accessor — first (cheapest) match. Body renderers
  /// often need the headline price for the title before iterating
  /// the rest for the body lines.
  StationPriceSample get cheapest => matches.first;
}

/// User-facing copy for a radius alert notification.
class RadiusAlertCopy {
  final String title;
  final String body;
  const RadiusAlertCopy({required this.title, required this.body});
}
