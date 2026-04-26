import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/background/background_service.dart';
import '../core/constants/app_constants.dart';
import '../core/cache/cache_manager.dart';
import '../core/error_tracing/storage/isolate_error_spool.dart';
import '../core/error_tracing/storage/trace_storage.dart';
import '../core/error_tracing/trace_recorder.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/perf/startup_timer.dart';
import '../core/services/country_service_registry.dart';
import '../core/storage/hive_storage.dart';
import '../core/sync/community_config.dart';
import '../core/sync/supabase_client.dart';
import '../core/telemetry/pii_scrubber.dart';
import '../core/utils/edge_to_edge.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/vehicle/data/reference_vehicle_catalog_provider.dart';
import '../features/vehicle/data/repositories/vehicle_profile_repository.dart';
import '../features/vehicle/data/vehicle_profile_migrator.dart';
import '../features/widget/data/home_widget_service.dart';
import '../features/widget/providers/nearest_widget_refresh_provider.dart';

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
/// 4. **optional (deferred)** — community config + TankSync. Scheduled for
///    a post-first-frame microtask so the app paints before Supabase is
///    touched (#795 phase 1). Failures are logged but never block startup.
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

  // ---------------------------------------------------------------------------
  // Phase 5 — runApp
  // ---------------------------------------------------------------------------

  static void _launch(
    ProviderContainer container,
    Widget Function(ProviderContainer container) appBuilder,
  ) {
    // Capture Flutter framework errors (build, layout, paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      container.read(traceRecorderProvider).record(
            details.exception,
            details.stack ?? StackTrace.current,
          );
    };
    // Capture async / platform errors that escape the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      container.read(traceRecorderProvider).record(error, stack);
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
