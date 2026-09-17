// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What one background scan DOES, in the stages its coordinator sequences
/// (#4162).
///
/// `BackgroundAlertScanCoordinator` used to run all of this as one private
/// method, so the only thing a test could observe was "the scan returned".
/// Split into the stages [ScanRunPhase] names, the coordinator advances
/// its phase between them — it stays the single owner of the run's state
/// — and a test can substitute a body that parks, throws or notifies at an
/// exact stage without standing up eight country providers.
///
/// The code is moved, not changed, with one exception the lifecycle work
/// asked for: the body reads the scan's own instant [at] instead of
/// reading the wall clock a second time, so a scan driven at an injected
/// time is consistent end to end.
library;

import '../../../core/background/scan_run_phase.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/background/provider_request_budget.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/hive_storage.dart';
import '../../widget/api.dart';
import '../data/models/price_alert.dart';
import '../data/repositories/alert_repository.dart';
import 'background_price_history_writer.dart';
import 'background_price_source.dart';
import 'background_scan_tracer.dart';
import 'bulk_alert_price_merge.dart';
import 'country_alert_strategy_resolver.dart';
import 'daily_collection.dart';
import 'notification_templates.dart';
import 'scan_opportunity_dispatch.dart';

/// One scan's stages. Built per run by the coordinator's body factory.
///
/// Stage order is the coordinator's business: [collect], then [dispatch]
/// unless [isEmpty], then [refreshWidgets]. A stage may throw; the
/// coordinator records `failed` and releases the lock.
abstract interface class ScanBody {
  /// [ScanRunPhase.collecting] — resolve the station set, fetch prices,
  /// write history.
  Future<void> collect();

  /// Whether [collect] found no station to fetch. The run then skips
  /// [dispatch] (#609: the nearest widget still refreshes).
  bool get isEmpty;

  /// Stations with fetched prices — the journal's `stations` count.
  int get stationsScanned;

  /// [ScanRunPhase.dispatching] — detect, budget, notify, record. Returns
  /// how many notifications went out (at most one, #4183).
  Future<int> dispatch(Future<NotificationService> Function() notifier);

  /// [ScanRunPhase.refreshingWidgets] — the home widgets.
  Future<void> refreshWidgets();
}

/// The production [ScanBody] (#2415, #2862, #2863, #4183).
class BackgroundScanBody implements ScanBody {
  BackgroundScanBody(this.storage, this.at);

  final HiveStorage storage;

  /// The scan's instant — the one `scan(now:)` was given.
  final DateTime at;

