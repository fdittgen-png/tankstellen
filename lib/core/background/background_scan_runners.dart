// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/alerts/data/models/price_alert.dart';
import '../../features/alerts/data/price_snapshot_store.dart';
import '../../features/alerts/data/radius_alert_dedup.dart';
import '../../features/alerts/data/radius_alert_runner.dart';
import '../../features/alerts/data/radius_alert_store.dart';
import '../../features/alerts/data/repositories/alert_repository.dart';
import '../../features/alerts/data/velocity_alert_cooldown.dart';
import '../../features/alerts/data/velocity_alert_runner.dart';
import '../../features/alerts/domain/radius_alert_evaluator.dart';
import '../../features/alerts/domain/velocity_alert_detector.dart';
import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../constants/field_names.dart';
import '../logging/error_logger.dart';
import '../notifications/local_notification_service.dart';
import '../services/country_service_registry.dart';
import '../storage/hive_storage.dart';
import '../storage/storage_keys.dart';
import '../telemetry/storage/isolate_error_spool.dart';
import '../utils/json_extensions.dart';
import 'background_price_source.dart';
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

  /// #2246 — the switch intentionally stays at e5/e10/diesel: those are the
  /// only fuels Tankerkönig's prices feed exposes.
  static Future<void> runPerStationAlerts({
    required AlertRepository repo,
    required List<PriceAlert> alerts,
    required Map<String, Map<String, dynamic>> prices,
    required DateTime now,
    required BackgroundNotificationTemplates templates,
  }) async {
    final activeAlerts = alerts.where((a) => a.isActive).toList();
    if (activeAlerts.isEmpty || prices.isEmpty) {
      final reason = activeAlerts.isEmpty
          ? (prices.isEmpty
              ? 'no active alerts AND no prices fetched'
              : 'no active alerts')
          : 'no prices fetched (refresh failed?)';
      debugPrint('BackgroundScanRunners: alert loop skipped — $reason');
      return;
    }

    final notifier = LocalNotificationService();
    await notifier.initialize();
    var notificationCount = 0;

    for (final alert in activeAlerts) {
      final stationPrices = prices[alert.stationId];
      if (stationPrices == null ||
          stationPrices[TankerkoenigFields.status] ==
              TankerkoenigFields.statusNoPrices) {
        continue;
      }
      double? currentPrice;
      switch (alert.fuelType) {
        case FuelTypeE5():
          currentPrice = stationPrices.getDouble(TankerkoenigFields.e5);
        case FuelTypeE10():
          currentPrice = stationPrices.getDouble(TankerkoenigFields.e10);
        case FuelTypeDiesel():
          currentPrice = stationPrices.getDouble(TankerkoenigFields.diesel);
        default:
          continue;
      }
      if (currentPrice == null || currentPrice > alert.targetPrice) continue;

      if (alert.lastTriggeredAt != null &&
          now.difference(alert.lastTriggeredAt!) <
              priceAlertRetriggerCooldown) {
        debugPrint(
            'BackgroundScanRunners: alert ${alert.stationId} tripped '
            'but cooldown still active — skipping');
        continue;
      }

      await notifier.showPriceAlert(
        id: alert.stationId.hashCode,
        title: templates.renderPriceAlertTitle(
          station: alert.stationName,
          fuelType: alert.fuelType.displayName,
        ),
        body: templates.renderPriceAlertBody(
          price: currentPrice.toStringAsFixed(3),
          target: alert.targetPrice.toStringAsFixed(3),
        ),
      );
      notificationCount++;
      await repo.saveAlert(alert.copyWith(lastTriggeredAt: now));
    }
    debugPrint('BackgroundScanRunners: $notificationCount alerts triggered');
  }

  /// #579 — velocity detector across nearby stations.
  static Future<void> runVelocity({
    required HiveStorage storage,
    required Map<String, Map<String, dynamic>> prices,
    required DateTime now,
    required BackgroundNotificationTemplates templates,
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
      final fuelKey = tankerkoenigKeyFor(config.fuelType);
      if (fuelKey == null) {
        debugPrint('BackgroundScanRunners: velocity skipped — '
            '${config.fuelType.apiValue} not in Tankerkoenig response');
        return;
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
        return;
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
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'BackgroundScanRunners: velocity detector failed'
      }));
      await IsolateErrorSpool.enqueue(
        isolateTaskName: 'velocity_detector',
        error: e,
        stack: st,
        contextMap: <String, dynamic>{'priceCount': prices.length},
      );
    }
  }

  /// #578 phase 3 — radius alerts via [RadiusAlertRunner] (reused read-only).
  ///
  /// #2862 — each alert's samples now come from the registry-driven
  /// [BackgroundPriceSource] for the **country its centre falls in**
  /// (derived via the bounding box), instead of a single hardcoded
  /// Tankerkönig search, so a radius alert in PT / AT / … is evaluated
  /// against that country's provider. The source caches its per-country
  /// services, so all alerts in one country reuse one provider. Centres in a
  /// non-polled country (e.g. bulk-dataset ES/IT — child #2863) yield no
  /// samples this scan.
  static Future<void> runRadiusAlerts({
    required DateTime now,
    required BackgroundPriceSource source,
    required String? apiKey,
    required BackgroundNotificationTemplates templates,
  }) async {
    try {
      final store = RadiusAlertStore();
      final radiusAlerts = await store.list();
      if (radiusAlerts.where((a) => a.enabled).isEmpty) {
        debugPrint('BackgroundScanRunners: no active radius alerts');
        return;
      }
      final notifier = LocalNotificationService();
      await notifier.initialize();
      final runner = RadiusAlertRunner(
        store: store,
        dedup: RadiusAlertDedup(),
        notifier: notifier,
        copyBuilder: (event) => buildRadiusAlertCopy(event, templates),
      );
      final fired = await runner.run(
        now: now,
        samplesFor: (alert) async {
          final country = CountryServiceRegistry.countryForLatLng(
              alert.centerLat, alert.centerLng);
          if (country == null) return const <StationPriceSample>[];
          final stations = await source.searchStations(
            countryCode: country,
            params: SearchParams(
              lat: alert.centerLat,
              lng: alert.centerLng,
              radiusKm: alert.radiusKm,
            ),
            apiKey: apiKey,
          );
          final samples = <StationPriceSample>[];
          for (final station in stations) {
            samples.addAll(StationPriceSample.fromStation(station));
          }
          return samples;
        },
      );
      debugPrint('BackgroundScanRunners: ${fired.length} radius alerts fired');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'BackgroundScanRunners: radius alert runner failed'
      }));
      await IsolateErrorSpool.enqueue(
        isolateTaskName: 'radius_alerts',
        error: e,
        stack: st,
      );
    }
  }
}

/// Map [FuelType] → Tankerkoenig JSON key. The BG isolate only fetches
/// E5/E10/diesel today so other fuels return `null` and skip velocity
/// detection. Top-level + visible-for-testing so the copy/format helpers
/// stay testable without a coordinator instance.
@visibleForTesting
String? tankerkoenigKeyFor(FuelType fuelType) => switch (fuelType) {
      FuelTypeE5() => TankerkoenigFields.e5,
      FuelTypeE10() => TankerkoenigFields.e10,
      FuelTypeDiesel() => TankerkoenigFields.diesel,
      _ => null,
    };

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
@visibleForTesting
RadiusAlertCopy buildRadiusAlertCopy(
  RadiusAlertGroupedEvent event,
  BackgroundNotificationTemplates templates,
) {
  final threshold = event.alert.threshold.toStringAsFixed(3);
  final label = event.alert.label;
  final currency = templates.currencySymbol;
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
    ),
    body: lines.join('\n'),
  );
}
