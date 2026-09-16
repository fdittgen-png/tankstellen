// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The scan's velocity path (#4183, #4185), split out of
/// `background_scan_runners.dart` to keep that file under the 400-line
/// cap. Detects an area-wide price movement, captures the runner's own
/// copy, and defers the cooldown write to the dispatcher (#4185).
library;

import '../../alerts/data/price_snapshot_store.dart';
import '../../alerts/data/velocity_alert_cooldown.dart';
import '../../alerts/data/velocity_alert_runner.dart';
import '../../alerts/domain/radius_alert_evaluator.dart';
import '../../alerts/domain/opportunity_detectors.dart';
import '../../../core/services/provider_capability.dart';
import '../../../core/constants/field_names.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/utils/json_extensions.dart';
import 'fuel_price_fields.dart';
import 'notification_templates.dart';
import 'scan_notification_copy_builders.dart';
import 'opportunity_dispatcher.dart';
import 'scan_opportunity_capture.dart';

/// #4183 — detects; the dispatcher decides.
Future<List<OpportunityCandidate>> detectVelocity({
  required HiveStorage storage,
  required Map<String, Map<String, dynamic>> prices,
  required DateTime now,
  required BackgroundNotificationTemplates templates,
  String? fallbackCountryCode,
}) async {
  try {
    // #4183 — the runner keeps its cooldown and its copy; only the
    // POST is intercepted. See `scan_opportunity_capture.dart`.
    final notifier = CapturingNotificationService();
    final runner = VelocityAlertRunner(
      snapshotStore: PriceSnapshotStore(),
      cooldown: VelocityAlertCooldown(),
      notifier: notifier,
      copyBuilder: (event) => buildVelocityCopy(event, templates),
    );
    final config = await runner.loadConfig();
    final fuelKey = fallbackCountryCode == null
        ? priceFieldKeyFor(config.fuelType)
        : priceFieldKeyForCountry(config.fuelType, fallbackCountryCode);
    if (fuelKey == null) {
      log.debug(
          'velocity skipped — ${config.fuelType.apiValue} not in the '
          'active country feed',
          tag: 'velocityScan');
      return const [];
    }
    final observations = <StationPriceSample>[];
    for (final entry in prices.entries) {
      final stationId = entry.key;
      final p = entry.value;
      if (p[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) {
        continue;
      }
      final price = p.getDouble(fuelKey);
      if (price == null) continue;
      final cached = storage.getCachedData('station:$stationId');
      final data = cached?.getMap('data');
      final lat = data?.getDouble('lat');
      final lng = data?.getDouble('lng');
      if (lat == null || lng == null) continue;
      observations.add(StationPriceSample(
        stationId: stationId,
        name: data?['name']?.toString() ?? stationId,
        fuelType: config.fuelType.apiValue,
        pricePerLiter: price,
        lat: lat,
        lng: lng,
      ));
    }
    if (observations.isEmpty) {
      log.debug('velocity has no usable observations',
          tag: 'velocityScan');
      return const [];
    }
    final userLat = storage.getSetting(StorageKeys.userPositionLat) as num?;
    final userLng = storage.getSetting(StorageKeys.userPositionLng) as num?;
    final event = await runner.run(
      observations: observations,
      now: now,
      userLat: userLat?.toDouble(),
      userLng: userLng?.toDouble(),
      // #4185 — the cooldown is stamped after the budget sends, not here.
      recordFire: false,
    );
    if (event == null) return const [];
    log.debug(
        'velocity movement ${event.fuelType.apiValue}, '
        'count=${event.stationCount}',
        tag: 'velocityScan');

    // An area-wide movement, not a station: no id, no money, and no
    // NUMERIC reference. The event names the affected stations and the
    // largest drop among them, not which station that was nor what it
    // charged before — so a (current, earlier) pair composed from the
    // cheapest price plus the biggest drop would describe no station
    // at all. The cheapest current observation is a real, checkable
    // number and the one a driver would act on; the comparison stays
    // categorical (`OpportunityReference.priceEarlier`, no figure).
    final cheapest = observations
        .map((o) => o.pricePerLiter)
        .reduce((a, b) => a < b ? a : b);
    final capability = fallbackCountryCode == null
        ? null
        : CountryServiceRegistry.capabilityFor(fallbackCountryCode);
    return [
      OpportunityCandidate(
        opportunityFromVelocityEvent(
          event: event,
          // #4186 — deliberately NO stamp. A movement is about an
          // area, not a row: the observations come from many stations
          // with many stamps, and dating it by any one of them would
          // be a figure true of no station. The capability's own
          // unknown is the honest answer.
          priceAge: priceAgeForScannedRow(capability),
          confidence: capability?.confidence ?? DataConfidence.none,
          now: now,
          currentPrice: cheapest,
        ),
        copy: notifier.captured.isEmpty
            ? null
            : notifier.captured.first.copy,
        // #4185 — stamp the cooldown only if this is what went out.
        onNotified: () => runner.recordFired(event, now),
      ),
    ];
  } catch (e, st) {
    // #3147 bonus — single log call: `errorLogger.log` already routes
    // to the IsolateErrorSpool when unbound, so the former explicit
    // `IsolateErrorSpool.enqueue` double-logged every failure (halving
    // the effective spool depth); context travels in the map instead.
    log.error(e, st, layer: ErrorLayer.other, context: {
      'where': 'BackgroundScanRunners: velocity detector failed',
      'isolateTaskName': 'velocity_detector',
      'priceCount': prices.length,
    });
    return const [];
  }
}

/// #578 phase 3 — radius alerts via [RadiusAlertRunner] (reused read-only).
///
/// #2862 — each alert's samples come from the per-country source for the
/// **country its centre falls in** (derived via the bounding box), instead
/// of a single hardcoded Tankerkönig search, so a radius alert in PT / AT /
/// … is evaluated against that country's provider.
///
/// #2863 — the country is now resolved to a [CountryAlertStrategy] via the
/// per-scan [CountryAlertStrategyResolver], so **both** polled and bulk
/// countries flow through one seam: a polled centre searches its provider
/// within `minInterval`; a bulk centre (ES/IT/AR/DK + flag-gated FR/GB) is a
/// local geo-filter over the cached whole-country dataset — zero per-alert
/// network. The resolver caches strategies per country, so all alerts in one
/// country reuse one strategy (and, for bulk, one in-memory dataset). A
/// centre whose country has no buildable strategy (e.g. the AU stub) yields
/// no samples this scan.
/// #4183 — detects; the dispatcher decides.