  /// Connect / receive timeouts for the BG-isolate Dio client.
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);

  String? _apiKey;
  late BackgroundNotificationTemplates _templates;
  late AlertRepository _repo;
  List<PriceAlert> _alerts = const [];
  Set<String> _alertStationIds = const {};
  bool _empty = true;
  String _activeCountry = 'DE';
  Map<String, Map<String, dynamic>> _prices = {};
  BackgroundPriceSource? _source;
  CountryAlertStrategyResolver? _resolver;
  BackgroundScanTracer? _tracer;

  @override
  bool get isEmpty => _empty;

  @override
  int get stationsScanned => _prices.length;

  @override
  Future<void> collect() async {
    await HiveStorage.loadApiKey();
    // #3746 — the threaded key only builds the DE Tankerkönig Dio; every
    // other country's polled strategy reads its own slot via `storage`.
    _apiKey = storage.getApiKey('de');

    // #2306 — load the localized notification templates the main isolate
    // stashed at reconcile() time. If absent (e.g. a task that outran the
    // first reconcile, or a storage hiccup) resolve live from the persisted
    // active language code so we still localize, never English.
    _templates = BackgroundNotificationTemplates.tryDecode(
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
    final favoriteIds = storage.getFavoriteIds();
    _repo = AlertRepository(storage);
    _alerts = _repo.getAlerts();
    _alertStationIds =
        _alerts.where((a) => a.isActive).map((a) => a.stationId).toSet();
    bool collectedToday(String id) {
      final recs = storage.getPriceRecords(id);
      if (recs.isEmpty) return false;
      final last = DateTime.tryParse(recs.last['recordedAt']?.toString() ?? '');
      return last != null && isSameDay(last, at);
    }

    final allStationIds = stationsToCollect(
      favorites: favoriteIds,
      alerts: _alertStationIds.toList(),
      viewed: storage.getPriceHistoryKeys(),
      collectedToday: collectedToday,
    );
    log.debug(
        '${favoriteIds.length} favorites, ${_alertStationIds.length} alert '
        'stations, ${allStationIds.length} total (incl. once-a-day viewed)',
        tag: 'BackgroundScanBody');

    _empty = allStationIds.isEmpty;
    if (_empty) return;

    // 2. Fetch prices via the registry-driven per-country source (#2862): the
    //    source groups the mixed-country id set by derived country and queries
    //    each polled provider at most once, within its minInterval; a
    //    prefix-less id falls back to the active country. Bulk-dataset
    //    countries (ES/IT/AR/DK) are scanned below (#2863), not here.
    _activeCountry =
        storage.getSetting('active_country_code') as String? ?? 'DE';

    // #2866 EXIT GATE: the shared per-provider budget (foreground + background
    // share one minInterval gate; skip a provider the foreground just hit) +
    // the dev-gated #2824 tracer (count + export the multi-country scan's
    // traffic, compliant per provider). Both threaded into every service built.
    final budget = ProviderRequestBudget(storage);
    final tracer = _tracer = BackgroundScanTracer.forScan();

    final source = _source = BackgroundPriceSource(
      storage: storage,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      recorder: tracer.recorder,
      budget: budget,
    );
    _prices = await source.fetchPricesGrouped(
      stationIds: allStationIds,
      fallbackCountryCode: _activeCountry,
      apiKey: _apiKey,
    );

    // #2863 — bulk-dataset countries (ES/IT/AR/DK + flag-gated FR/GB) flow
    // through a [BulkDatasetAlertStrategy] resolved per country: ≤1 dataset
    // download per scan (per datasetTtl) then local-filter, merged into the
    // same Tankerkönig-shaped map the evaluator consumes. (Radius alerts in
    // bulk countries run below via the strategy-aware runRadiusAlerts.)
    final resolver = _resolver = CountryAlertStrategyResolver(
      storage: storage,
      cache: CacheManager(storage),
      apiKey: _apiKey,
      recorder: tracer.recorder,
      budget: budget,
    );
    _prices.addAll(await fetchBulkAlertPrices(
      alertStationIds: _alertStationIds,
      fallbackCountryCode: _activeCountry,
      resolver: resolver,
    ));

    log.debug('fetched prices for ${_prices.length} stations',
        tag: 'BackgroundScanBody');

    if (_prices.isNotEmpty) {
      await BackgroundPriceHistoryWriter.recordHistory(storage, _prices, at);
      await BackgroundPriceHistoryWriter.updateCachedStations(storage, _prices);
    }
  }

  @override
  Future<int> dispatch(Future<NotificationService> Function() notifier) =>
      // #4183 — the three paths DETECT; one dispatcher decides. See
      // `scan_opportunity_dispatch.dart` for what that replaced.
      detectAndDispatch(
        repo: _repo,
        alerts: _alerts,
        prices: _prices,
        now: at,
        templates: _templates,
        storage: storage,
        resolver: _resolver!,
        activeCountry: _activeCountry,
        notifier: notifier,
      );

  @override
  Future<void> refreshWidgets() async {
    if (_empty) {
      // #609 — users without favorites still need a populated nearest widget.
      await _refreshNearestWidgetFromSearch();
      return;
    }
    await HomeWidgetService.updateWidget(
      storage,
      profileStorage: storage,
      settingsStorage: storage,
    );
    await _refreshNearestWidgetFromSearch(source: _source);

    // #2866 — dev-gated: snapshot + export this scan's data-access trace so the
    // maintainer reads `aggregates().compliant` per provider (no-op otherwise).
    await _tracer?.exportIfEnabled();
  }

  /// #609 — nearest-widget refresh from a real search (or legacy fallback).
  ///
  /// #2862 — the nearest-widget search goes through the registry-driven
  /// [BackgroundPriceSource] for the active country instead of a hardcoded
  /// Tankerkönig service, so a non-DE user's widget shows nearby stations
  /// from their own country's provider. A [source] is reused when the scan
  /// body already built one (so its per-country services are shared); the
  /// empty-favorites path builds a throwaway one.
  Future<void> _refreshNearestWidgetFromSearch({
    BackgroundPriceSource? source,
  }) async {
    try {
      final apiKey = storage.getApiKey('de'); // #3746 — DE Dio key only.
      final activeCountry =
          storage.getSetting('active_country_code') as String? ?? 'DE';
      final priceSource = source ??
          BackgroundPriceSource(
            storage: storage,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
          );
      final service = priceSource.serviceFor(activeCountry, apiKey: apiKey);
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
      log.error(e, st, layer: ErrorLayer.other, context: const {
        'where': 'BackgroundScanBody: nearest widget refresh failed'
      });
    }
  }
}
