// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../features/alerts/background/background_service.dart';
import '../core/constants/app_constants.dart';
import '../core/cache/cache_manager.dart';
import '../core/telemetry/collectors/breadcrumb_persistence.dart';
import '../core/telemetry/crash_forensics_harvester.dart';
import '../core/platform/app_flavor.dart';
import '../core/privacy/consent_enforcement.dart';
import '../core/telemetry/collectors/breadcrumb_collector.dart';
import '../core/telemetry/health_counters.dart';
import '../core/telemetry/storage/startup_failure_store.dart';
import '../core/telemetry/storage/trace_storage.dart';
import '../core/logging/app_log.dart';
import '../core/logging/error_log_denoise.dart';
import '../core/logging/error_logger.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/perf/launch_sync_trace.dart';
import '../core/perf/startup_timer.dart';
import '../core/services/country_service_registry.dart';
import '../core/storage/hive_boxes.dart';
import '../core/storage/hive_storage.dart';
import '../core/sync/community_config.dart';
import '../core/sync/supabase_client.dart';
import '../core/sync/sync_run_trace.dart';
import '../core/sync/tanksync_init.dart';
import '../core/telemetry/pii_scrubber.dart';
import '../core/utils/edge_to_edge.dart';
import '../features/obd2/data/obd2_connect_trace_persistence.dart';
import '../features/feature_management/application/legacy_toggle_migration_provider.dart';
import '../features/price_history/data/repositories/price_history_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/widget/data/home_widget_service.dart';
import '../features/widget/providers/pending_widget_uri_provider.dart';
import 'profile_language_binding.dart';
import 'startup/launch_sync_phase.dart';
import 'startup/provider_warmup_phase.dart';
import 'startup/telemetry_replay_phase.dart';
import 'startup/trip_recovery_phase.dart';
import 'widgets/storage_recovery_screen.dart';

part 'app_initializer_boot_support.dart';
part 'app_initializer_deferred_tasks.dart';

/// Drives the cold-start sequence in well-defined phases: **bootstrap** →
/// **storage** → **services** (parallel) → **optional deferred**
/// (post-first-frame) → **runApp**. Full phase narrative + #3139 notes:
/// atop `app_initializer_deferred_tasks.dart` (`part`, move-only #3761).
///
/// This library stays the single ordering authority: every phase's slot
/// and the scheduling (pre-Zone / post-bind / post-first-frame placement)
/// live only here. The #3149 storage catch-all stays inline in [run]
/// because it must execute BEFORE `_launch` installs the global handlers
/// — there is no Zone handler yet at that point.
class AppInitializer {
  AppInitializer._();

