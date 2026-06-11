// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

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
import '../../alerts/domain/velocity_alert_detector.dart';
import '../../../core/domain/search_params.dart';
import '../../../core/constants/field_names.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/utils/json_extensions.dart';
import 'country_alert_strategy_resolver.dart';
import 'fuel_price_fields.dart';
import 'notification_templates.dart';

/// Alert-evaluation runners invoked by [BackgroundAlertScanCoordinator]
/// during a scan (#2415). Split out of the coordinator to keep each file
/// reviewable (file-length cap). These are the three notification paths the
/// scan fans out into — per-station price alerts, the velocity detector, and
/// radius alerts — plus the localized copy builders they share.
///
/// All methods assume Hive is already initialised in this isolate and the
/// HiveIsolateLock is held (the coordinator owns that lifecycle). Each runner
/// reuses the existing alert machinery read-only (RadiusAlertRunner,
/// VelocityAlertRunner) and never mutates their throttle behaviour.
class BackgroundScanRunners {
  BackgroundScanRunners._();

  /// Do not re-fire the same per-station price alert within this window.
  static const priceAlertRetriggerCooldown = Duration(hours: 4);

  /// #2864 — per-station price-alert evaluation is now country/currency/fuel
  /// aware. Each alert's country is derived from its station-id prefix
  /// ([CountryServiceRegistry.countryForStationId], falling back to
  /// [fallbackCountryCode] for prefix-less legacy ids); the current price is
  /// read via the per-country fuel mapping ([priceFieldKeyForCountry]) so an
  /// LPG / CNG / E98 alert in a country whose provider exposes that fuel fires,
  /// and the notification renders in that country's currency. DE e5/e10/diesel
  /// resolution + the euro are unchanged.
  /// Returns the number of notifications fired (#3147 — the count feeds
  /// the coordinator's persisted scan journal).
  static Future<int> runPerStationAlerts({
    required AlertRepository repo,
    required List<PriceAlert> alerts,
    required Map<String, Map<String, dynamic>> prices,
    required DateTime now,
    required BackgroundNotificationTemplates templates,
    String? fallbackCountryCode,
    @visibleForTesting NotificationService? notifier,
  }) async {
    final activeAlerts = alerts.where((a) => a.isActive).toList();
    if (activeAlerts.isEmpty || prices.isEmpty) {
      final reason = activeAlerts.isEmpty
          ? (prices.isEmpty
              ? 'no active alerts AND no prices fetched'
              : 'no active alerts')
          : 'no prices fetched (refresh failed?)';
      debugPrint('BackgroundScanRunners: alert loop skipped — $reason');
      return 0;
    }

    final notify = notifier ?? LocalNotificationService();
    await notify.initialize();
    var notificationCount = 0;

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

      if (alert.lastTriggeredAt != null &&
          now.difference(alert.lastTriggeredAt!) <
              priceAlertRetriggerCooldown) {
        debugPrint(
            'BackgroundScanRunners: alert ${alert.stationId} tripped '
            'but cooldown still active — skipping');
        continue;
      }

      await notify.showPriceAlert(
        id: alert.stationId.hashCode,
        title: templates.renderPriceAlertTitle(
          station: alert.stationName,
          fuelType: alert.fuelType.displayName,
        ),
        body: templates.renderPriceAlertBody(
          price: currentPrice.toStringAsFixed(3),
          target: alert.targetPrice.toStringAsFixed(3),
          currency: templates.currencyForCountry(country),
        ),
      );
      notificationCount++;
      await repo.saveAlert(alert.copyWith(lastTriggeredAt: now));
    }
    debugPrint('BackgroundScanRunners: $notificationCount alerts triggered');
    return notificationCount;
  }

  /// #579 — velocity detector across nearby stations.
  ///
  /// #2864 — the velocity fuel is now read via the per-country fuel mapping for
  /// the active country ([fallbackCountryCode]), so the detector runs on the
  /// fuel the user's country actually exposes (e.g. an LPG velocity alert in FR)
  /// rather than the DE-only e5/e10/diesel switch.
  /// Returns 1 when a velocity notification fired, else 0 (#3147).
  static Future<int> runVelocity({
    required HiveStorage storage,
    required Map<String, Map<String, dynamic>> prices,
    required DateTime now,
    required BackgroundNotificationTemplates templates,
    String? fallbackCountryCode,
  }) async {
    try {
      final notifier = LocalNotificationService();
      await notifier.initialize();
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
        return 0;
      }
      final observations = <VelocityStationObservation>[];
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
        observations.add(VelocityStationObservation(
          stationId: stationId,
          price: price,
          lat: lat,
          lng: lng,
        ));
      }
      if (observations.isEmpty) {
        debugPrint('BackgroundScanRunners: velocity has no usable '
            'observations');
        return 0;
      }
      final userLat = storage.getSetting(StorageKeys.userPositionLat) as num?;
      final userLng = storage.getSetting(StorageKeys.userPositionLng) as num?;
      final event = await runner.run(
        observations: observations,
        now: now,
        userLat: userLat?.toDouble(),
        userLng: userLng?.toDouble(),
      );
      if (event != null) {
        debugPrint('BackgroundScanRunners: velocity alert '
            '${event.fuelType.apiValue}, count=${event.stationCount}');
        return 1;
      }
      return 0;
    } catch (e, st) {
      // #3147 bonus — single log call: `errorLogger.log` already routes
      // to the IsolateErrorSpool when unbound, so the former explicit
      // `IsolateErrorSpool.enqueue` double-logged every failure (halving
      // the effective spool depth); context travels in the map instead.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'BackgroundScanRunners: velocity detector failed',
        'isolateTaskName': 'velocity_detector',
        'priceCount': prices.length,
      }));
      return 0;
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
  /// Returns the number of radius alerts fired (#3147).
  static Future<int> runRadiusAlerts({
    required DateTime now,
    required CountryAlertStrategyResolver resolver,
    required BackgroundNotificationTemplates templates,
  }) async {
    try {
      final store = RadiusAlertStore();
      final radiusAlerts = await store.list();
      if (radiusAlerts.where((a) => a.enabled).isEmpty) {
        debugPrint('BackgroundScanRunners: no active radius alerts');
        return 0;
      }
      final notifier = LocalNotificationService();
      await notifier.initialize();
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
      debugPrint('BackgroundScanRunners: ${fired.length} radius alerts fired');
      return fired.length;
    } catch (e, st) {
      // #3147 bonus — single log call (see [runVelocity]'s catch).
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'BackgroundScanRunners: radius alert runner failed',
        'isolateTaskName': 'radius_alerts',
      }));
      return 0;
    }
  }
}

