import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app/app.dart';
import 'core/background/background_service.dart';
import 'core/cache/cache_manager.dart';
import 'core/error_tracing/storage/trace_storage.dart';
import 'core/error_tracing/trace_recorder.dart';
import 'core/utils/edge_to_edge.dart';
import 'core/notifications/notification_service.dart';
import 'core/perf/startup_timer.dart';
import 'core/storage/hive_storage.dart';
import 'core/sync/community_config.dart';
import 'core/services/country_service_registry.dart';
import 'core/sync/supabase_client.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/widget/data/home_widget_service.dart';

/// App entry point. Initialization order matters:
///
/// 1. Flutter binding (required before any plugin calls)
/// 2. Hive local storage (all other systems depend on stored config)
/// 3. API keys from secure storage into memory cache
/// 4. Error trace storage (for capturing startup errors)
/// 5. Cache eviction (prevent stale data accumulation)
/// 6. Profile migration (backward compatibility)
/// 7. Notifications + background tasks (WorkManager)
/// 8. Sentry (optional, user-configured)
/// 9. TankSync/Supabase (optional, user-configured)
/// 10. Run app with global error handlers
Future<void> main() async {
  StartupTimer.instance.start();

  WidgetsFlutterBinding.ensureInitialized();
  StartupTimer.instance.mark('binding');

  // Opt in to edge-to-edge display (required for Android 15+).
  // Makes system bars transparent so app content draws behind them.
  // Individual screens handle insets via SafeArea or MediaQuery.viewPadding.
  EdgeToEdge.enable();

  // Silence all debugPrint output in release builds.
  // debugPrint is NOT stripped by the compiler, so it leaks to logcat/console
  // in production — exposing user IDs, API responses, sync errors, etc.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await HiveStorage.init();
  StartupTimer.instance.mark('hive_init');
  await HiveStorage.loadApiKey();
  await TraceStorage.init();
  StartupTimer.instance.mark('storage_ready');

  // Verify all countries have registered service implementations.
  // Fails fast in debug mode if country_config.dart and the registry diverge.
  assert(() {
    CountryServiceRegistry.assertAllCountriesRegistered();
    return true;
  }());

  // Evict stale cache entries on startup
  final cacheManager = CacheManager(HiveStorage());
  await cacheManager.evictExpired();

  // Migrate existing profiles to include country/language
  final profileRepo = ProfileRepository(HiveStorage());
  await profileRepo.migrateProfileCountryLanguage();

  // Initialize local notifications, background tasks, and home widget
  await NotificationService.init();
  await BackgroundService.init();
  await HomeWidgetService.init();
  StartupTimer.instance.mark('services_init');

  final container = ProviderContainer();

  // Check if user has configured a Sentry DSN
  final storage = HiveStorage();
  final sentryDsn = storage.getSetting('sentry_dsn') as String?;

  // Load community config from bundled asset (for TankSync community mode)
  await CommunityConfig.load();

  // Optionally initialize TankSync if configured
  final syncEnabled = storage.getSetting('sync_enabled') as bool? ?? false;
  if (syncEnabled) {
    final url = storage.getSetting('supabase_url') as String?;
    final key = storage.getSetting('supabase_anon_key') as String?;
    if (url != null && key != null) {
      try {
        await Future(() async {
          await TankSyncClient.init(url: url, anonKey: key);
          // Re-authenticate if session expired
          if (TankSyncClient.client?.auth.currentUser == null) {
            debugPrint('TankSync: session expired, re-authenticating...');
            await TankSyncClient.signInAnonymously();
          }
          // ALWAYS sync stored userId with the active session
          final sessionId = TankSyncClient.client?.auth.currentUser?.id;
          final storedId = storage.getSetting('sync_user_id') as String?;
          if (sessionId != null && sessionId != storedId) {
            debugPrint('TankSync: userId changed $storedId → $sessionId');
            await storage.putSetting('sync_user_id', sessionId);
          }
          // Ensure public.users row exists (FK constraint requirement)
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
          debugPrint('TankSync: ready, userId=$sessionId');
        }).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        debugPrint('TankSync: init timed out after 8s, proceeding without sync');
      } catch (e) {
        debugPrint('TankSync init failed: $e');
      }
    }
  }

  StartupTimer.instance.mark('pre_run_app');

  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    // Read version from pubspec.yaml metadata at runtime
    final packageInfo = await PackageInfo.fromPlatform();
    final release = 'tankstellen@${packageInfo.version}+${packageInfo.buildNumber}';

    // Sentry enabled — use SentryFlutter to capture errors
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2; // 20% of transactions
        options.environment = 'production';
        options.release = release;
      },
      appRunner: () => _runApp(container),
    );
  } else {
    // No Sentry — use local error tracing only
    _runApp(container);
  }
}

void _runApp(ProviderContainer container) {
  // Capture Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    container.read(traceRecorderProvider).record(
          details.exception,
          details.stack ?? StackTrace.current,
        );
  };

  // Capture async / platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    container.read(traceRecorderProvider).record(error, stack);
    return true;
  };

  StartupTimer.instance.mark('first_frame');
  StartupTimer.instance.finish();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TankstellenApp(),
    ),
  );
}