  /// Runs the full cold-start sequence; the *only* thing `main()` calls.
  static Future<void> run({
    required Widget Function(ProviderContainer container) appBuilder,
  }) async {
    StartupTimer.instance.start();

    _bootstrap();
    StartupTimer.instance.mark('binding');

    // #2978 — load `intl` locale date-symbols so `DateFormat.EEEE` works
    // for non-`en_US` locales instead of throwing `LocaleDataException`.
    await initializeDateFormatting();

    // #2294 — a Hive box damaged beyond crash recovery throws a
    // HiveCorruptionException out of the storage phase; #3149 widened the
    // net to ANY storage-phase fault. Both previously escaped uncaught —
    // no Zone handler exists yet (handlers install only in `_launch`) —
    // freezing the splash with no message and no telemetry. Surface a
    // localized recovery screen and route the exception through
    // errorLogger; startup cannot continue without local storage.
    try {
      await _initStorage();
    } on HiveCorruptionException catch (e, st) {
      // #3149 — Hive is down (spool can't write); plain-file the cause.
      await StartupFailureStore.persist(e, st);
      unawaited(errorLogger.log(ErrorLayer.storage, e, st));
      // #3272 — bare scope (missing_provider_scope); reads no providers.
      runApp(const ProviderScope(child: StorageRecoveryHost()));
      return;
    } catch (e, st) {
      // #3149 — any OTHER storage-phase fault (secure-storage cipher,
      // TraceStorage, loadApiKey…) previously escaped uncaught — no Zone
      // handler exists yet — freezing the splash with zero telemetry.
      await StartupFailureStore.persist(e, st);
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'initStorage'}));
      runApp(const ProviderScope(child: StorageRecoveryHost()));
      return;
    }
    StartupTimer.instance.mark('storage_ready');

    await _initServicesInParallel();
    StartupTimer.instance.mark('services_init');

    final container = createContainer();

    final storage = HiveStorage();

    // #1794/#1768 — post-first-frame storage work: deep-box opens
    // (idempotent + cached; later post-frame readers await the same
    // opens), #2264 bounded cache eviction (#3610 records the yield),
    // the #2317 price-history retention trim, profile migrations.
    _deferPostFirstFrame(() async {
      unawaited(HiveBoxes.initDeferred());
      final evicted = await CacheManager(storage).evictBounded();
      if (evicted > 0) {
        healthCounters.increment('cache.evicted', by: evicted);
      }
      await PriceHistoryRepository(storage).evictOldRecords();
      await _migrateProfilesDeferred(storage);
    });

    // #795 phase 1 — defer Supabase/TankSync warm-up and community-config
    // asset read past the first frame. Call sites stay here (non-awaited)
    // so structural ordering tests pinning `services < tankSync < launch`
    // keep passing; the sequence body lives in [_runDeferredLaunchSync].
    _deferPostFirstFrame(() async {
      await CommunityConfig.load();
      await _runDeferredLaunchSync(container, storage,
          initTankSync: _maybeInitTankSync);
    });

    // #570 — cache the runtime version post-frame (About screen reads it).
    _deferPostFirstFrame(_cacheRuntimeVersion);

    // #950 phase 4 — one-shot `referenceVehicleId` catalog backfill.
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.migrateVehicleCatalog(container, storage));

    // #1373 phase 3a/3b/3e/3f — legacy-toggle migration kick-off; reading
    // `.future` triggers the build (keepAlive + idempotent no-op re-fire).
    // Non-awaited, non-fatal — see `legacyToggleMigrationProvider`.
    _deferPostFirstFrame(() async {
      try {
        unawaited(container.read(legacyToggleMigrationProvider.future));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.background, e, st,
            context: {'where': 'legacyToggleMigration kick-off'}));
      }
    });

    // #3580 crash forensics + the #1858/#1925/#2465 provider warm-ups —
    // four post-frame registrations, in order (see the part file).
    _schedulePostFrameWarmups(container);

    // Eagerly resolve the home-widget cold-launch URI BEFORE the router
    // builds (#widget-deeplink); 200 ms cap — see [_stashWidgetLaunchUri].
    await _stashWidgetLaunchUri(container);
    StartupTimer.instance.mark('widget_launch_probe');

    StartupTimer.instance.mark('pre_run_app');

    // #1769 — Sentry no longer wraps `runApp`: the app paints first,
    // Sentry initialises post-first-frame (it only needs to be live
    // before an error is *reported*); `_installErrorHandlers` re-runs so
    // `errorLogger` stays authoritative. #3492 — libre/F-Droid ships NO
    // Sentry SDK; `AppFlavor.isLibre` is const so R8 folds the block out.
    // #3870 — mirror the tile-proxy switch before the first map paints.
    AppConstants.tileProxyDisabledByUser =
        !(storage.getSetting('tile_proxy_enabled') as bool? ?? true);
    final dsn = resolveSentryDsn(storage);
    final consentGiven =
        storage.getSetting('consent_error_reporting') as bool? ?? false;
    if (!AppFlavor.isLibre && dsn.isNotEmpty && consentGiven) {
      _deferPostFirstFrame(() => _startSentry(dsn));
    }
    // #3866 (Epic #3865) — withdrawing the Error reporting consent closes
    // Sentry in-session; granting it starts the SDK without a relaunch.
    if (!AppFlavor.isLibre && dsn.isNotEmpty) {
      ConsentEnforcement.errorReportingHook = (enabled) async {
        if (enabled) {
          if (!Sentry.isEnabled) await _startSentry(dsn);
        } else if (Sentry.isEnabled) {
          await Sentry.close();
        }
      };
    }

    _launch(container, appBuilder);
  }

  /// Builds the app's ONE root [ProviderContainer] — the production
  /// composition root (#3738). Every cross-boundary container override
  /// belongs here: `run()` used to build a bare `ProviderContainer()`,
  /// leaving the #3134 profile-language bridge overrides uninstalled.
  /// [overrides] lets the composition-root test append fakes after the
  /// real seams; production callers pass none.
  static ProviderContainer createContainer({
    List<Override> overrides = const [],
  }) =>
      ProviderContainer(
        overrides: [...profileLanguageOverrides(), ...overrides],
      );

  /// Resolves the active Sentry DSN at startup. The user-stored
  /// `sentry_dsn` setting always wins, otherwise the build-time
  /// `SENTRY_DSN` dart-define; empty string when neither is configured —
  /// callers must check `dsn.isNotEmpty` (#476). Exposed for unit tests.
  static String resolveSentryDsn(HiveStorage storage) {
    final stored = storage.getSetting('sentry_dsn') as String?;
    if (stored != null && stored.isNotEmpty) return stored;
    const buildDsn = String.fromEnvironment('SENTRY_DSN');
    return buildDsn;
  }

  /// Starts the Sentry SDK against [dsn] and re-installs the error
  /// handlers so `errorLogger` stays authoritative (#1769).
  static Future<void> _startSentry(String dsn) async {
    final packageInfo = await _resolvePackageInfo();
    await SentryFlutter.init(
        (options) => _configureSentryOptions(options, dsn, packageInfo));
    _installErrorHandlers();
  }

  // Phase 2 — storage.

  static Future<void> _initStorage() async {
    await HiveStorage.init();
    StartupTimer.instance.mark('hive_init');

    // #795 phase 1 — API-key load (secure-storage read + legacy Hive
    // settings migration) and trace-storage box-open are independent;
    // `Future.wait` overlaps I/O waits that used to be sequential.
    await Future.wait<void>([
      HiveStorage.loadApiKey(),
      TraceStorage.init(),
      // #3184 — persisted OBD2 connect-trace ring (own box; best-effort).
      Obd2ConnectTracePersistence.init(),
      HealthCounters.init(), // #3146 — always-on production counters
    ]);

    // Debug-mode country-registry check + the #555 default-profile safety
    // net (critical path — the first route depends on a profile existing).
    await _verifyRegistryAndSeedProfile();
  }

  // Post-first-frame deferral.

  /// Schedules [body] to run *after* Flutter has drawn the first frame
  /// (#795 phase 1) — a post-frame callback, NOT a bare microtask (the
  /// microtask queue can drain *before* the first paint on slow devices).
  /// Errors inside [body] are caught + logged, never crash the app.
  @visibleForTesting
  static void deferPostFirstFrame(Future<void> Function() body) =>
      _deferPostFirstFrame(body);

  static void _deferPostFirstFrame(Future<void> Function() body) {
    Future<void> run() async {
      try {
        await body();
      } catch (e, st) {
        // #3143 — release-visible: debugPrint is no-opped in release.
        unawaited(errorLogger.log(ErrorLayer.background, e, st,
            context: {'where': 'deferPostFirstFrame'}));
      }
    }

    // Non-null once `_bootstrap()` ran `ensureInitialized()`; the work
    // then runs as a microtask off the frame budget.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(run());
    });
  }

  // Phase 3 — services (parallel).

  /// Notifications, background tasks and the home widget initialiser are
  /// independent — parallelised; each future is individually
  /// error-protected so one failing plugin doesn't block the others.
  static Future<void> _initServicesInParallel() async {
    await Future.wait<void>([
      _safe('notifications', LocalNotificationService().initialize),
      _safe('background', _maybeInitBackground),
      _safe('home_widget', HomeWidgetService.init),
    ]);
  }

  /// Schedule periodic price polling only when the user has at least one
  /// active alert (#713 — per Tankerkönig's ToS, requests on demand only).
  /// #2210 — reconcile gates BOTH price and radius alerts. #3169 — a cold
  /// launch also fires an opportunistic scan (an execution window iOS
  /// reliably grants; Android no-ops), cross-trigger-cooldown-gated.
  static Future<void> _maybeInitBackground() async {
    await BackgroundService.reconcile();
    await BackgroundService.onOpportunisticWake();
  }

  // Phase 4 — optional TankSync.

  /// Initialises Supabase if the user has opted in, under a hard 8-second
  /// timeout: a stuck init must not block the first frame. The body —
  /// incl. the #3449 stored-identity guard — lives in [TankSyncInit]; the
  /// deferred launch block reads `lastOutcome` (#3449 relink, #3450 retry).
  static Future<void> _maybeInitTankSync(HiveStorage storage) async {
    try {
      await TankSyncInit.run(storage).timeout(const Duration(seconds: 8));
    } on TimeoutException catch (e, st) {
      // #3143 — proceeding without sync, but record it: a silent init
      // timeout previously looked identical to "sync works" in the field.
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'maybeInitTankSync', 'timeoutSeconds': 8}));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'maybeInitTankSync'}));
    }
  }

  /// Reads the URI carried by the home-widget tap that cold-started the
  /// app (if any) and stashes it in [pendingWidgetUriProvider]. The probe
  /// body (200 ms cap) lives in [_probeWidgetLaunchUri]; the stash
  /// closure keeps the provider read lazy — only fired when a URI exists.
  static Future<void> _stashWidgetLaunchUri(
    ProviderContainer container,
  ) {
    return _probeWidgetLaunchUri(
      stash: (uri) =>
          container.read(pendingWidgetUriProvider.notifier).set(uri),
    );
  }

  // Phase 5 — runApp.

  /// Wires the framework + platform error handlers onto the app's
  /// [errorLogger] pipeline. Called from [_launch], and again right after
  /// the deferred `SentryFlutter.init` (#1769): Sentry chains itself onto
  /// these hooks during init, so re-running keeps the app's `errorLogger`
  /// routing authoritative. Handler bodies live in the part file (#3761).
  static void _installErrorHandlers() {
    // Capture Flutter framework errors (build, layout, paint).
    FlutterError.onError = _onFlutterError;
    // Capture async / platform errors that escape the framework.
    PlatformDispatcher.instance.onError = _onPlatformDispatcherError;
  }

  static void _launch(
    ProviderContainer container,
    Widget Function(ProviderContainer container) appBuilder,
  ) {
    // #1104 — bind the unified errorLogger to this container so every
    // foreground `errorLogger.log(...)` routes through TraceRecorder +
    // Sentry (background isolates spool via IsolateErrorSpool, replayed
    // by TelemetryReplayPhase).
    errorLogger.bind(container);
    _installErrorHandlers();

    // #609 heartbeat, #1004/#1303 trip recoveries, orchestrator start,
    // aggregator hook, isolate-spool drain — in order (see part file).
    _scheduleLaunchDeferredPhases(container);

    // #3149 — replay a previous bricked launch's plain-file cause record
    // into the trace pipeline, so the frozen splash finally has a why.
    _deferPostFirstFrame(() async {
      final failure = await StartupFailureStore.drain();
      if (failure == null) return;
      await errorLogger.log(
        ErrorLayer.storage,
        Exception('previous launch bricked during startup: '
            '${failure['errorType']}: ${failure['error']}'),
        StackTrace.fromString(failure['stack'] as String? ?? ''),
        context: {'where': 'startupFailureReplay', 'at': failure['at']},
      );
    });

    StartupTimer.instance.mark('first_frame');
    StartupTimer.instance.finish();
    // #2320 — surface the cold-start total as a trace breadcrumb (finish()
    // only prints under kDebugMode; breadcrumbs ride every error trace).
    final totalMs = StartupTimer.instance.totalMs;
    if (totalMs != null) {
      BreadcrumbCollector.add('startup', detail: '${totalMs}ms');
    }
    // #3272 — UncontrolledProviderScope IS the root scope (bootstrap-owned).
    // ignore: missing_provider_scope
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: appBuilder(container),
      ),
    );
  }
}
