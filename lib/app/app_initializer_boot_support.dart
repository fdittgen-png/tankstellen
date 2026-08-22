// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'app_initializer.dart';

/// Boot-phase support for [AppInitializer], extracted as a `part` file so
/// it keeps library-private access while the initializer stays under the
/// #1680 file-length cap (sanctioned #3761 decomposition — move-only,
/// behaviour preserved). Free functions here are the bodies behind the
/// structurally-pinned thin members in `app_initializer.dart`: bootstrap,
/// the storage-phase profile seed, the parallel-service error shield, the
/// shared PackageInfo future, the Sentry options block and the global
/// error-handler bodies.

// ---------------------------------------------------------------------------
// Phase 1 — bootstrap
// ---------------------------------------------------------------------------

void _bootstrap() {
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
// Phase 2 — storage (tail of AppInitializer._initStorage)
// ---------------------------------------------------------------------------

Future<void> _verifyRegistryAndSeedProfile() async {
  // Verify all countries have registered service implementations.
  // Fails fast in debug mode if country_config.dart and the registry diverge.
  assert(() {
    CountryServiceRegistry.assertAllCountriesRegistered();
    return true;
  }(), 'every configured country must have a registered service');

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
// Phase 3 — services (parallel) error shield
// ---------------------------------------------------------------------------

Future<void> _safe(String label, Future<void> Function() body) async {
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
// Deferred runtime-version / Sentry support
// ---------------------------------------------------------------------------

/// #1769 — reading package info is a platform-channel round-trip.
/// Resolve it once, lazily; the same Future is shared by the
/// runtime-version cache and the Sentry release string so neither
/// path pays a second round-trip.
Future<PackageInfo>? _packageInfoFuture;

Future<PackageInfo> _resolvePackageInfo() =>
    _packageInfoFuture ??= PackageInfo.fromPlatform();

/// Cache runtime version so AppConstants.appVersion is accurate (#570).
/// Fire-and-forget: the value is read opportunistically (e.g. by the
/// About screen), not on the first-frame critical path, so awaiting it
/// would only delay `runApp`.
Future<void> _cacheRuntimeVersion() async {
  try {
    final packageInfo = await _resolvePackageInfo();
    AppConstants.setRuntimeVersion(
      '${packageInfo.version}+${packageInfo.buildNumber}',
    );
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.background, e, st,
        context: {'where': 'resolveRuntimeVersion (#570)'}));
  }
}

/// The country/language profile migration + the #2597 one-profile-per-
/// country dedupe — both whole-box walks, deferred past the first frame
/// by `run()`'s post-first-frame storage block (#1768).
Future<void> _migrateProfilesDeferred(HiveStorage storage) async {
  final profileRepo = ProfileRepository(storage);
  await profileRepo.migrateProfileCountryLanguage();
  // #2597 — one profile per country: dedupe existing duplicates
  // (idempotent, runs after the country backfill above).
  await profileRepo.dedupeCountryProfiles();
}

/// The deferred `SentryFlutter.init` options block (#1769 — off the
/// cold-start critical path; the gate that decides WHETHER to init lives
/// in `run()`, pinned there by the structural tests).
void _configureSentryOptions(
  SentryFlutterOptions options,
  String dsn,
  PackageInfo packageInfo,
) {
  options.dsn = dsn;
  options.tracesSampleRate = 0.2;
  options.environment = 'production';
  options.release =
      'tankstellen@${packageInfo.version}+${packageInfo.buildNumber}';
  // #1109 — strip PII (emails, lat/lng, tokens, user/request blocks,
  // long breadcrumbs) from every event before it leaves the device.
  // The scrubber is a pure function shared with `TraceUploader`.
  options.beforeSend = (event, hint) {
    try {
      return PiiScrubber.scrubSentryEvent(event);
    } catch (e, st) {
      // #3144 — breadcrumb-level (NOT errorLogger): a warn trace from
      // inside beforeSend could recurse through the Sentry upload path.
      // The breadcrumb still rides the next persisted trace.
      log.info('Sentry beforeSend scrub failed: $e\n$st', tag: 'sentry');
      return event;
    }
  };
}

// ---------------------------------------------------------------------------
// Widget cold-launch URI probe
// ---------------------------------------------------------------------------

/// Body of [AppInitializer._stashWidgetLaunchUri]. Capped by a short
/// timeout: the `home_widget` plugin's platform channel is normally
/// instant, but a stuck implementation must not block cold start. On
/// timeout / error the warm-click stream still delivers the URI a few
/// frames later — the cost is the very situation this probe was written
/// to remove (a brief landing-screen flash), not data loss.
Future<void> _probeWidgetLaunchUri({
  required void Function(Uri uri) stash,
}) async {
  try {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget()
        .timeout(const Duration(milliseconds: 200));
    if (uri == null) return;
    // #2600 — the only widget launch URI is a station deep-link now.
    // The refresh button no longer launches the app (it is a native
    // broadcast handled in place), so the former #2159 refresh-marker
    // discrimination was removed: every launch URI is a route to stash.
    stash(uri);
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
// Phase 5 — global error-handler bodies
// ---------------------------------------------------------------------------

/// Captures Flutter framework errors (build, layout, paint); assigned to
/// `FlutterError.onError` by [AppInitializer._installErrorHandlers].
void _onFlutterError(FlutterErrorDetails details) {
  FlutterError.presentError(details);
  if (isTileFetchNoise(details.exception) ||
      isBenignStreamCancel(details.exception) ||
      isHandledImageNetworkNoise(details.library, details.exception)) {
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
}

/// Captures async / platform errors that escape the framework; assigned
/// to `PlatformDispatcher.instance.onError`.
bool _onPlatformDispatcherError(Object error, StackTrace stack) {
  if (isTileFetchNoise(error) || isBenignStreamCancel(error)) return true;
  // #3150 — context so a dispatcher-caught trace is distinguishable
  // from a bare errorLogger call site.
  unawaited(errorLogger.log(ErrorLayer.other, error, stack,
      context: const {'where': 'PlatformDispatcher.onError'}));
  return true;
}
