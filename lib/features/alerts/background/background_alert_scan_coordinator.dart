// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/alert_repository.dart';
import '../../widget/api.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/background/alert_scan_journal.dart';
import 'background_price_history_writer.dart';
import '../../../core/background/background_scan_trigger.dart';
import 'background_price_source.dart';
import 'background_scan_dedup_store.dart';
import 'background_scan_runners.dart';
import 'background_scan_tracer.dart';
import 'bulk_alert_price_merge.dart';
import 'country_alert_strategy_resolver.dart';
import 'daily_collection.dart';
import '../../../core/background/hive_isolate_lock.dart';
import 'notification_templates.dart';
import '../../../core/background/provider_request_budget.dart';

// The trigger taxonomy lives in its own file since #3169 (file-length cap);
// re-exported here so every existing importer keeps working.
export '../../../core/background/background_scan_trigger.dart';

/// Platform-neutral entry point for an on-device background price scan
/// (#2415).
///
/// Every trigger — WorkManager periodic tasks, the Android home-widget
/// refresh (#2412), and the iOS BGAppRefreshTask (#2414) — funnels through
/// [scan] so they all run *exactly the same* fetch → evaluate → notify
/// pipeline. Centralising it here means there is one place that:
///
///   1. acquires the [HiveIsolateLock] so the background and main isolates
///      never write Hive concurrently (a single serialisation point for
///      WorkManager + widget + BGTask),
///   2. enforces a coarse cross-trigger cooldown ([scanCooldown]) via
///      [BackgroundScanDedupStore] so two wakeups seconds apart can't
///      double-fetch or double-notify, and
///   3. runs the scan body (price fetch, daily history collection via
///      [BackgroundPriceHistoryWriter], the per-station / velocity / radius
///      alert runners in [BackgroundScanRunners], widget refresh).
///
/// The per-alert throttles are untouched and still own "don't re-notify the
/// same alert too often": [RadiusAlertRunner]'s frequency gate, the price-
/// alert re-trigger cooldown, and the velocity cooldown. [scanCooldown] is a
/// *separate*, shorter window that only dedups redundant *triggers*.
///
/// ## Honest reliability framing
/// Background scanning is **best-effort**, never real-time. Android delays
/// periodic work under Doze; iOS schedules BGAppRefresh opportunistically
/// against the user's app-usage budget; the widget refresh is bounded by
/// the OS. The coordinator makes triggers cheap and idempotent — it does
/// not (and cannot) make them punctual.
class BackgroundAlertScanCoordinator {
  /// Max IDs accepted per Tankerkoenig batch prices request.
  static const tankerkoenigBatchSize = 10;

  /// Coarse cross-trigger scan cooldown (#2415). A scan that lands inside
  /// this window after a completed scan is skipped, so the WorkManager
  /// task and an opportunistic widget/BGTask wake seconds later don't both
  /// hit the API. Chosen far below the twice-daily periodic cadence so a
  /// legitimately-scheduled periodic task is never starved, but long enough
  /// to absorb a burst of near-simultaneous triggers (the widget refresh +
  /// the periodic wake landing seconds apart).
  static const scanCooldown = Duration(minutes: 10);

  /// Do not re-fire the same per-station price alert within this window.
  /// Re-exported from [BackgroundScanRunners] so existing call sites + tests
  /// keep a single name for the per-alert throttle.
  static const priceAlertRetriggerCooldown =
      BackgroundScanRunners.priceAlertRetriggerCooldown;

  /// Connect / receive timeouts for the BG-isolate Dio client.
  static const bgConnectTimeout = Duration(seconds: 10);
  static const bgReceiveTimeout = Duration(seconds: 15);

  /// Max retry attempts + base backoff for transient network failures.
  static const maxRetryAttempts = 3;
  static const retryBaseDelay = Duration(seconds: 2);

  final BackgroundScanDedupStore _dedup;
  final AlertScanJournal _journal;

  /// Creates a coordinator. [dedup] and [journal] are injectable so unit
  /// tests can drive the cooldown gate / journal with fakes.
  BackgroundAlertScanCoordinator({
    BackgroundScanDedupStore? dedup,
    AlertScanJournal? journal,
  })  : _dedup = dedup ?? BackgroundScanDedupStore(),
        _journal = journal ?? AlertScanJournal();