/// Build notification copy for a velocity event. #2306 — copy comes from the
/// localized [BackgroundNotificationTemplates] the main isolate resolved for
/// the active in-app language.
@visibleForTesting
VelocityAlertCopy buildVelocityCopy(
  VelocityAlertEvent event,
  BackgroundNotificationTemplates templates,
) {
  final fuelLabel = event.fuelType.displayName.toUpperCase();
  return VelocityAlertCopy(
    title: templates.renderVelocityTitle(fuelLabel: fuelLabel),
    body: templates.renderVelocityBody(
      count: event.stationCount,
      cents: event.maxDropCents.round(),
    ),
  );
}

/// Build notification copy for a grouped radius alert (#1012 phase 2). #2306
/// — copy comes from the localized [BackgroundNotificationTemplates].
///
/// #2864 — the currency is resolved from the radius centre's country (via the
/// registry bounding box), so a GB / DK / … radius alert renders in £ / kr
/// instead of a forced euro. A centre outside every registered box falls back
/// to the template's default (euro).
@visibleForTesting
RadiusAlertCopy buildRadiusAlertCopy(
  RadiusAlertGroupedEvent event,
  BackgroundNotificationTemplates templates,
) {
  final threshold = event.alert.threshold.toStringAsFixed(3);
  final label = event.alert.label;
  final country = CountryServiceRegistry.countryForLatLng(
      event.alert.centerLat, event.alert.centerLng);
  final currency = templates.currencyForCountry(country);
  final total = event.matches.length + event.truncatedMoreCount;
  final lines = event.matches
      // #2211 — show the station name, not the raw id. The per-line
      // "name price currency" mask is language-neutral.
      .map((m) => '${m.name} ${m.pricePerLiter.toStringAsFixed(3)} $currency')
      .toList();
  if (event.truncatedMoreCount > 0) {
    lines.add(templates.renderRadiusMore(count: event.truncatedMoreCount));
  }
  return RadiusAlertCopy(
    title: templates.renderRadiusTitle(
      label: label,
      count: total,
      threshold: threshold,
      currency: currency,
    ),
    body: lines.join('\n'),
  );
}
