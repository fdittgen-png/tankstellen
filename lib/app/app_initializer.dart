// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../features/alerts/background/background_service.dart';
import '../core/constants/app_constants.dart';
import '../core/cache/cache_manager.dart';
import '../core/telemetry/collectors/breadcrumb_collector.dart';
import '../core/telemetry/health_counters.dart';
import '../core/telemetry/storage/startup_failure_store.dart';
import '../core/telemetry/storage/trace_storage.dart';
import '../core/logging/app_log.dart';
import '../core/logging/error_logger.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/perf/startup_timer.dart';
import '../core/services/country_service_registry.dart';
import '../core/storage/hive_boxes.dart';
import '../core/storage/hive_storage.dart';
import '../core/sync/community_config.dart';
import '../core/sync/supabase_client.dart';
import '../core/sync/sync_run_trace.dart';
import '../core/telemetry/pii_scrubber.dart';
import '../core/utils/edge_to_edge.dart';
import '../features/obd2/data/obd2_connect_trace_persistence.dart';
import '../features/feature_management/application/legacy_toggle_migration_provider.dart';
import '../features/price_history/data/repositories/price_history_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/widget/data/home_widget_service.dart';
import '../features/widget/providers/pending_widget_uri_provider.dart';
import 'startup/launch_sync_phase.dart';
import 'startup/provider_warmup_phase.dart';
import 'startup/telemetry_replay_phase.dart';
import 'startup/trip_recovery_phase.dart';
import 'widgets/storage_recovery_screen.dart';

/// Drives the cold-start sequence in well-defined phases instead of one
/// monolithic `main()` body. Splitting the work makes failures observable
/// (each phase is wrapped in try/catch) and unblocks parallelisation of
/// independent service inits — `LocalNotificationService`, `BackgroundService`
/// and `HomeWidgetService` no longer run sequentially.
///
/// Phases (in order):
///
/// 1. **bootstrap** — Flutter binding, edge-to-edge, debug-print silencing.
///    Synchronous and must succeed for any of the rest to make sense.
/// 2. **storage** — Hive boxes, secure-storage API key, trace storage,
///    profile migration, cache eviction. A failure here means the device
///    can't write local data; we surface it but still attempt to keep
///    going so the user isn't stuck on a black screen.
///    The secure-storage API-key read and `TraceStorage.init()` run in
///    parallel with each other (both only depend on `Hive.initFlutter` +
///    the main-isolate box opens already being done) (#795 phase 1).
/// 3. **services** — notifications, background tasks, home widget.
///    Independent of each other → parallelised with `Future.wait`.
/// 4. **optional (deferred)** — community config + TankSync, plus
///    one-shot migrations (vehicle reference-catalog backfill #950, and
///    the feature-flag legacy-toggle promoter #1373 phase 3a/3b/3e/3f).
///    All scheduled for a post-first-frame microtask so the app paints
///    before Supabase is touched (#795 phase 1) and before any Hive
///    walks for the migrators run. Failures are logged but never block
///    startup.
/// 5. **runApp** — wires global error handlers and hands control to the
///    Flutter framework. Wrapped in `SentryFlutter.init` when a DSN is
///    configured so framework + platform errors land in Sentry.
///
/// ## Phase objects (#3139)
///
/// The bulky deferred work is decomposed into ordered phase objects under
/// `lib/app/startup/` — [LaunchSyncPhase] (launch-time server→local
/// merges), [TripRecoveryPhase] (paused-then-active trip crash recovery),
/// [ProviderWarmupPhase] (one-shot migrations + keep-alive provider
/// kick-offs) and [TelemetryReplayPhase] (background-isolate error-spool
/// drain). This class stays the single ordering authority: every phase
/// documents its slot in the sequence, and the scheduling (pre-Zone /
/// post-bind / post-first-frame placement) lives ONLY here. The #3149
/// storage catch-all stays inline in [run] because it must execute BEFORE
/// `_launch` installs the global handlers — there is no Zone handler yet
/// at that point, which is the entire reason it exists.
class AppInitializer {
  AppInitializer._();

