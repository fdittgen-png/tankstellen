// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT


import 'package:flutter/foundation.dart';

import '../../alerts/data/models/price_alert.dart';
import '../../alerts/data/price_snapshot_store.dart';
import '../../alerts/data/radius_alert_dedup.dart';
import '../../alerts/data/radius_alert_runner.dart';
import '../../alerts/data/radius_alert_store.dart';
import '../../alerts/data/repositories/alert_repository.dart';
import '../../alerts/data/velocity_alert_cooldown.dart';
import '../../alerts/data/velocity_alert_runner.dart';
import '../../alerts/domain/radius_alert_evaluator.dart';
import '../../alerts/domain/opportunity_detectors.dart';
import '../../../core/services/provider_capability.dart';
import '../../../core/domain/search_params.dart';
import '../../../core/constants/field_names.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/utils/json_extensions.dart';
import 'country_alert_strategy_resolver.dart';
import 'fuel_price_fields.dart';
import 'notification_templates.dart';
import 'scan_notification_copy_builders.dart';
import 'opportunity_dispatcher.dart';
import 'scan_opportunity_capture.dart';

/// Alert-evaluation runners invoked by [BackgroundAlertScanCoordinator]
/// during a scan (#2415). Split out of the coordinator to keep each file
/// reviewable (file-length cap). These are the three detection paths the
/// scan fans out into — per-station price alerts, the velocity detector, and
/// radius alerts — plus the localized copy builders they share.
///
/// All methods assume Hive is already initialised in this isolate and the
/// HiveIsolateLock is held (the coordinator owns that lifecycle).
///
/// ## #4183 — they detect, they no longer decide
///
/// Each returns [OpportunityCandidate]s now instead of posting
/// notifications and counting them. Three runners each certain of
/// themselves could not make one budget: `alert_delivery_sla`'s "1-3 per
/// day, never next-day" was a coincidence of three thresholds rather than
/// a property of the system. [OpportunityDispatcher] makes the single
/// interrupt decision and records everything it refuses.
///
/// The velocity and radius paths reach that shape through
/// [CapturingNotificationService] rather than a rewrite — see
/// `scan_opportunity_capture.dart` for what that preserves and the one
/// ordering caveat it leaves (#4185).
class BackgroundScanRunners {
  BackgroundScanRunners._();

  /// Do not re-fire the same per-station price alert within this window.
  ///
  /// #4183 — **no longer the gate.** `BudgetPolicy.perStationQuiet` (12 h,
  /// across every detector) now decides, and it is strictly stricter, so
  /// this 4 h check became dead weight in front of it. Kept as a constant
  /// because `background_service.dart` re-exports it and because the
  /// number records what the per-station path used to promise.
  ///
  /// The consequence is the one user-visible behaviour change in #4183: a
  /// station alert the user configured can now re-fire at most every 12 h
  /// rather than every 4. That follows from #4151's decision to have ONE
  /// budget across kinds; a 4 h per-station retrigger and a 1-3/day cap
  /// are not simultaneously satisfiable once a user has several alerts.
  /// Tune `perStationQuiet`, not this.
  static const priceAlertRetriggerCooldown = Duration(hours: 4);

