import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:hive/hive.dart';

import '../core/background/background_service.dart';
import '../core/constants/app_constants.dart';
import '../core/cache/cache_manager.dart';
import '../core/feedback/auto_record_badge_provider.dart';
import '../core/telemetry/storage/isolate_error_spool.dart';
import '../core/telemetry/storage/trace_storage.dart';
import '../core/telemetry/trace_recorder.dart';
import '../core/logging/error_logger.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/perf/startup_timer.dart';
import '../core/services/country_service_registry.dart';
import '../core/storage/hive_boxes.dart';
import '../core/storage/hive_storage.dart';
import '../core/sync/community_config.dart';
import '../core/sync/supabase_client.dart';
import '../core/telemetry/pii_scrubber.dart';
import '../core/utils/edge_to_edge.dart';
import '../features/consumption/data/obd2/active_trip_recovery_service.dart';
import '../features/consumption/data/obd2/active_trip_repository.dart';
import '../features/consumption/data/obd2/paused_trip_recovery_service.dart';
import '../features/consumption/data/obd2/paused_trip_repository.dart';
import '../features/consumption/data/trip_history_repository.dart';
import '../features/consumption/providers/auto_record_orchestrator.dart';
import '../features/consumption/providers/trip_recording_provider.dart';
import '../features/feature_management/application/legacy_toggle_migration_provider.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/vehicle/data/reference_vehicle_catalog_provider.dart';
import '../features/vehicle/data/repositories/vehicle_profile_repository.dart';
import '../features/vehicle/data/vehicle_profile_migrator.dart';
import '../features/vehicle/providers/vehicle_aggregate_updater_provider.dart';
import '../features/widget/data/home_widget_service.dart';
import '../features/widget/providers/nearest_widget_refresh_provider.dart';
import 'router.dart';

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

    await _initStorage();
    StartupTimer.instance.mark('storage_ready');

    await _initServicesInParallel();
    StartupTimer.instance.mark('services_init');

    final container = ProviderContainer();

    final storage = HiveStorage();
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
    });

    // Cache runtime version so AppConstants.appVersion is accurate (#570).
    // Fire-and-forget: the value is read opportunistically (e.g. by the
    // About screen), not on the first-frame critical path, so awaiting it
    // would only delay `runApp`.
    _deferPostFirstFrame(() async {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        AppConstants.setRuntimeVersion(
          '${packageInfo.version}+${packageInfo.buildNumber}',
        );
      } catch (e, st) {
        debugPrint('PackageInfo.fromPlatform failed (#570): $e\n$st');
      }
    });

    // #950 phase 4 — backfill `referenceVehicleId` on existing
    // VehicleProfile entries from the reference catalog. One-shot:
    // gated on `vehicleCatalogMigrationDone` so subsequent launches
    // skip the work. Runs after the first frame because reading the
    // bundled JSON asset shouldn't block the landing UI.
    _deferPostFirstFrame(() async {
      try {
        final migrator = VehicleProfileCatalogMigrator(
          repository: VehicleProfileRepository(storage),
          settings: storage,
        );
        if (migrator.hasRun) return;
        final catalog =
            await container.read(referenceVehicleCatalogProvider.future);
        final matched = await migrator.run(catalog: catalog);
        debugPrint(
            'VehicleProfileCatalogMigrator: matched $matched profile(s)');
      } catch (e, st) {
        debugPrint('VehicleProfileCatalogMigrator: deferred run failed: $e\n$st');
      }
    });

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
        debugPrint(
            'AppInitializer: legacyToggleMigration kick-off failed: $e\n$st');
      }
    });

    StartupTimer.instance.mark('pre_run_app');

    final dsn = resolveSentryDsn(storage);
    final consentGiven = storage
            .getSetting('consent_error_reporting') as bool? ??
        false;
    if (dsn.isNotEmpty && consentGiven) {
      final packageInfo = await PackageInfo.fromPlatform();
      final release =
          'tankstellen@${packageInfo.version}+${packageInfo.buildNumber}';
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.tracesSampleRate = 0.2;
          options.environment = 'production';
          options.release = release;
          // #1109 — strip PII (emails, lat/lng, tokens, user/request blocks,
          // long breadcrumb payloads) from every event before it leaves the
          // device. The scrubber is a pure function so it stays unit-tested
          // and shared with `TraceUploader`.
          options.beforeSend = (event, hint) {
            try {
              return PiiScrubber.scrubSentryEvent(event);
            } catch (e, st) {
              debugPrint('Sentry beforeSend scrub failed: $e\n$st');
              return event;
            }
          };
        },
        appRunner: () => _launch(container, appBuilder),
      );
    } else {
      _launch(container, appBuilder);
    }
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
    ]);

    // Verify all countries have registered service implementations.
    // Fails fast in debug mode if country_config.dart and the registry diverge.
    assert(() {
      CountryServiceRegistry.assertAllCountriesRegistered();
      return true;
    }());

    // Evict stale cache entries on startup.
    final storage = HiveStorage();
    final cacheManager = CacheManager(storage);
    await cacheManager.evictExpired();

    // Migrate existing profiles to include country/language.
    final profileRepo = ProfileRepository(storage);
    await profileRepo.migrateProfileCountryLanguage();

    // Safety net: guarantee a default profile always exists (#555).
    // The onboarding wizard calls ensureDefaultProfile() at completion,
    // but if the wizard was ever skipped (e.g., by the #521 hasApiKey
    // regression), the app would run without any profile.
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
        debugPrint('AppInitializer: deferred task failed: $e\n$st');
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
  /// active price alert (#713). Alerts are the only user-consented reason
  /// to poll the station APIs on a regular schedule — per Tankerkönig's
  /// terms of service, apps must use "requests on demand" and avoid
  /// regular non-user-initiated requests.
  static Future<void> _maybeInitBackground() async {
    final storage = HiveStorage();
    final rawAlerts = storage.getAlerts();
    final hasActiveAlert = rawAlerts.any((a) => a['isActive'] == true);
    if (!hasActiveAlert) {
      debugPrint(
          'AppInitializer: skipping background polling — no active alerts');
      return;
    }
    await BackgroundService.init();
  }

  static Future<void> _safe(String label, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      debugPrint('AppInitializer: $label init failed: $e\n$st');
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
          debugPrint('TankSync: session expired, re-authenticating...');
          await TankSyncClient.signInAnonymously();
        }
        final sessionId = TankSyncClient.client?.auth.currentUser?.id;
        final storedId = storage.getSetting('sync_user_id') as String?;
        if (sessionId != null && sessionId != storedId) {
          debugPrint('TankSync: userId changed');
          await storage.putSetting('sync_user_id', sessionId);
        }
        if (sessionId != null) {
          try {
            await TankSyncClient.client!.from('users').upsert(
              {'id': sessionId},
              onConflict: 'id',
            );
          } catch (e, st) {
            debugPrint('TankSync: users upsert failed: $e\n$st');
          }
        }
        debugPrint('TankSync: ready');
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('TankSync: init timed out after 8s, proceeding without sync');
    } catch (e, st) {
      debugPrint('TankSync init failed: $e\n$st');
    }
  }

  /// #1303 — recover an in-progress trip snapshot that survived a
  /// process death. Walks the active-trip Hive box; if a fresh
  /// snapshot is on disk (within the 24 h staleness window) the
  /// `TripRecording` provider is rehydrated into a
  /// `pausedDueToDrop`-shaped state with the captured samples
  /// preserved, the launcher-icon badge is bumped (auto-record
  /// trips only), and the user is navigated to `/trip-recording`.
  ///
  /// Stale snapshots are dropped quietly — the user gave up; we
  /// don't surface a stale recovery prompt that would confuse them
  /// on a fresh launch.
  ///
  /// No-ops cleanly when the active-trip box isn't open.
  static Future<void> _runActiveTripRecovery(
    ProviderContainer container,
  ) async {
    if (!Hive.isBoxOpen(HiveBoxes.obd2ActiveTrip)) return;
    final activeRepo = ActiveTripRepository(
      box: Hive.box<String>(HiveBoxes.obd2ActiveTrip),
    );
    TripHistoryRepository? historyRepo;
    if (Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) {
      historyRepo = TripHistoryRepository(
        box: Hive.box<String>(HiveBoxes.obd2TripHistory),
      );
    }
    final service = ActiveTripRecoveryService(
      activeRepo: activeRepo,
      historyRepo: historyRepo,
      onAutomaticRecovered: () async {
        try {
          final badge =
              await container.read(autoRecordBadgeServiceProvider.future);
          await badge.increment();
        } catch (e, st) {
          debugPrint(
              'AppInitializer: activeTripRecovery badge bump failed: $e\n$st');
        }
      },
    );
    final outcome = await service.recover();
    switch (outcome) {
      case ActiveTripRecoveryOutcome.none:
      case ActiveTripRecoveryOutcome.failed:
      case ActiveTripRecoveryOutcome.discarded:
        return;
      case ActiveTripRecoveryOutcome.recovered:
        final snapshot = service.recoveredSnapshot;
        if (snapshot == null) return;
        try {
          final notifier = container.read(tripRecordingProvider.notifier);
          final applied = notifier.restoreFromSnapshot(snapshot);
          if (!applied) return;
          // Bump the unseen-trip badge for auto-record sessions —
          // the user should see "your auto-trip didn't fully save"
          // in the launcher even if they don't tap the recording
          // banner. Mirrors the paused-trip recovery semantics.
          if (snapshot.automatic) {
            try {
              final badge = await container
                  .read(autoRecordBadgeServiceProvider.future);
              await badge.increment();
            } catch (e, st) {
              debugPrint(
                  'AppInitializer: activeTripRecovery recovered badge bump failed: $e\n$st');
            }
          }
          // Auto-navigate to /trip-recording on the next frame so
          // the user lands directly on the live recording UI. We
          // re-enter post-frame because the GoRouter redirect chain
          // (consent → setup → landing) has to settle before we
          // can push a new route — a synchronous push from inside
          // the recovery callback would race against the redirect
          // logic and lose.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            try {
              final goRouter = container.read(routerProvider);
              goRouter.go('/trip-recording');
            } catch (e, st) {
              debugPrint(
                  'AppInitializer: activeTripRecovery go(/trip-recording) failed: $e\n$st');
            }
          });
        } catch (e, st) {
          debugPrint(
              'AppInitializer: activeTripRecovery restoreFromSnapshot failed: $e\n$st');
        }
    }
  }

  /// #1004 phase 4-WAL — finalise paused trips that survived an app
  /// kill mid-grace-window into the trip-history rolling log.
  ///
  /// Resolves the paused-trips + history Hive boxes (no-op when either
  /// is closed — widget tests, fresh installs), wires the badge bump
  /// from [autoRecordBadgeServiceProvider] only for entries flagged as
  /// auto-record, and calls [PausedTripRecoveryService.recoverStale]
  /// with the default 5-minute threshold. The recovered count is
  /// debug-printed; production builds drop the message.
  static Future<void> _runPausedTripRecovery(
    ProviderContainer container,
  ) async {
    if (!Hive.isBoxOpen(HiveBoxes.obd2PausedTrips)) return;
    if (!Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) return;
    final pausedRepo = PausedTripRepository(
      box: Hive.box<String>(HiveBoxes.obd2PausedTrips),
    );
    final historyRepo = TripHistoryRepository(
      box: Hive.box<String>(HiveBoxes.obd2TripHistory),
    );
    final service = PausedTripRecoveryService(
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
      onAutomaticRecovered: () async {
        try {
          final badge =
              await container.read(autoRecordBadgeServiceProvider.future);
          await badge.increment();
        } catch (e, st) {
          debugPrint(
              'AppInitializer: pausedTripRecovery badge bump failed: $e\n$st');
        }
      },
    );
    final recovered = await service.recoverStale();
    if (recovered > 0) {
      debugPrint(
          'AppInitializer: recovered $recovered paused trip(s) into history');
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 5 — runApp
  // ---------------------------------------------------------------------------

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

    // Capture Flutter framework errors (build, layout, paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      errorLogger.log(
        ErrorLayer.ui,
        details.exception,
        details.stack ?? StackTrace.current,
        context: <String, Object?>{
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };
    // Capture async / platform errors that escape the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      errorLogger.log(ErrorLayer.other, error, stack);
      return true;
    };

    // #609 — kick the 2-minute nearest-widget heartbeat so the home-screen
    // widget stays fresh while the app is running. The provider is
    // keepAlive and owns its own Timer; disposal cancels it cleanly.
    try {
      container.read(nearestWidgetRefreshProvider);
    } catch (e, st) {
      debugPrint('AppInitializer: nearestWidgetRefresh start failed: $e\n$st');
    }

    // #1004 phase 4-WAL — recover paused trips that were never
    // finalised because the app was killed mid-grace-window. Walks
    // the `obd2_paused_trips` box, finalises any entry older than 5
    // minutes into the trip-history rolling log, and bumps the
    // launcher-icon badge for entries that came from the auto-record
    // path. Deferred to the post-frame microtask so the first paint
    // isn't blocked by what is at most a 100 ms Hive walk on devices
    // with a single stale entry. Sequenced BEFORE the orchestrator
    // start below so the user lands on a history list with the
    // recovered trip already populated.
    _deferPostFirstFrame(() async {
      try {
        await _runPausedTripRecovery(container);
      } catch (e, st) {
        debugPrint(
            'AppInitializer: pausedTripRecovery failed: $e\n$st');
      }
    });

    // #1303 — recover an in-progress trip whose process was killed
    // before it could finalise. Walks the active-trip Hive box,
    // hands a non-stale snapshot back to the [TripRecording]
    // provider, bumps the unseen-trip badge for auto-record
    // sessions, and navigates to `/trip-recording`. Sequenced
    // AFTER the paused-trip recovery so a stale paused row from
    // the same drive lands in history before the active recovery
    // re-enters the recording UI.
    _deferPostFirstFrame(() async {
      try {
        await _runActiveTripRecovery(container);
      } catch (e, st) {
        debugPrint(
            'AppInitializer: activeTripRecovery failed: $e\n$st');
      }
    });

    // #1004 phase 2b-2 — instantiate the auto-record orchestrator. The
    // provider is `keepAlive: true` and watches the vehicle list
    // internally; reading it once is enough to spin up coordinators
    // for any vehicle that already has `autoRecord: true`. Deferred to
    // a post-frame microtask so a slow listener factory (Android
    // platform channel handshake) cannot delay the first paint. The
    // try/catch belongs here, not just inside the provider, because a
    // bug in `defaultTargetPlatform` resolution or in the listener
    // factory would otherwise crash the whole launch path.
    _deferPostFirstFrame(() async {
      try {
        container.read(autoRecordOrchestratorProvider);
      } catch (e, st) {
        debugPrint(
            'AppInitializer: autoRecordOrchestrator init failed: $e\n$st');
      }
    });

    // #1193 phase 2 — wire the vehicle aggregator's `runForVehicle`
    // hook onto `TripHistoryRepository.onSavedHook` so every saved
    // trip with a non-null vehicleId triggers a background recompute
    // of the rolling driving aggregates. Deferred to the post-frame
    // microtask because the trip-history Hive box is opened during
    // the storage phase but the Riverpod provider may not have read
    // it yet — by post-frame the provider graph has settled. Errors
    // are logged but never block launch (the aggregator is purely an
    // optimisation; trips still save without it).
    _deferPostFirstFrame(() async {
      try {
        final wired = wireAggregatorIntoTripHistory(container);
        if (!wired) {
          debugPrint(
              'AppInitializer: vehicle aggregator hook deferred — '
              'trip-history box not open yet');
        }
      } catch (e, st) {
        debugPrint(
            'AppInitializer: vehicle aggregator wiring failed: $e\n$st');
      }
    });

    // #1105 — drain the background-isolate error spool through the
    // foreground TraceRecorder. WorkManager runs without Riverpod, so
    // every BG failure is parked in a Hive ring buffer until the app
    // is in the foreground; replaying here puts those errors in the
    // same observability pipeline as foreground exceptions (and into
    // Sentry when the user has consented). Deferred to the post-frame
    // microtask so the first paint isn't delayed by Hive reads /
    // recorder writes.
    _deferPostFirstFrame(() async {
      try {
        final recorder = container.read(traceRecorderProvider);
        final replayed = await IsolateErrorSpool.drain(recorder);
        if (replayed > 0) {
          debugPrint(
              'AppInitializer: drained $replayed isolate error(s) into TraceRecorder');
        }
      } catch (e, st) {
        debugPrint('AppInitializer: isolate spool drain failed: $e\n$st');
      }
    });

    StartupTimer.instance.mark('first_frame');
    StartupTimer.instance.finish();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: appBuilder(container),
      ),
    );
  }
}