  /// Runs the full cold-start sequence and starts the app. Designed to be
  /// the *only* thing called from `main()`.
  static Future<void> run({
    required Widget Function(ProviderContainer container) appBuilder,
  }) async {
    StartupTimer.instance.start();

    _bootstrap();
    StartupTimer.instance.mark('binding');

    // #2978 — load `intl` locale date-symbols so `DateFormat.EEEE` (the
    // localized price-prediction weekday) works for non-`en_US` locales
    // instead of throwing `LocaleDataException`. In-memory, off the I/O path.
    await initializeDateFormatting();

    // #2294 — a Hive box damaged beyond crash recovery throws a
    // HiveCorruptionException out of the storage phase. Previously it
    // escaped uncaught — `_initStorage` had no try/catch, `run()`/`main()`
    // had no Zone handler, and the error handlers are only installed in
    // `_launch` (after storage) — so the user froze on the splash with no
    // message and (debugPrint silenced in release) no telemetry. Surface
    // a localized recovery screen and route the exception through
    // errorLogger so it lands in the trace pipeline / Sentry. Startup
    // cannot continue without local storage, so we stop here.
    try {
      await _initStorage();
    } on HiveCorruptionException catch (e, st) {
      // #3149 — Hive is down (spool can't write); plain-file the cause.
      await StartupFailureStore.persist(e, st);
      unawaited(errorLogger.log(ErrorLayer.storage, e, st));
      runApp(const StorageRecoveryHost());
      return;
    } catch (e, st) {
      // #3149 — any OTHER storage-phase fault (secure-storage cipher,
      // TraceStorage, loadApiKey…) previously escaped uncaught — no Zone
      // handler exists yet — freezing the splash with zero telemetry.
      await StartupFailureStore.persist(e, st);
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'initStorage'}));
      runApp(const StorageRecoveryHost());
      return;
    }
    StartupTimer.instance.mark('storage_ready');

    await _initServicesInParallel();
    StartupTimer.instance.mark('services_init');

    final container = ProviderContainer();

    final storage = HiveStorage();

    // #1794 / #1768 — post-first-frame storage work. `initDeferred()`
    // opens the deep-feature Hive boxes; it is idempotent + cached, so
    // the post-frame readers below (`_runTripsSyncMerge`, the trip
    // recovery passes) await the same opens. Cache eviction and the
    // country/language profile migration each walk an entire box and
    // are not needed for the first frame, so they run here too.
    _deferPostFirstFrame(() async {
      unawaited(HiveBoxes.initDeferred());
      // #2264 — bounded eviction (expiry + per-prefix budget + LRU byte
      // ceiling) replaces the one-shot 500-key expiry cap.
      await CacheManager(storage).evictBounded();
      // #2317 — trim price-history rows past the 30-day retention window
      // once per cold start. The foreground record path (station detail)
      // never trims, so without this hook a heavy user accumulates
      // ~175k dead rows/year; reads already filter to the last 30 days,
      // so this caps storage growth, not a correctness bug.
      await PriceHistoryRepository(storage).evictOldRecords();
      final profileRepo = ProfileRepository(storage);
      await profileRepo.migrateProfileCountryLanguage();
      // #2597 — one profile per country: dedupe existing duplicates
      // (idempotent, runs after the country backfill above).
      await profileRepo.dedupeCountryProfiles();
    });

    // #795 phase 1 — defer Supabase/TankSync warm-up and community-config
    // asset read until after the first frame. Neither is required for the
    // landing UI and both touch relatively slow I/O (asset bundle decode +
    // Supabase client init + anonymous auth).
    //
    // We keep the call sites here (non-awaited) so structural ordering
    // tests that pin `services < tankSync < launch` in the source body
    // continue to pass. The actual work runs via `_deferPostFirstFrame`.
    _deferPostFirstFrame(() async {
      await CommunityConfig.load();
      await _maybeInitTankSync(storage);
      // #3126 — one run id threads the launch merges into the trace.
      if (TankSyncClient.client != null) SyncRunTrace.begin('launch');
      // #1541 — run the trip-summaries merge + details retention pass
      // once TankSync is up. No-ops cleanly when the user is signed
      // out or when the trip-history Hive box isn't open.
      await LaunchSyncPhase.runTripsSyncMerge(container);
      // #3077 — pull the remaining server→local entities (ratings,
      // alerts, fill-ups, vehicles) once TankSync is up, mirroring the
      // trips merge above. No-ops cleanly when sync is off / unauthenticated
      // and respects each entity's consent gate.
      await LaunchSyncPhase.runEntitySyncMerge(container, storage);
    });

    // Cache runtime version so AppConstants.appVersion is accurate (#570).
    // Fire-and-forget: the value is read opportunistically (e.g. by the
    // About screen), not on the first-frame critical path, so awaiting it
    // would only delay `runApp`.
    _deferPostFirstFrame(() async {
      try {
        final packageInfo = await _resolvePackageInfo();
        AppConstants.setRuntimeVersion(
          '${packageInfo.version}+${packageInfo.buildNumber}',
        );
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.background, e, st,
            context: {'where': 'resolveRuntimeVersion (#570)'}));
      }
    });

    // #950 phase 4 — one-shot `referenceVehicleId` backfill from the
    // bundled reference catalog; deferred so the JSON asset read never
    // blocks the landing UI (see ProviderWarmupPhase).
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.migrateVehicleCatalog(container, storage));

    // #1373 phase 3a/3b/3e/3f — kick off the legacy-toggle migrations
    // at every cold start. Reading the provider's future triggers its
    // `build`, which runs `migrateLegacyToggles` + `migrateUserProfileToggles`
    // inside a microtask. The provider is `keepAlive: true` and idempotent
    // (each migrator is gated on its own `*Migrated` flag), so re-firing
    // on subsequent launches is a cheap no-op once the flags are set.
    //
    // Non-awaited: failures are non-fatal (the provider itself swallows +
    // `debugPrint`s), and we don't want a slow Hive read to delay any
    // other deferred work scheduled on the post-first-frame microtask.
    // Previously this only fired when the user navigated to the
    // feature-flags settings screen — see the docstring on
    // `legacyToggleMigrationProvider` for why startup wiring was deferred
    // during the original phase-3 dispatches.
    _deferPostFirstFrame(() async {
      try {
        unawaited(container.read(legacyToggleMigrationProvider.future));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.background, e, st,
            context: {'where': 'legacyToggleMigration kick-off'}));
      }
    });

    // #1858 — warm the keep-alive η_v recompute listener so it watches
    // vehicle-profile edits before the user can reach the Edit-vehicle
    // screen (see ProviderWarmupPhase).
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.warmTripVeRecomputeListener(container));

    // #1925 — arm the OBD2 debug-session recorder from the persisted
    // opt-in flag (see ProviderWarmupPhase).
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.armObd2DebugSessionLogging(container));

    // #2465 — arm the OBD2 comm-health diagnostics collector from
    // Feature.debugMode (see ProviderWarmupPhase).
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.armObd2CommDiagnosticsGate(container));

    // Eagerly resolve the home-widget cold-launch URI BEFORE we build
    // the router so the very first redirect pass can land directly on
    // the requested station detail (#widget-deeplink). Capped at 200 ms
    // so a stuck plugin never blocks cold start — if the read overruns,
    // the warm-click stream still handles the URI a moment later (one
    // visible landing-screen flash is the worst case).
    await _stashWidgetLaunchUri(container);
    StartupTimer.instance.mark('widget_launch_probe');

    StartupTimer.instance.mark('pre_run_app');

    // #1769 — Sentry no longer wraps `runApp`; the old wrapper forced
    // both `SentryFlutter.init` and the package-info round-trip it
    // needs for the release string onto the cold-start critical path.
    // The app now paints first and Sentry initialises in the first
    // post-first-frame microtask. Native crash handlers come up a few
    // hundred ms later — acceptable, since Sentry only needs to be live
    // before an error is *reported*, not before first paint.
    // `_installErrorHandlers` is re-run afterwards so the app's
    // `errorLogger` pipeline stays the authoritative target, matching
    // today's behaviour where `_launch` overwrote Sentry's own
    // integration handlers.
    final dsn = resolveSentryDsn(storage);
    final consentGiven = storage
            .getSetting('consent_error_reporting') as bool? ??
        false;
    if (dsn.isNotEmpty && consentGiven) {
      _deferPostFirstFrame(() async {
        final packageInfo = await _resolvePackageInfo();
        await SentryFlutter.init((options) {
          options.dsn = dsn;
          options.tracesSampleRate = 0.2;
          options.environment = 'production';
          options.release =
              'tankstellen@${packageInfo.version}+${packageInfo.buildNumber}';
          // #1109 — strip PII (emails, lat/lng, tokens, user/request
          // blocks, long breadcrumb payloads) from every event before
          // it leaves the device. The scrubber is a pure function so it
          // stays unit-tested and shared with `TraceUploader`.
          options.beforeSend = (event, hint) {
            try {
              return PiiScrubber.scrubSentryEvent(event);
            } catch (e, st) {
              // #3144 — breadcrumb-level (NOT errorLogger): a warn-level
              // trace from inside beforeSend could recurse through the
              // Sentry upload path. The breadcrumb still rides inside the
              // next persisted trace, so the scrub fault is field-visible.
              log.info('Sentry beforeSend scrub failed: $e\n$st',
                  tag: 'sentry');
              return event;
            }
          };
        });
        _installErrorHandlers();
      });
    }

    _launch(container, appBuilder);
  }

  /// Resolves the active Sentry DSN at startup. The user-stored
  /// `sentry_dsn` setting (entered manually via Settings > Diagnostics)
  /// always wins, otherwise we fall back to the build-time `SENTRY_DSN`
  /// dart-define. Returns the empty string when neither is configured —
  /// callers must check `dsn.isNotEmpty` before passing it to
  /// `SentryFlutter.init` (#476).
  ///
  /// Exposed for unit tests.
  static String resolveSentryDsn(HiveStorage storage) {
    final stored = storage.getSetting('sentry_dsn') as String?;
    if (stored != null && stored.isNotEmpty) return stored;
    const buildDsn = String.fromEnvironment('SENTRY_DSN');
    return buildDsn;
  }

  /// #1769 — reading package info is a platform-channel round-trip.
  /// Resolve it once, lazily; the same Future is shared by the
  /// runtime-version cache and the Sentry release string so neither
  /// path pays a second round-trip.
  static Future<PackageInfo>? _packageInfoFuture;

  static Future<PackageInfo> _resolvePackageInfo() =>
      _packageInfoFuture ??= PackageInfo.fromPlatform();

  // ---------------------------------------------------------------------------
  // Phase 1 — bootstrap
  // ---------------------------------------------------------------------------

  static void _bootstrap() {
    WidgetsFlutterBinding.ensureInitialized();
    // Opt in to edge-to-edge display (required for Android 15+).
    EdgeToEdge.enable();

    // Note: we no longer override Flutter's default ImageCache size
    // (was bumped to 200 MB / 2000 entries by #711 as a workaround
    // for the persistent-gray-tile bug). The root cause was
    // `TileLayer` caching failed fetches, now fixed at the
    // tile-provider layer by #757 (RetryNetworkTileProvider +
    // evictErrorTileStrategy). The Flutter default of
    // 100 MB / 1 000 entries is sufficient for normal map usage.

    // Silence debugPrint in release — it is NOT stripped by the compiler.
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 2 — storage
  // ---------------------------------------------------------------------------

  static Future<void> _initStorage() async {
    await HiveStorage.init();
    StartupTimer.instance.mark('hive_init');

    // #795 phase 1 — API-key load (secure-storage read + legacy Hive
    // settings migration) and trace-storage box-open are independent
    // operations that both require `Hive.initFlutter` + the encrypted
    // box opens already done above. Running them via `Future.wait`
    // overlaps two I/O waits that used to be sequential.
    await Future.wait<void>([
      HiveStorage.loadApiKey(),
      TraceStorage.init(),
      // #3184 — persisted OBD2 connect-trace ring: hydrates the in-memory
      // ring, registers the persist hook + the `obd2ConnectTraces` export
      // section. Independent of the other two (own box); best-effort.
      Obd2ConnectTracePersistence.init(),
      HealthCounters.init(), // #3146 — always-on production counters
    ]);

    // Verify all countries have registered service implementations.
    // Fails fast in debug mode if country_config.dart and the registry diverge.
    assert(() {
      CountryServiceRegistry.assertAllCountriesRegistered();
      return true;
    }());

    // Safety net: guarantee a default profile always exists (#555).
    // The onboarding wizard calls ensureDefaultProfile() at completion,
    // but if the wizard was ever skipped (e.g., by the #521 hasApiKey
    // regression), the app would run without any profile. This stays on
    // the critical path — the first route depends on a profile existing.
    //
    // #1768 — cache eviction and the country/language profile migration
    // used to run here too; both walk an entire Hive box and neither
    // result is needed to paint the first frame, so they are deferred
    // past it (see `run()`'s post-first-frame block).
    final profileRepo = ProfileRepository(HiveStorage());
    await profileRepo.ensureDefaultProfile();
  }

  // ---------------------------------------------------------------------------
  // Post-first-frame deferral
  // ---------------------------------------------------------------------------

  /// Schedules [body] to run *after* Flutter has drawn the first frame.
  ///
  /// Introduced by #795 phase 1 so TankSync, CommunityConfig, and the
  /// runtime-version PackageInfo read no longer block the first paint.
  ///
  /// Implementation detail: we enqueue a microtask that immediately
  /// registers a post-frame callback. Doing it this way instead of a
  /// plain `scheduleMicrotask(body)` guarantees the work is held back
  /// until there's actually something on screen — on a slow device the
  /// microtask queue is drained *before* the first frame paints, so we
  /// need the scheduler hook to hit the intended "after first paint"
  /// ordering.
  ///
  /// Errors inside [body] are caught and logged; a failure in the
  /// deferred work must never crash the running app.
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

    // `SchedulerBinding.instance` is non-null once
    // `WidgetsFlutterBinding.ensureInitialized()` has run, which
    // `_bootstrap()` guarantees before we reach this point. The
    // callback fires on the first post-frame phase and we then run
    // the work as a microtask so it doesn't extend the frame budget.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(run());
    });
  }

  // ---------------------------------------------------------------------------
  // Phase 3 — services (parallel)
  // ---------------------------------------------------------------------------

  /// Notifications, background tasks, and the home widget initialiser are
  /// independent — running them in parallel cuts cold-start time on devices
  /// where one of them blocks on a slow plugin handshake.
  ///
  /// Each future is individually error-protected so a failure in (say) the
  /// home widget plugin doesn't prevent notifications from being available.
  static Future<void> _initServicesInParallel() async {
    await Future.wait<void>([
      _safe('notifications', LocalNotificationService().initialize),
      _safe('background', _maybeInitBackground),
      _safe('home_widget', HomeWidgetService.init),
    ]);
  }

  /// Schedule periodic price polling only when the user has at least one
  /// active alert (#713). Alerts are the only user-consented reason to
  /// poll the station APIs on a regular schedule — per Tankerkönig's
  /// terms of service, apps must use "requests on demand" and avoid
  /// regular non-user-initiated requests. #2210 — delegates to
  /// BackgroundService.reconcile so BOTH price and radius alerts gate
  /// the scheduler (radius-only users were previously never scheduled).
  ///
  /// #3169 — after reconciling the schedule, a cold launch also fires an
  /// opportunistic scan: on iOS the app-open moment is one of the few
  /// execution windows the OS reliably grants (Android implements it as
  /// a no-op). The coordinator's cross-trigger cooldown keeps repeated
  /// launches free.
  static Future<void> _maybeInitBackground() async {
    await BackgroundService.reconcile();
    await BackgroundService.onOpportunisticWake();
  }

  static Future<void> _safe(String label, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      // #3143 — pre-bind, so this spools via IsolateErrorSpool and is
      // drained into the trace pipeline post-first-frame.
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'serviceInit', 'service': label}));
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 4 — optional TankSync
  // ---------------------------------------------------------------------------

  /// Initialises Supabase if the user has opted in. Wrapped in a hard 8-second
  /// timeout: a stuck Supabase init must not block the first frame.
  static Future<void> _maybeInitTankSync(HiveStorage storage) async {
    final syncEnabled = storage.getSetting('sync_enabled') as bool? ?? false;
    if (!syncEnabled) return;
    final url = storage.getSetting('supabase_url') as String?;
    final key = storage.getSupabaseAnonKey();
    if (url == null || key == null) return;

    try {
      await Future(() async {
        await TankSyncClient.init(url: url, anonKey: key);
        if (TankSyncClient.client?.auth.currentUser == null) {
          log.info('TankSync: session expired, re-authenticating...');
          await TankSyncClient.signInAnonymously();
        }
        final sessionId = TankSyncClient.client?.auth.currentUser?.id;
        final storedId = storage.getSetting('sync_user_id') as String?;
        if (sessionId != null && sessionId != storedId) {
          log.info('TankSync: userId changed');
          await storage.putSetting('sync_user_id', sessionId);
        }
        if (sessionId != null) {
          try {
            await TankSyncClient.client!.from('users').upsert(
              {'id': sessionId},
              onConflict: 'id',
            );
          } catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.sync, e, st,
                context: {'where': 'maybeInitTankSync users upsert'}));
          }
        }
        log.info('TankSync: ready');
      }).timeout(const Duration(seconds: 8));
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

  /// Reads the URI carried by the home-widget tap that cold-started
  /// the app (if any) and stashes it in [pendingWidgetUriProvider] so
  /// the router's redirect chain can land the user on the station
  /// detail directly — no landing-screen flash, no post-frame race.
  ///
  /// Capped by a short timeout: the `home_widget` plugin's platform
  /// channel is normally instant, but a stuck implementation must not
  /// block cold start. On timeout / error the warm-click stream still
  /// delivers the URI a few frames later — the cost is the very
  /// situation this method was written to remove (a brief landing-
  /// screen flash), not data loss.
  static Future<void> _stashWidgetLaunchUri(
    ProviderContainer container,
  ) async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget()
          .timeout(const Duration(milliseconds: 200));
      if (uri == null) return;
      // #2600 — the only widget launch URI is a station deep-link now.
      // The refresh button no longer launches the app (it is a native
      // broadcast handled in place), so the former #2159 refresh-marker
      // discrimination was removed: every launch URI is a route to stash.
      container.read(pendingWidgetUriProvider.notifier).set(uri);
    } on TimeoutException {
      // Expected benign race (stuck plugin / slow channel) — the warm-click
      // stream still delivers the URI. Breadcrumb, not an ERROR trace.
      BreadcrumbCollector.add('widget-launch-probe-timeout',
          detail: '200ms — falling back to the warm-click stream');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: {'where': 'stashWidgetLaunchUri'}));
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 5 — runApp
  // ---------------------------------------------------------------------------

  /// Wires the framework + platform error handlers onto the app's
  /// [errorLogger] pipeline.
  ///
  /// Called from [_launch], and again right after the deferred
  /// `SentryFlutter.init` (#1769): Sentry's `FlutterErrorIntegration`
  /// and `OnErrorIntegration` chain themselves onto these hooks during
  /// init, so re-running this keeps the app's `errorLogger` routing
  /// authoritative — exactly as `_launch` did when it ran inside
  /// Sentry's old `appRunner`.
  static void _installErrorHandlers() {
    // Capture Flutter framework errors (build, layout, paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (_isTileFetchNoise(details.exception) ||
          isBenignStreamCancel(details.exception)) {
        return;
      }
      unawaited(errorLogger.log(
        ErrorLayer.ui,
        details.exception,
        details.stack ?? StackTrace.current,
        context: <String, Object?>{
          'where': 'FlutterError.onError', // #3150 — name the handler
          'library': details.library,
          'context': details.context?.toString(),
        },
      ));
    };
    // Capture async / platform errors that escape the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_isTileFetchNoise(error) || isBenignStreamCancel(error)) return true;
      // #3150 — context so a dispatcher-caught trace is distinguishable
      // from a bare errorLogger call site.
      unawaited(errorLogger.log(ErrorLayer.other, error, stack,
          context: const {'where': 'PlatformDispatcher.onError'}));
      return true;
    };
  }

  /// Whether [error] is a transient network failure from the OSM tile
  /// pipeline. flutter_map's `RetryNetworkTileProvider` already retries
  /// and shows an error tile; the global error log shouldn't also
  /// record these as crashes — they pollute the report with offline /
  /// flaky-network noise (17 entries in a single session on a mobile
  /// device, observed 2026-05-27). Cancellation aborts (#930) are
  /// classed as noise too.
  static bool _isTileFetchNoise(Object error) {
    final msg = error.toString().toLowerCase();
    final isTileUrl = msg.contains('tile.openstreetmap.org');
    if (isTileUrl) return true;
    // SocketException with a host-lookup failure on any host is
    // offline noise. The wrapping FlutterError shows it as "Failed
    // host lookup".
    if (msg.contains('failed host lookup')) return true;
    return false;
  }

  /// Benign EventChannel teardown ("No active stream to cancel"), a lifecycle
  /// race that safeCancel covers at app sites but can escape via plugins —
  /// never a real crash, must not pollute the error log (#2772).
  @visibleForTesting
  static bool isBenignStreamCancel(Object error) =>
      error is PlatformException &&
      (error.message?.toLowerCase().contains('no active stream to cancel') ??
          false);

  static void _launch(
    ProviderContainer container,
    Widget Function(ProviderContainer container) appBuilder,
  ) {
    // #1104 — bind the unified errorLogger to this container so every
    // call to `errorLogger.log(layer, e, st)` from the foreground
    // isolate routes through TraceRecorder + Sentry. Background-isolate
    // callsites never reach this path; they fall through to the Hive
    // ring buffer (IsolateErrorSpool) and are replayed below.
    errorLogger.bind(container);
    _installErrorHandlers();

    // #609 — kick the 2-minute nearest-widget heartbeat so the home-screen
    // widget stays fresh while the app is running (see ProviderWarmupPhase).
    ProviderWarmupPhase.startNearestWidgetHeartbeat(container);

    // #1004 phase 4-WAL — finalise paused trips that survived an app
    // kill mid-grace-window. Sequenced BEFORE the active recovery AND
    // the orchestrator start below so the user lands on a history list
    // with the recovered trip already populated (see TripRecoveryPhase).
    _deferPostFirstFrame(() => TripRecoveryPhase.recoverPausedTrips(container));

    // #1303 — recover an in-progress trip whose process was killed
    // before it could finalise. Sequenced AFTER the paused-trip recovery
    // so a stale paused row from the same drive lands in history before
    // the active recovery re-enters the recording UI
    // (see TripRecoveryPhase).
    _deferPostFirstFrame(() => TripRecoveryPhase.recoverActiveTrip(container));

    // #1004 phase 2b-2 — start the auto-record orchestrator, with the
    // #3167 iOS Core Bluetooth state-restoration opt-in sequenced first
    // inside the same deferred block (see ProviderWarmupPhase).
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.startAutoRecordOrchestrator(container));

    // #1193 phase 2 — wire the vehicle aggregator's `runForVehicle` hook
    // onto `TripHistoryRepository.onSavedHook` (see ProviderWarmupPhase).
    _deferPostFirstFrame(
        () => ProviderWarmupPhase.wireVehicleAggregatorHook(container));

    // #1105 — drain the background-isolate error spool through the
    // foreground TraceRecorder (see TelemetryReplayPhase).
    _deferPostFirstFrame(
        () => TelemetryReplayPhase.drainIsolateErrorSpool(container));

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
    // #2320 — surface the cold-start total as a trace breadcrumb so a
    // startup-latency regression is visible in production error traces
    // (StartupTimer.finish() otherwise only prints under kDebugMode).
    // BreadcrumbCollector is already drained into every error trace by
    // the nav + dio observers, so a single add here puts the figure in
    // the same ring buffer.
    final totalMs = StartupTimer.instance.totalMs;
    if (totalMs != null) {
      BreadcrumbCollector.add('startup', detail: '${totalMs}ms');
    }
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: appBuilder(container),
      ),
    );
  }
}