  /// #2864 — per-station price-alert evaluation is now country/currency/fuel
  /// aware. Each alert's country is derived from its station-id prefix
  /// ([CountryServiceRegistry.countryForStationId], falling back to
  /// [fallbackCountryCode] for prefix-less legacy ids); the current price is
  /// read via the per-country fuel mapping ([priceFieldKeyForCountry]) so an
  /// LPG / CNG / E98 alert in a country whose provider exposes that fuel fires,
  /// and the notification renders in that country's currency. DE e5/e10/diesel
  /// resolution + the euro are unchanged.
  /// #4183 — returns the opportunities this path FOUND. Whether any of
  /// them interrupts anyone is [OpportunityDispatcher]'s decision.
  static Future<List<OpportunityCandidate>> detectPerStationAlerts({
    required AlertRepository repo,
    required List<PriceAlert> alerts,
    required Map<String, Map<String, dynamic>> prices,
    required DateTime now,
    required BackgroundNotificationTemplates templates,
    String? fallbackCountryCode,
    HiveStorage? storage,
  }) async {
    final activeAlerts = alerts.where((a) => a.isActive).toList();
    if (activeAlerts.isEmpty || prices.isEmpty) {
      final reason = activeAlerts.isEmpty
          ? (prices.isEmpty
              ? 'no active alerts AND no prices fetched'
              : 'no active alerts')
          : 'no prices fetched (refresh failed?)';
      debugPrint('BackgroundScanRunners: alert loop skipped — $reason');
      return const [];
    }

    final found = <OpportunityCandidate>[];

    for (final alert in activeAlerts) {
      final stationPrices = prices[alert.stationId];
      if (stationPrices == null ||
          stationPrices[TankerkoenigFields.status] ==
              TankerkoenigFields.statusNoPrices) {
        continue;
      }
      final country =
          CountryServiceRegistry.countryForStationId(alert.stationId) ??
              fallbackCountryCode;
      final fuelKey = country == null
          ? priceFieldKeyFor(alert.fuelType)
          : priceFieldKeyForCountry(alert.fuelType, country);
      if (fuelKey == null) continue;
      final currentPrice = stationPrices.getDouble(fuelKey);
      if (currentPrice == null || currentPrice > alert.targetPrice) continue;

      // #4183 — no local cooldown check. `BudgetPolicy.perStationQuiet`
      // is stricter and spans every detector; see the constant's doc.
      // `lastTriggeredAt` is still written, by the coordinator, AFTER a
      // notification actually goes out — it is user-visible in the alert
      // list and must mean "you were told", not "we considered it".
      final capability =
          country == null ? null : CountryServiceRegistry.capabilityFor(country);
      found.add(OpportunityCandidate(
        opportunityFromPriceAlert(
          alert: alert,
          currentPrice: currentPrice,
          // No user position in this path, and a fabricated distance
          // would reach the budget's ranking. Zero is the honest input:
          // the ranking is by money, and this kind carries none.
          distanceKm: 0,
          // #4186 — a real age now, where the provider published a
          // stamp. The freshness gate can finally refuse a stale
          // background opportunity instead of never seeing one.
          priceAge: priceAgeForScannedRow(capability,
              stampedAt: scannedRowStamp(stationPrices), now: now),
          confidence: capability?.confidence ?? DataConfidence.none,
          now: now,
        ),
        // The copy this path has always produced, verbatim.
        copy: (
          title: templates.renderPriceAlertTitle(
            station: alert.stationName,
            fuelType: alert.fuelType.displayName,
          ),
          body: templates.renderPriceAlertBody(
            price: currentPrice.toStringAsFixed(3),
            target: alert.targetPrice.toStringAsFixed(3),
            currency: templates.currencyForCountry(country),
          ),
        ),
      ));
    }
    debugPrint('BackgroundScanRunners: ${found.length} station alerts tripped');
    return found;
  }


