// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression tests for issue #424 — the cold-start sequence has been
/// extracted from main.dart into AppInitializer with phased ordering and
/// parallelised service init.
///
/// These are source-level structural tests rather than runtime ones because
/// AppInitializer.run() touches platform plugins (Hive, secure storage,
/// notifications) that aren't available under flutter_test without a real
/// device binding.
void main() {
  late String mainSource;
  late String initSource;

  setUpAll(() {
    mainSource = File('lib/main.dart').readAsStringSync();
    initSource = File('lib/app/app_initializer.dart').readAsStringSync();
  });

  group('main.dart is a thin entry point', () {
    test('main.dart is at most 30 lines', () {
      // The original main.dart was 178 lines. Keep it tiny so the cold-start
      // sequence stays in AppInitializer where it can be reasoned about.
      final lines = mainSource.split('\n').length;
      expect(lines, lessThanOrEqualTo(30),
          reason:
              'main.dart should delegate to AppInitializer.run; growth above '
              '30 lines means new logic is leaking back into main()');
    });

    test('main.dart calls AppInitializer.run', () {
      expect(mainSource, contains('AppInitializer.run'));
    });

    test('main.dart does NOT call HiveStorage, BackgroundService, etc. directly',
        () {
      // Anything that touches storage or services must go through
      // AppInitializer so it gets the phased error handling.
      const forbidden = [
        'HiveStorage.init',
        'BackgroundService.init',
        'LocalNotificationService',
        'TankSyncClient.init',
        'SentryFlutter.init',
      ];
      for (final symbol in forbidden) {
        expect(mainSource, isNot(contains(symbol)),
            reason: '$symbol must live inside AppInitializer, not main.dart');
      }
    });
  });

  group('AppInitializer phase ordering', () {
    test('runs in order: bootstrap → storage → services → optional → launch',
        () {
      // Pin the call ordering inside AppInitializer.run so a future edit
      // can't accidentally do storage-before-bootstrap or skip a phase.
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull, reason: 'run() method must exist');

      final bootstrap = runBody!.indexOf('_bootstrap()');
      final storage = runBody.indexOf('_initStorage()');
      final services = runBody.indexOf('_initServicesInParallel()');
      final tankSync = runBody.indexOf('_maybeInitTankSync');
      final launch = runBody.indexOf('_launch(');

      expect(bootstrap, isNonNegative, reason: '_bootstrap call missing');
      expect(storage, isNonNegative, reason: '_initStorage call missing');
      expect(services, isNonNegative, reason: '_initServices call missing');
      expect(tankSync, isNonNegative, reason: '_maybeInitTankSync missing');
      expect(launch, isNonNegative, reason: '_launch call missing');

      expect(bootstrap, lessThan(storage),
          reason: 'bootstrap must precede storage init');
      expect(storage, lessThan(services),
          reason: 'storage must precede service init');
      expect(services, lessThan(tankSync),
          reason: 'service init must precede TankSync');
      expect(tankSync, lessThan(launch),
          reason: 'TankSync must precede _launch');
    });

    test('service inits run in parallel via Future.wait', () {
      // A future regression that swaps Future.wait back to sequential awaits
      // must fail this test — that was the whole point of the refactor.
      final body = _extractMethodBody(
        initSource,
        'static Future<void> _initServicesInParallel',
      );
      expect(body, isNotNull);
      expect(body, contains('Future.wait'));
      expect(body, contains('LocalNotificationService'));
      // Background polling is now gated on active alerts (#713); the
      // parallel slot may reference the gating helper instead of the
      // service directly. Either is fine so long as background work
      // still happens in the same Future.wait slot.
      expect(
        body!.contains('BackgroundService.init') ||
            body.contains('_maybeInitBackground'),
        isTrue,
        reason: 'background init (or its gating helper) must run in parallel',
      );
      expect(body, contains('HomeWidgetService.init'));
    });

    test('each parallel service init is wrapped in error protection', () {
      // Failing notifications must not block background or home widget init.
      final body = _extractMethodBody(
        initSource,
        'static Future<void> _initServicesInParallel',
      );
      expect(body, isNotNull);
      expect(body, contains('_safe('),
          reason: 'each parallel init should go through _safe to isolate '
              'failures across services');
    });

    test('TankSync init is bounded by an 8-second timeout', () {
      final body =
          _extractMethodBody(initSource, 'static Future<void> _maybeInitTankSync');
      expect(body, isNotNull);
      expect(body, contains('Duration(seconds: 8)'),
          reason: 'TankSync init must have a hard timeout so a stuck Supabase '
              "init can't block the first frame");
      expect(body, contains('TimeoutException'));
    });

    test('global error handlers are installed via _launch', () {
      final launchBody = _extractMethodBody(initSource, 'static void _launch');
      expect(launchBody, isNotNull);
      expect(launchBody, contains('_installErrorHandlers'),
          reason: '_launch must install the global error handlers');
      expect(launchBody, contains('runApp'));

      // #1769 — the handler wiring lives in its own helper so it can be
      // re-asserted after the deferred SentryFlutter.init.
      final handlersBody =
          _extractMethodBody(initSource, 'static void _installErrorHandlers');
      expect(handlersBody, isNotNull,
          reason: '_installErrorHandlers helper must exist');
      expect(handlersBody, contains('FlutterError.onError'));
      expect(handlersBody, contains('PlatformDispatcher.instance.onError'));
    });

    test('PackageInfo.fromPlatform is invoked at most once (#1769)', () {
      // A platform-channel round-trip — resolve it once and share the
      // cached Future between the runtime-version cache and Sentry.
      final hits = 'PackageInfo.fromPlatform('.allMatches(initSource).length;
      expect(hits, lessThanOrEqualTo(1),
          reason: 'PackageInfo.fromPlatform() must be called once and the '
              'Future reused (#1769)');
    });

    test('Sentry.init no longer wraps runApp via appRunner (#1769)', () {
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);
      expect(runBody, isNot(contains('appRunner')),
          reason: 'Sentry.init must not wrap runApp via appRunner — that '
              'forces it onto the cold-start critical path (#1769)');
      expect(runBody, contains('SentryFlutter.init'),
          reason: 'Sentry is still initialised, just off the critical path');
    });
  });

  group('Legacy-toggle migration kick-off (#1373 phase 3a/3b/3e/3f follow-up)',
      () {
    test(
        'AppInitializer.run schedules legacyToggleMigrationProvider on a '
        'post-first-frame microtask via container.read(...future)', () {
      // Source-level pin: the wiring must live inside a `_deferPostFirstFrame`
      // block (so it never delays the first paint) AND it must read the
      // provider's `.future` (not just `read(provider)` which would only
      // observe the synchronous AsyncValue placeholder and never let the
      // migrator microtask be scheduled at the framework level).
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);
      expect(
        runBody,
        contains('legacyToggleMigrationProvider'),
        reason: 'AppInitializer.run must reference the provider so the '
            'legacy-toggle migrators fire at every cold start, not only when '
            'the user opens the feature-flags settings screen',
      );
      expect(
        runBody,
        contains('legacyToggleMigrationProvider.future'),
        reason: 'The kick-off must read `.future` so the underlying microtask '
            'actually runs the migrators (a plain `read(provider)` returns '
            'the synchronous AsyncValue placeholder without firing build())',
      );

      // The reference must sit inside a `_deferPostFirstFrame` block so it
      // can never delay the first paint. We assert the textual order: the
      // FIRST `_deferPostFirstFrame` opening brace must precede the
      // legacyToggleMigrationProvider mention, AND the import must be
      // present (otherwise the file wouldn't compile).
      final deferIdx = runBody!.indexOf('_deferPostFirstFrame');
      final providerIdx = runBody.indexOf('legacyToggleMigrationProvider');
      expect(deferIdx, isNonNegative);
      expect(providerIdx, isNonNegative);
      expect(deferIdx, lessThan(providerIdx),
          reason: 'legacy-toggle migration must be scheduled INSIDE a '
              '_deferPostFirstFrame block so it never blocks the first paint');

      expect(
        initSource,
        contains(
            "import '../features/feature_management/application/legacy_toggle_migration_provider.dart';"),
        reason: 'the provider must be imported so the wiring compiles',
      );
    });
  });

  group('Sentry observability wiring (#476)', () {
    test(
        'resolveSentryDsn prefers the user-stored sentry_dsn setting over '
        'the build-time SENTRY_DSN dart-define', () {
      // Source-level invariants: the resolver must read the storage
      // setting first, then fall back to String.fromEnvironment.
      final body =
          _extractMethodBody(initSource, 'static String resolveSentryDsn');
      expect(body, isNotNull, reason: 'resolveSentryDsn helper must exist');
      // Storage read happens first.
      final storedIdx = body!.indexOf("getSetting('sentry_dsn')");
      final envIdx = body.indexOf('String.fromEnvironment');
      expect(storedIdx, isNonNegative);
      expect(envIdx, isNonNegative);
      expect(storedIdx, lessThan(envIdx),
          reason: 'storage setting must be checked before the dart-define '
              'fallback so a power user can override the maintainer DSN');
      // The dart-define key is exactly SENTRY_DSN (not e.g. SentryDSN or
      // sentry_dsn — that would silently misalign with the build flag).
      expect(body, contains("String.fromEnvironment('SENTRY_DSN')"),
          reason: 'dart-define key must be exactly SENTRY_DSN to match the '
              'build flag in the release workflow');
    });

    test(
        'SentryFlutter.init is gated on (a) DSN non-empty AND '
        '(b) consent_error_reporting setting being true', () {
      final body =
          _extractMethodBody(initSource, 'static Future<void> run');
      expect(body, isNotNull);
      // The init must check consent.
      expect(body, contains('consent_error_reporting'),
          reason: 'AppInitializer.run must check the user has opted in to '
              'error reporting before initialising Sentry');
      // And it must check the DSN is non-empty.
      expect(body, contains('isNotEmpty'),
          reason: 'init must guard on DSN.isNotEmpty so an empty SENTRY_DSN '
              'in the build env never triggers Sentry');
    });

    test(
        'main.dart still does NOT reference SentryFlutter — that is owned '
        'by AppInitializer', () {
      // Belt and braces: keep the forbidden-symbols list in sync if the
      // Sentry rollout ever leaks back into main.dart.
      expect(mainSource, isNot(contains('SentryFlutter')));
      expect(mainSource, isNot(contains('SENTRY_DSN')));
    });
  });

  group('Price-history eviction cold-start hook (#2317)', () {
    test(
        'run() evicts old price-history records on cold start inside a '
        '_deferPostFirstFrame block, next to CacheManager eviction', () {
      // #2317 — PriceHistoryRepository.evictOldRecords existed + was
      // tested but had zero production call sites, so the foreground
      // record path grew the box unbounded (~175k dead rows/year for a
      // heavy user). The fix mirrors the existing CacheManager cold-start
      // eviction hook: trim the price-history box once per cold start
      // off the first-frame critical path.
      final runBody = _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);

      expect(runBody, contains('PriceHistoryRepository(storage).evictOldRecords'),
          reason: 'run() must call evictOldRecords on cold start so the '
              'price-history box stops growing unbounded (#2317)');

      // It must live next to the existing CacheManager eviction so it is
      // deferred past the first frame (not on the critical path).
      final evictBoundedIdx = runBody!.indexOf('evictBounded');
      final evictOldIdx = runBody.indexOf('evictOldRecords');
      final deferIdx = runBody.indexOf('_deferPostFirstFrame');
      expect(evictBoundedIdx, isNonNegative);
      expect(evictOldIdx, isNonNegative);
      expect(deferIdx, isNonNegative);
      expect(deferIdx, lessThan(evictOldIdx),
          reason: 'price-history eviction must be scheduled inside a '
              '_deferPostFirstFrame block so it never blocks the first paint');

      expect(
        initSource,
        contains(
            "import '../features/price_history/data/repositories/price_history_repository.dart';"),
        reason: 'the repository must be imported so the eviction wiring '
            'compiles',
      );
    });
  });

  group('Widget cold-launch URI dispatch (#2159)', () {
    test(
        '_stashWidgetLaunchUri intercepts refresh URIs before stashing',
        () {
      // #2159 — the refresh-button URI `tankstellenwidget://refresh`
      // is NOT a route. If we let it flow into pendingWidgetUriProvider
      // the router redirect consumes it (clears the stash) and
      // widgetUriToPath returns null, so the user lands on the default
      // landing screen and the widget never refreshes. The fix is to
      // discriminate refresh URIs and call the refresh notifier
      // directly, BEFORE the pending-URI stash.
      final body = _extractMethodBody(
          initSource, 'static Future<void> _stashWidgetLaunchUri');
      expect(body, isNotNull,
          reason: '_stashWidgetLaunchUri must exist');

      final refreshCheck = body!.indexOf('isWidgetRefreshUri(uri)');
      final refreshDispatch =
          body.indexOf('nearestWidgetRefreshProvider.notifier');
      final stash = body.indexOf('pendingWidgetUriProvider.notifier');

      expect(refreshCheck, isNonNegative,
          reason: 'must check isWidgetRefreshUri before stashing');
      expect(refreshDispatch, isNonNegative,
          reason: 'must dispatch refresh URIs to the refresh notifier');
      expect(stash, isNonNegative,
          reason: 'station URIs must still flow through the pending stash');

      expect(refreshCheck, lessThan(stash),
          reason:
              'the refresh discriminator must run BEFORE the stash, '
              'otherwise refresh URIs are consumed by the router redirect '
              'and silently dropped');
      expect(refreshDispatch, lessThan(stash),
          reason:
              'the refresh dispatch must run BEFORE the stash for the '
              'same reason');
    });
  });
}

/// Extracts the body of the first method that starts with [signature].
/// Returns null if not found. Skips past the parameter list (which may
/// itself contain braces in named-parameter blocks) before locating the
/// body brace.
String? _extractMethodBody(String source, String signature) {
  final start = source.indexOf(signature);
  if (start < 0) return null;

  // Walk past the parameter list. The signature is followed by `(...)`,
  // optionally with a `{...}` named-parameter block inside the parens.
  var i = source.indexOf('(', start);
  if (i < 0) return null;
  var parenDepth = 0;
  for (; i < source.length; i++) {
    final ch = source[i];
    if (ch == '(') parenDepth++;
    if (ch == ')') {
      parenDepth--;
      if (parenDepth == 0) {
        i++;
        break;
      }
    }
  }
  // Now find the first `{` after the closing paren — that's the body.
  final braceStart = source.indexOf('{', i);
  if (braceStart < 0) return null;
  var depth = 0;
  for (var j = braceStart; j < source.length; j++) {
    final ch = source[j];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return source.substring(braceStart + 1, j);
    }
  }
  return null;
}
