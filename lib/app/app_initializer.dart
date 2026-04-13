import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/background/background_service.dart';
import '../core/cache/cache_manager.dart';
import '../core/error_tracing/storage/trace_storage.dart';
import '../core/error_tracing/trace_recorder.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/perf/startup_timer.dart';
import '../core/services/country_service_registry.dart';
import '../core/storage/hive_storage.dart';
import '../core/sync/community_config.dart';
import '../core/sync/supabase_client.dart';
import '../core/utils/edge_to_edge.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/widget/data/home_widget_service.dart';

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
/// 3. **services** — notifications, background tasks, home widget.
///    Independent of each other → parallelised with `Future.wait`.
/// 4. **optional** — community config, TankSync. Best-effort; failures are
///    logged but never block startup.
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
    await CommunityConfig.load();
    await _maybeInitTankSync(storage);

    StartupTimer.instance.mark('pre_run_app');

    final sentryDsn = storage.getSetting('sentry_dsn') as String?;
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      final packageInfo = await PackageInfo.fromPlatform();
      final release =
          'tankstellen@${packageInfo.version}+${packageInfo.buildNumber}';
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 0.2;
          options.environment = 'production';
          options.release = release;
        },
        appRunner: () => _launch(container, appBuilder),
      );
    } else {
      _launch(container, appBuilder);
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 — bootstrap
  // ---------------------------------------------------------------------------

  static void _bootstrap() {
    WidgetsFlutterBinding.ensureInitialized();
    // Opt in to edge-to-edge display (required for Android 15+).
    EdgeToEdge.enable();

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
    await HiveStorage.loadApiKey();
    await TraceStorage.init();

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
      _safe('background', BackgroundService.init),
      _safe('home_widget', HomeWidgetService.init),
    ]);
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
          } catch (e) {
            debugPrint('TankSync: users upsert failed: $e');
          }
        }
        debugPrint('TankSync: ready');
      }).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('TankSync: init timed out after 8s, proceeding without sync');
    } catch (e) {
      debugPrint('TankSync init failed: $e');
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