  /// #579 — velocity detector across nearby stations.
  ///
  /// #2864 — the velocity fuel is now read via the per-country fuel mapping for
  /// the active country ([fallbackCountryCode]), so the detector runs on the
  /// fuel the user's country actually exposes (e.g. an LPG velocity alert in FR)
  /// rather than the DE-only e5/e10/diesel switch.
  /// #4183 — detects; the dispatcher decides.
  static Future<List<OpportunityCandidate>> detectVelocity({
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
        debugPrint('BackgroundScanRunners: velocity skipped — '
            '${config.fuelType.apiValue} not in the active country feed');
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
        debugPrint('BackgroundScanRunners: velocity has no usable '
            'observations');
        return const [];
      }
      final userLat = storage.getSetting(StorageKeys.userPositionLat) as num?;
      final userLng = storage.getSetting(StorageKeys.userPositionLng) as num?;
      final event = await runner.run(
        observations: observations,
        now: now,
        userLat: userLat?.toDouble(),
        userLng: userLng?.toDouble(),
      );
      if (event == null) return const [];
      debugPrint('BackgroundScanRunners: velocity movement '
          '${event.fuelType.apiValue}, count=${event.stationCount}');

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
      return pairWithCapturedCopy(
        [
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
        ],
        notifier.captured,
      );
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
  static Future<List<OpportunityCandidate>> detectRadiusAlerts({
    required DateTime now,
    required CountryAlertStrategyResolver resolver,
    required BackgroundNotificationTemplates templates,
  }) async {
    try {
      final store = RadiusAlertStore();
      final radiusAlerts = await store.list();
      if (radiusAlerts.where((a) => a.enabled).isEmpty) {
        debugPrint('BackgroundScanRunners: no active radius alerts');
        return const [];
      }
      // #4183 — the runner keeps its dedup (including the price-drop
      // escape hatch), its grouping and its copy; only the POST is
      // intercepted. See `scan_opportunity_capture.dart`.
      final notifier = CapturingNotificationService();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: RadiusAlertDedup(),
        notifier: notifier,
        // #2864 — currency comes from the centre's country, so a GB / DK / …
        // radius alert renders in £ / kr instead of a forced euro.
        copyBuilder: (event) => buildRadiusAlertCopy(event, templates),
        // #2864 — the deep-link payload country is the centre's country, not a
        // hardcoded 'de'.
        countryResolver: (alert) => CountryServiceRegistry.countryForLatLng(
            alert.centerLat, alert.centerLng),
      );
      final fired = await runner.run(
        now: now,
        samplesFor: (alert) async {
          final country = CountryServiceRegistry.countryForLatLng(
              alert.centerLat, alert.centerLng);
          if (country == null) return const <StationPriceSample>[];
          final strategy = resolver.strategyFor(country);
          if (strategy == null) return const <StationPriceSample>[];
          final stations = await strategy.searchArea(
            SearchParams(
              lat: alert.centerLat,
              lng: alert.centerLng,
              radiusKm: alert.radiusKm,
            ),
          );
          final samples = <StationPriceSample>[];
          for (final station in stations) {
            samples.addAll(StationPriceSample.fromStation(station));
          }
          return samples;
        },
      );
      debugPrint('BackgroundScanRunners: ${fired.length} radius alerts '
          'matched');

      // One opportunity per grouped event, standing for its cheapest
      // match — the grouped COPY the runner built travels with it, so
      // "Berlin: 5 stations ≤ 1.699 €" survives intact. Building one
      // opportunity per station instead would put five candidates in
      // front of a budget that can only send one, and the winner would
      // then be rendered as a single station.
      // Paired by INDEX inside one loop rather than by two lists of the
      // same length afterwards: a grouped event with no matches would
      // shorten `found` and silently de-pair every candidate's copy.
      // Here a skipped event skips its own capture and nothing else.
      final found = <OpportunityCandidate>[];
      for (var i = 0; i < fired.length; i++) {
        final event = fired[i];
        if (event.matches.isEmpty) continue;
        final cheapest = event.matches
            .reduce((a, b) => a.pricePerLiter <= b.pricePerLiter ? a : b);
        final country = CountryServiceRegistry.countryForLatLng(
            event.alert.centerLat, event.alert.centerLng);
        final capability = country == null
            ? null
            : CountryServiceRegistry.capabilityFor(country);
        found.add(OpportunityCandidate(
          opportunityFromRadiusMatch(
            alert: event.alert,
            sample: cheapest,
            // The runner reports matches within the alert's radius; the
            // per-match distance is not on the sample, and inventing one
            // would reach the budget's ordering.
            distanceKm: 0,
            // #4186 — the sample carries its station's stamp now.
            priceAge: priceAgeForScannedRow(capability,
                stampedAt: cheapest.priceUpdatedAt, now: now),
            confidence: capability?.confidence ?? DataConfidence.none,
            now: now,
          ),
          copy: i < notifier.captured.length
              ? notifier.captured[i].copy
              : null,
        ));
      }
      return found;
    } catch (e, st) {
      // #3147 bonus — single log call (see [runVelocity]'s catch).
      log.error(e, st, layer: ErrorLayer.other, context: const {
        'where': 'BackgroundScanRunners: radius alert runner failed',
        'isolateTaskName': 'radius_alerts',
      });
      return const [];
    }
  }
}
