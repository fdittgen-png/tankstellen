// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The scan's opportunity phase: detect on three paths, decide once
/// (#4183).
///
/// What this replaced, in the coordinator, was three independent calls
/// each of which notified and returned a count:
///
///     alertsFired  = runPerStationAlerts(…)   // fires 1 per tripped alert
///     alertsFired += runVelocity(…)           // fires its own
///     alertsFired += runRadiusAlerts(…)       // fires its own
///
/// Three runners each certain of themselves cannot make one budget.
/// `alert_delivery_sla` pins the contract at **1-3 per day, ≤3-4 h
/// latency, never next-day**, and with three independent cooldowns that
/// was a coincidence of thresholds rather than a property of the system.
///
/// Its own library rather than more lines in the coordinator: that file
/// is the scan's LIFECYCLE authority (the lock, the journal, the
/// trigger cooldown, the trace) and it was at the 400-line cap. "Which
/// findings deserve an interruption" is a different question from "did
/// this scan run".
library;

import '../../../core/logging/app_log.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/notifications/notification_delivery.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/hive_storage.dart';
import '../data/models/price_alert.dart';
import '../data/repositories/alert_repository.dart';
import '../domain/opportunity.dart';
import 'background_scan_runners.dart';
import 'country_alert_strategy_resolver.dart';
import 'notification_templates.dart';
import 'opportunity_dispatcher.dart';
import 'velocity_scan_detector.dart';

/// What one scan's dispatch did, for the scan journal: how many
/// notifications went out (at most one, #3147), and what became of the
/// winner's notification when it did not (#4335) — null when nothing was
/// attempted or it was posted.
typedef ScanDispatchResult = ({int alertsFired, NotificationDelivery? undelivered});

/// Run the three detectors, hand everything to one budget, and record
/// what the user was actually told.
///
/// [notifier] builds the initialized notifier the dispatch posts through
/// (#4162) — the platform plugin in production, a recording fake in the
/// lifecycle suites. Called after detection, as the inline construction
/// it replaced was.
Future<ScanDispatchResult> detectAndDispatch({
  required AlertRepository repo,
  required List<PriceAlert> alerts,
  required Map<String, Map<String, dynamic>> prices,
  required DateTime now,
  required BackgroundNotificationTemplates templates,
  required HiveStorage storage,
  required CountryAlertStrategyResolver resolver,
  String? activeCountry,
  OpportunityDispatcher dispatcher = const OpportunityDispatcher(),
  Future<NotificationService> Function()? notifier,
}) async {
  final candidates = <OpportunityCandidate>[
    ...await BackgroundScanRunners.detectPerStationAlerts(
      repo: repo,
      alerts: alerts,
      prices: prices,
      now: now,
      templates: templates,
      fallbackCountryCode: activeCountry,
    ),
    if (prices.isNotEmpty)
      ...await detectVelocity(
        storage: storage,
        prices: prices,
        now: now,
        templates: templates,
        fallbackCountryCode: activeCountry,
      ),
    ...await BackgroundScanRunners.detectRadiusAlerts(
      now: now,
      resolver: resolver,
      templates: templates,
    ),
  ];

  final dispatch = await dispatcher.dispatch(
    candidates: candidates,
    now: now,
    notifier: await (notifier ?? initializedLocalNotifier)(),
    templates: templates,
  );

  // `lastTriggeredAt` is user-visible in the alert list, so it has to
  // mean "you were told", not "we considered it". Written here, after
  // the dispatcher actually sent — never by the detector.
  if (dispatch.notifiedOpportunity case final sent?
      when sent.kind == OpportunityKind.favouriteStation) {
    for (final alert in alerts) {
      if (alert.stationId == sent.stationId) {
        await repo.saveAlert(alert.copyWith(lastTriggeredAt: now));
      }
    }
  }

  if (dispatch.demotions.isNotEmpty) {
    log.debug(
        'scan: ${dispatch.demotions.length} opportunities demoted — '
        '${dispatch.demotions.map((d) => d.reason.name).toSet().join(", ")}',
        tag: 'detectAndDispatch');
  }

  final delivery = dispatch.delivery;
  return (
    alertsFired: dispatch.notified ? 1 : 0,
    undelivered: delivery == null || delivery.wasPosted ? null : delivery,
  );
}

/// The production notifier: the platform plugin, initialized (it registers
/// the channels, #2209).
Future<NotificationService> initializedLocalNotifier() async {
  final notifier = LocalNotificationService();
  await notifier.initialize();
  return notifier;
}