  /// Run one background scan on behalf of [trigger].
  ///
  /// Acquires the Hive isolate lock, checks the cross-trigger cooldown,
  /// runs the full scan body, and stamps the dedup record on completion.
  /// Returns `true` when a scan actually ran, `false` when it was skipped
  /// (lock contention or cooldown).
  ///
  /// Every failure is caught and routed through `errorLogger` (which spools
  /// via the isolate error spool when unbound, #3150) for the
  /// foreground TraceRecorder; the call returns `false` rather than
  /// propagating, so a flaky network or storage fault can't crash the OS-
  /// spawned background isolate. The whole body is wrapped in
  /// try/catch/finally so the lock is always released and the Hive boxes
  /// always closed.
  ///
  /// [now] is injectable for tests; defaults to the wall clock.
  Future<bool> scan({
    required BackgroundScanTrigger trigger,
    DateTime? now,
    Duration cooldown = scanCooldown,
  }) async {
    final at = now ?? DateTime.now();
    HiveIsolateLock? lock;
    try {
      lock = await HiveIsolateLock.create();
      final acquired = await lock.acquire();
      if (!acquired) {
        debugPrint(
            'BackgroundAlertScanCoordinator: could not acquire Hive lock '
            '(${trigger.tag}), skipping');
        // #3147 — best-effort: the alerts box is usually NOT open on this
        // path (the lock holder owns it), so the append may no-op; the
        // concurrent holder journals its own completed row.
        await _journal.append(
            at: at, trigger: trigger.tag, skippedReason: 'hive_lock');
        return false;
      }

      await HiveStorage.initInIsolate();

      // Cross-trigger cooldown — read it *after* the lock + box open so the
      // dedup row is consistent with whatever the previous scan wrote.
      final allowed = await _dedup.shouldScan(now: at, cooldown: cooldown);
      if (!allowed) {
        final last = await _dedup.lastScanAt();
        debugPrint(
            'BackgroundAlertScanCoordinator: scan skipped (${trigger.tag}) '
            '— last scan $last is within ${cooldown.inMinutes}m cooldown');
        await _journal.append(
            at: at, trigger: trigger.tag, skippedReason: 'cooldown');
        return false;
      }

      final summary = await _runScanBody(HiveStorage());

      // Stamp completion only after the body finishes so a crash mid-scan
      // leaves the door open for the next trigger to retry.
      await _dedup.recordScan(now: at, trigger: trigger.tag);
      // #3147 — persisted audit row: when, what trigger, how many stations
      // were fetched, how many notifications fired. Rides in the export so
      // "why didn't I get an alert?" is answerable in the field.
      await _journal.append(
        at: at,
        trigger: trigger.tag,
        stationsScanned: summary.stationsScanned,
        alertsFired: summary.alertsFired,
      );
      return true;
    } catch (e, st) {
      // #3150 — single log call. `errorLogger.log` already routes to the
      // IsolateErrorSpool when unbound (background isolate), so the former
      // explicit `IsolateErrorSpool.enqueue` double-logged every scan
      // failure; the bg_scan tag now travels in the context map instead.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'BackgroundAlertScanCoordinator: scan failed (${trigger.tag})',
        'isolateTaskName': 'bg_scan_${trigger.tag}',
      }));
      // #3147 — the error TYPE only (PII-safe), so the journal shows a
      // failed run distinctly from "no scan ran at all".
      await _journal.append(
          at: at, trigger: trigger.tag, error: e.runtimeType.toString());
      return false;
    } finally {
      try {
        await HiveStorage.closeIsolateBoxes();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
          'where': 'BackgroundAlertScanCoordinator: failed to close Hive boxes'
        }));
      }
      lock?.release();
    }
  }

  /// The scan body: fetch prices for favourites + alert stations (plus
  /// once-a-day viewed stations, #2212), record history, evaluate per-
  /// station / velocity / radius alerts, refresh the home widgets. Assumes
  /// Hive is already initialised in this isolate and the lock is held.
  /// Returns the journal counts (#3147): stations with fetched prices +
  /// total notifications fired across the three runners.
  Future<({int stationsScanned, int alertsFired})> _runScanBody(
      HiveStorage storage) async {
    await HiveStorage.loadApiKey();
    final apiKey = storage.getApiKey();

    // #2306 — load the localized notification templates the main isolate
    // stashed at reconcile() time. If absent (e.g. a task that outran the
    // first reconcile, or a storage hiccup) resolve live from the persisted
    // active language code so we still localize, never English.
    final templates = BackgroundNotificationTemplates.tryDecode(
          storage.getSetting(BackgroundNotificationTemplates.storageKey)
              as String?,
        ) ??
        BackgroundNotificationTemplates.resolveForLanguage(
          storage.getSetting('active_language_code') as String?,
        );

    // 1. Build the station-id set to fetch. Favorites + active-alert
    //    stations are always refreshed; #2212 — every previously-viewed
    //    ("collected") station is also gathered ONCE PER DAY so its price
    //    history keeps growing even if it isn't a favorite.
    final now = DateTime.now();
    final favoriteIds = storage.getFavoriteIds();
    final repo = AlertRepository(storage);
    final alerts = repo.getAlerts();
    final alertStationIds =
        alerts.where((a) => a.isActive).map((a) => a.stationId).toSet();
    bool collectedToday(String id) {
      final recs = storage.getPriceRecords(id);
      if (recs.isEmpty) return false;
      final last = DateTime.tryParse(recs.last['recordedAt']?.toString() ?? '');
      return last != null && isSameDay(last, now);
    }

    final allStationIds = stationsToCollect(
      favorites: favoriteIds,
      alerts: alertStationIds.toList(),
      viewed: storage.getPriceHistoryKeys(),
      collectedToday: collectedToday,
    );
    debugPrint('BackgroundAlertScanCoordinator: ${favoriteIds.length} '
        'favorites, ${alertStationIds.length} alert stations, '
        '${allStationIds.length} total (incl. once-a-day viewed)');

    if (allStationIds.isEmpty) {
      // #609 — users without favorites still need a populated nearest widget.
      await _refreshNearestWidgetFromSearch(storage);
      return (stationsScanned: 0, alertsFired: 0);
    }

    // 2. Fetch prices via the registry-driven per-country source (#2862): the
    //    source groups the mixed-country id set by derived country and queries
    //    each polled provider at most once, within its minInterval; a
    //    prefix-less id falls back to the active country. Bulk-dataset
    //    countries (ES/IT/AR/DK) are scanned below (#2863), not here.
    final activeCountry =
        storage.getSetting('active_country_code') as String? ?? 'DE';

    // #2866 EXIT GATE: the shared per-provider budget (foreground + background
    // share one minInterval gate; skip a provider the foreground just hit) +
    // the dev-gated #2824 tracer (count + export the multi-country scan's
    // traffic, compliant per provider). Both threaded into every service built.
    final budget = ProviderRequestBudget(storage);
    final tracer = BackgroundScanTracer.forScan();

    final source = BackgroundPriceSource(
      storage: storage,
      connectTimeout: bgConnectTimeout,
      receiveTimeout: bgReceiveTimeout,
      recorder: tracer.recorder,
      budget: budget,
    );
    final prices = await source.fetchPricesGrouped(
      stationIds: allStationIds,
      fallbackCountryCode: activeCountry,
      apiKey: apiKey,
    );

    // #2863 — bulk-dataset countries (ES/IT/AR/DK + flag-gated FR/GB) flow
    // through a [BulkDatasetAlertStrategy] resolved per country: ≤1 dataset
    // download per scan (per datasetTtl) then local-filter, merged into the
    // same Tankerkönig-shaped map the evaluator consumes. (Radius alerts in
    // bulk countries run below via the strategy-aware runRadiusAlerts.)
    final resolver = CountryAlertStrategyResolver(
      storage: storage,
      cache: CacheManager(storage),
      apiKey: apiKey,
      recorder: tracer.recorder,
      budget: budget,
    );
    prices.addAll(await fetchBulkAlertPrices(
      alertStationIds: alertStationIds,
      fallbackCountryCode: activeCountry,
      resolver: resolver,
    ));

    debugPrint('BackgroundAlertScanCoordinator: fetched prices for '
        '${prices.length} stations');

    if (prices.isNotEmpty) {
      await BackgroundPriceHistoryWriter.recordHistory(storage, prices, now);
      await BackgroundPriceHistoryWriter.updateCachedStations(storage, prices);
    }

    var alertsFired = await BackgroundScanRunners.runPerStationAlerts(
      repo: repo,
      alerts: alerts,
      prices: prices,
      now: now,
      templates: templates,
      fallbackCountryCode: activeCountry,
    );

    if (prices.isNotEmpty) {
      alertsFired += await BackgroundScanRunners.runVelocity(
        storage: storage,
        prices: prices,
        now: now,
        templates: templates,
        fallbackCountryCode: activeCountry,
      );
    }

    alertsFired += await BackgroundScanRunners.runRadiusAlerts(
      now: now,
      resolver: resolver,
      templates: templates,
    );

    await HomeWidgetService.updateWidget(
      storage,
      profileStorage: storage,
      settingsStorage: storage,
    );
    await _refreshNearestWidgetFromSearch(storage, source: source);

    // #2866 — dev-gated: snapshot + export this scan's data-access trace so the
    // maintainer reads `aggregates().compliant` per provider (no-op otherwise).
    await tracer.exportIfEnabled();

    return (stationsScanned: prices.length, alertsFired: alertsFired);
  }

  /// #609 — nearest-widget refresh from a real search (or legacy fallback).
  ///
  /// #2862 — the nearest-widget search now goes through the registry-driven
  /// [BackgroundPriceSource] for the active country instead of a hardcoded
  /// Tankerkönig service, so a non-DE user's widget shows nearby stations
  /// from their own country's provider. A [source] is reused when the scan
  /// body already built one (so its per-country services are shared); the
  /// empty-favorites early-return builds a throwaway one.
  Future<void> _refreshNearestWidgetFromSearch(
    HiveStorage storage, {
    BackgroundPriceSource? source,
  }) async {
    try {
      final apiKey = storage.getApiKey();
      final activeCountry =
          storage.getSetting('active_country_code') as String? ?? 'DE';
      final priceSource = source ??
          BackgroundPriceSource(
            storage: storage,
            connectTimeout: bgConnectTimeout,
            receiveTimeout: bgReceiveTimeout,
          );
      final service =
          priceSource.serviceFor(activeCountry, apiKey: apiKey);
      // A null service means the active country is not a polled provider
      // (e.g. a bulk-dataset country — child #2863) or has no configured key;
      // fall back to the cache-only nearest-widget path.
      await HomeWidgetService.updateNearestWidget(
        storage,
        storage,
        profileStorage: storage,
        stationService: service,
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'BackgroundAlertScanCoordinator: nearest widget refresh failed'
      }));
    }
  }
}
